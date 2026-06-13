import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/part.dart';
import '../models/api_exception.dart';

bool kDebugMode = false;


class ApiService extends ChangeNotifier {
  String baseUrl = '';
  String token = '';
  double zoomLevel = 2.0;
  bool sunmiEnabled = true;
  bool niimbotEnabled = true;
  String locale = 'en';
  final _secureStorage = const FlutterSecureStorage();

  ApiService();

  Future<void> loadConfig() async {
    final url = await _secureStorage.read(key: 'partdb_base_url');
    final t = await _secureStorage.read(key: 'partdb_token');
    final zoom = await _secureStorage.read(key: 'camera_zoom');
    final sunmi = await _secureStorage.read(key: 'printer_sunmi_enabled');
    final niimbot = await _secureStorage.read(key: 'printer_niimbot_enabled');
    final loc = await _secureStorage.read(key: 'app_locale');

    baseUrl = url ?? '';
    token = t ?? '';
    zoomLevel = double.tryParse(zoom ?? '2.0') ?? 2.0;
    sunmiEnabled = sunmi != 'false';
    niimbotEnabled = niimbot != 'false';
    locale = loc ?? 'en';
  }

  Future<void> saveConfig(String url, String t) async {
    await _secureStorage.write(key: 'partdb_base_url', value: url);
    await _secureStorage.write(key: 'partdb_token', value: t);
    baseUrl = url;
    token = t;
    notifyListeners();
  }

  Future<void> saveZoomLevel(double zoom) async {
    await _secureStorage.write(key: 'camera_zoom', value: zoom.toString());
    zoomLevel = zoom;
    notifyListeners();
  }

  Future<void> saveSunmiEnabled(bool enabled) async {
    await _secureStorage.write(key: 'printer_sunmi_enabled', value: enabled.toString());
    sunmiEnabled = enabled;
    notifyListeners();
  }

  Future<void> saveNiimbotEnabled(bool enabled) async {
    await _secureStorage.write(key: 'printer_niimbot_enabled', value: enabled.toString());
    niimbotEnabled = enabled;
    notifyListeners();
  }

  Future<void> saveLocale(String newLocale) async {
    await _secureStorage.write(key: 'app_locale', value: newLocale);
    locale = newLocale;
    notifyListeners();
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: 'partdb_token');
    token = '';
    notifyListeners();
  }

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _join(String path) {
    if (baseUrl.endsWith('/')) {
      return '$baseUrl${path.startsWith('/') ? path.substring(1) : path}';
    } else {
      return '$baseUrl$path';
    }
  }

  static const _timeout = Duration(seconds: 10);

  Future<http.Response> _get(Uri uri) =>
      http.get(uri, headers: _headers()).timeout(
        _timeout,
        onTimeout: () => throw TimeoutException('No server response (timeout 10s)'),
      );

  Future<http.Response> _patch(Uri uri, String body) =>
      http.patch(
        uri,
        headers: {..._headers(), 'Content-Type': 'application/merge-patch+json'},
        body: body,
      ).timeout(
        _timeout,
        onTimeout: () => throw TimeoutException('No server response (timeout 10s)'),
      );

  Future<http.Response> _post(Uri uri, String body) =>
      http.post(
        uri,
        headers: _headers(),
        body: body,
      ).timeout(
        _timeout,
        onTimeout: () => throw TimeoutException('No server response (timeout 10s)'),
      );

  /// Wyciąga czytelny opis błędu z odpowiedzi PartDB (hydra:description / violations / detail).
  String _extractError(http.Response r, String fallback) {
    try {
      final decoded = json.decode(r.body);
      if (decoded is Map) {
        // API Platform validation error
        final desc = decoded['hydra:description']?.toString();
        if (desc != null && desc.isNotEmpty) return desc;
        // violations list
        final violations = decoded['violations'];
        if (violations is List && violations.isNotEmpty) {
          return violations
              .map((v) => '${v['propertyPath']}: ${v['message']}')
              .join(', ');
        }
        // generic detail
        final detail = decoded['detail']?.toString();
        if (detail != null && detail.isNotEmpty) return detail;
        final title = decoded['title']?.toString();
        if (title != null && title.isNotEmpty) return title;
      }
    } catch (_) {}
    return '$fallback (${r.statusCode})';
  }

  Future<Map<String, dynamic>> getCurrentTokenInfo() async {
    final r = await _get(Uri.parse(_join('/api/tokens/current')));
    if (r.statusCode == 200) {
      return json.decode(r.body) as Map<String, dynamic>;
    } else {
      throw ApiException(r.statusCode, 'Token verification error (${r.statusCode})');
    }
  }

  Future<Part> findPartByIPN(String ipn) async {
    final r = await _get(Uri.parse(_join('/api/parts?ipn=${Uri.encodeQueryComponent(ipn)}')));

    if (r.statusCode == 200) {
      final decoded = json.decode(r.body);
      if (kDebugMode) {
        print('DEBUG: findPartByIPN response = $decoded');
      }

      if (decoded is Map && decoded.containsKey('hydra:member')) {
        final members = decoded['hydra:member'];
        if (members is List && members.isNotEmpty) {
          return Part.fromJson(Map<String, dynamic>.from(members.first));
        } else {
          throw ApiException(404, 'Part not found: IPN=$ipn');
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        return Part.fromJson(Map<String, dynamic>.from(decoded.first));
      } else if (decoded is Map && decoded.containsKey('id')) {
        return Part.fromJson(Map<String, dynamic>.from(decoded));
      } else {
        throw ApiException(404, 'Part not found: IPN=$ipn');
      }
    } else {
      throw ApiException(r.statusCode, 'IPN search error (${r.statusCode})');
    }
  }

  Future<List<Part>> fetchAllParts() async {
    final List allMembers = [];
    String? nextUrl = _join('/api/parts?itemsPerPage=100');

    while (nextUrl != null && allMembers.length < 2000) {
      final r = await _get(Uri.parse(nextUrl));
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, 'Fetch parts error (${r.statusCode})');
      }
      final decoded = json.decode(r.body);
      if (decoded is Map && decoded.containsKey('hydra:member')) {
        allMembers.addAll(decoded['hydra:member'] as List);
        final next = decoded['hydra:view']?['hydra:next'] as String?;
        nextUrl = next != null ? _join(next) : null;
      } else if (decoded is List) {
        allMembers.addAll(decoded);
        nextUrl = null;
      } else {
        nextUrl = null;
      }
    }

    return allMembers
        .map((m) => Part.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  /// Szuka części po nazwie po stronie serwera (bez pobierania całej listy).
  /// Dla trybów param/value nadal używa [searchPartsAdvanced].
  Future<List<Part>> searchByName(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final List allMembers = [];
    String? nextUrl = _join('/api/parts?name=$encoded&itemsPerPage=100');

    while (nextUrl != null && allMembers.length < 200) {
      final r = await _get(Uri.parse(nextUrl));
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, 'Search error (${r.statusCode})');
      }
      final decoded = json.decode(r.body);
      if (decoded is Map && decoded.containsKey('hydra:member')) {
        allMembers.addAll(decoded['hydra:member'] as List);
        final next = decoded['hydra:view']?['hydra:next'] as String?;
        nextUrl = next != null ? _join(next) : null;
      } else if (decoded is List) {
        allMembers.addAll(decoded);
        nextUrl = null;
      } else {
        nextUrl = null;
      }
    }

    return allMembers
        .map((m) => Part.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<List<Part>> searchPartsAdvanced(String query,
      {bool searchInParams = true, bool searchInValues = true}) async {
    final lowerQuery = query.toLowerCase();
    final allParts = await fetchAllParts();
    final List<Part> results = [];

    for (final part in allParts) {
      final name = part.name.toLowerCase();
      final ipn = part.partNumber.toLowerCase();
      final unit = part.unit.toLowerCase();
      final paramNames = part.parameters.map((p) => p.name.toLowerCase()).join(' ');
      final paramValues = part.parameters.map((p) => p.value.toLowerCase()).join(' ');

      bool match = name.contains(lowerQuery) ||
          ipn.contains(lowerQuery) ||
          unit.contains(lowerQuery);

      if (!match && searchInParams) match = paramNames.contains(lowerQuery);
      if (!match && searchInValues) match = paramValues.contains(lowerQuery);

      if (match) results.add(part);
    }

    return results;
  }

  Future<PartLot> patchPartLot(int lotId, double newAmount, {String? comment}) async {
    final body = <String, dynamic>{'amount': newAmount};
    if (comment != null && comment.isNotEmpty) body['description'] = comment;

    final r = await _patch(
      Uri.parse(_join('/api/part_lots/$lotId')),
      json.encode(body),
    );

    if (r.statusCode == 200) {
      return PartLot.fromJson(Map<String, dynamic>.from(json.decode(r.body)));
    } else {
      throw ApiException(r.statusCode, 'Stock save error (${r.statusCode})');
    }
  }

  Future<void> patchPartParameter(int parameterId, String newValue) async {
    final r = await _patch(
      Uri.parse(_join('/api/part_parameters/$parameterId')),
      json.encode({'value': newValue}),
    );

    if (r.statusCode != 200) {
      throw ApiException(r.statusCode, 'Parameter save error (${r.statusCode})');
    }
  }

  Future<void> patchPartIPN(int partId, String newIpn) async {
    final r = await _patch(
      Uri.parse(_join('/api/parts/$partId')),
      json.encode({'ipn': newIpn}),
    );

    if (r.statusCode != 200) {
      throw ApiException(r.statusCode, 'IPN save error (${r.statusCode})');
    }
  }

  Future<PartDetails> fetchPartParameters(int partId) async {
    final r = await _get(Uri.parse(_join('/api/parts/$partId')));

    if (r.statusCode == 200) {
      final decoded = json.decode(r.body);
      if (kDebugMode) {
        print('DEBUG: fetchPartParameters for partId=$partId -> $decoded');
      }

      final List<PartParameter> params = [];
      final rawParams = (decoded['parameters'] is List)
          ? decoded['parameters']
          : (decoded['part_parameters'] ?? []);

      for (final p in rawParams) {
        if (p is Map) {
          final casted = p.map((k, v) => MapEntry(k.toString(), v));
          params.add(PartParameter.fromJson(casted));
        } else if (p is String) {
          params.add(PartParameter(id: 0, name: p, value: '', unit: ''));
        }
      }

      // Wyciągnij kategorię i producenta z pełnej odpowiedzi
      String category = '';
      final cat = decoded['category'];
      if (cat is Map) {
        category = cat['name']?.toString() ?? '';
      } else if (cat is String && !cat.startsWith('/api/') && !cat.startsWith('http')) {
        category = cat;
      }

      String manufacturer = '';
      final mfr = decoded['manufacturer'];
      if (mfr is Map) {
        manufacturer = mfr['name']?.toString() ?? '';
      } else if (decoded['manufacturers'] is List) {
        final list = decoded['manufacturers'] as List;
        if (list.isNotEmpty && list.first is Map) {
          final m = list.first as Map;
          final inner = m['manufacturer'];
          if (inner is Map) manufacturer = inner['name']?.toString() ?? '';
        }
      }

      return PartDetails(params: params, category: category, manufacturer: manufacturer);
    } else {
      throw ApiException(r.statusCode, 'Fetch parameters error (${r.statusCode})');
    }
  }

  Future<List<PartCategory>> fetchCategories() async {
    final List allMembers = [];
    String? nextUrl = _join('/api/categories?itemsPerPage=200');

    while (nextUrl != null) {
      final r = await _get(Uri.parse(nextUrl));
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, 'Fetch categories error (${r.statusCode})');
      }
      final decoded = json.decode(r.body);
      if (decoded is Map && decoded.containsKey('hydra:member')) {
        allMembers.addAll(decoded['hydra:member'] as List);
        final next = decoded['hydra:view']?['hydra:next'] as String?;
        nextUrl = next != null ? _join(next) : null;
      } else if (decoded is List) {
        allMembers.addAll(decoded);
        nextUrl = null;
      } else {
        nextUrl = null;
      }
    }

    return allMembers
        .map((m) => PartCategory.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<Part> fetchPartById(int partId) async {
    final r = await _get(Uri.parse(_join('/api/parts/$partId')));
    if (r.statusCode == 200) {
      return Part.fromJson(Map<String, dynamic>.from(json.decode(r.body)));
    } else {
      throw ApiException(r.statusCode, 'Fetch part error (${r.statusCode})');
    }
  }

  Future<List<Part>> fetchPartsNeedingReview() async {
    final List allMembers = [];
    String? nextUrl = _join('/api/parts?needs_review=true&itemsPerPage=100');

    while (nextUrl != null && allMembers.length < 2000) {
      final r = await _get(Uri.parse(nextUrl));
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, 'Fetch review parts error (${r.statusCode})');
      }
      final decoded = json.decode(r.body);
      if (decoded is Map && decoded.containsKey('hydra:member')) {
        allMembers.addAll(decoded['hydra:member'] as List);
        final next = decoded['hydra:view']?['hydra:next'] as String?;
        nextUrl = next != null ? _join(next) : null;
      } else if (decoded is List) {
        allMembers.addAll(decoded);
        nextUrl = null;
      } else {
        nextUrl = null;
      }
    }

    return allMembers
        .map((m) => Part.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<List<StorageLocation>> fetchStorageLocations() async {
    final List allMembers = [];
    String? nextUrl = _join('/api/storage_locations?itemsPerPage=200');

    while (nextUrl != null) {
      final r = await _get(Uri.parse(nextUrl));
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, 'Fetch locations error (${r.statusCode})');
      }
      final decoded = json.decode(r.body);
      if (decoded is Map && decoded.containsKey('hydra:member')) {
        allMembers.addAll(decoded['hydra:member'] as List);
        final next = decoded['hydra:view']?['hydra:next'] as String?;
        nextUrl = next != null ? _join(next) : null;
      } else if (decoded is List) {
        allMembers.addAll(decoded);
        nextUrl = null;
      } else {
        nextUrl = null;
      }
    }

    return allMembers
        .map((m) => StorageLocation.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<void> patchPartNeedsReview(int partId, bool value) async {
    final r = await _patch(
      Uri.parse(_join('/api/parts/$partId')),
      json.encode({'needs_review': value}),
    );
    if (r.statusCode != 200) {
      throw ApiException(r.statusCode, _extractError(r, 'Save needs_review error'));
    }
  }

  Future<void> patchPartLotStorageLocation(int lotId, String locationIri) async {
    final r = await _patch(
      Uri.parse(_join('/api/part_lots/$lotId')),
      json.encode({'storage_location': locationIri}),
    );
    if (r.statusCode != 200) {
      throw ApiException(r.statusCode, _extractError(r, 'Save lot location error'));
    }
  }

  Future<void> patchPartLotAmount(int lotId, double amount) async {
    final r = await _patch(
      Uri.parse(_join('/api/part_lots/$lotId')),
      json.encode({'amount': amount}),
    );
    if (r.statusCode != 200) {
      throw ApiException(r.statusCode, _extractError(r, 'Save lot amount error'));
    }
  }

  /// Tworzy nowy lot w 2 krokach: POST (bez storage_location), potem PATCH z lokalizacją.
  Future<PartLot> createPartLot(int partId, double amount, String locationIri) async {
    final postR = await _post(
      Uri.parse(_join('/api/part_lots')),
      json.encode({'part': '/api/parts/$partId', 'amount': amount}),
    );
    if (postR.statusCode != 201) {
      throw ApiException(postR.statusCode, _extractError(postR, 'Create lot error'));
    }
    final created = PartLot.fromJson(Map<String, dynamic>.from(json.decode(postR.body)));

    await patchPartLotStorageLocation(created.id, locationIri);
    return created;
  }

  /// Cached IRI pierwszego dostępnego typu załącznika.
  String? _defaultAttachmentTypeIri;

  Future<String?> _getDefaultAttachmentTypeIri() async {
    if (_defaultAttachmentTypeIri != null) return _defaultAttachmentTypeIri;
    try {
      final r = await _get(Uri.parse(_join('/api/attachment_types?itemsPerPage=1')));
      if (r.statusCode == 200) {
        final decoded = json.decode(r.body);
        final members = decoded is Map
            ? (decoded['hydra:member'] ?? decoded['member'] ?? [])
            : decoded;
        if (members is List && members.isNotEmpty) {
          final iri = members.first['@id']?.toString() ??
              '/api/attachment_types/${members.first['id']}';
          _defaultAttachmentTypeIri = iri;
          return iri;
        }
      }
    } catch (_) {
      // typy opcjonalne — kontynuuj bez nich
    }
    return null;
  }

  Future<void> uploadAttachment(int partId, Uint8List imageBytes, String filename) async {
    final base64data = base64Encode(imageBytes);
    final mimeType = filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mimeType;base64,$base64data';
    final attachmentTypeIri = await _getDefaultAttachmentTypeIri();

    final bodyMap = <String, dynamic>{
      'name': filename,
      'element': '/api/parts/$partId',
      'uploadFile': dataUrl,
    };
    if (attachmentTypeIri != null) bodyMap['attachment_type'] = attachmentTypeIri;
    final body = json.encode(bodyMap);

    final r = await http.post(
      Uri.parse(_join('/api/attachments')),
      headers: {..._headers(), 'Content-Type': 'application/ld+json'},
      body: body,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Timeout przy wysyłaniu zdjęcia'),
    );

    if (r.statusCode != 201 && r.statusCode != 200) {
      throw ApiException(r.statusCode, _extractError(r, 'Upload attachment error'));
    }
  }

}

class PartDetails {
  final List<PartParameter> params;
  final String category;
  final String manufacturer;

  const PartDetails({
    required this.params,
    this.category = '',
    this.manufacturer = '',
  });
}

class PartCategory {
  final int id;
  final String name;
  final String iri;
  final String? parentIri;

  const PartCategory({
    required this.id,
    required this.name,
    required this.iri,
    this.parentIri,
  });

  factory PartCategory.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] is int) ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final parent = json['parent'];
    String? parentIri;
    if (parent is String && parent.startsWith('/api/')) {
      parentIri = parent;
    } else if (parent is Map) {
      parentIri = parent['@id']?.toString();
    }
    return PartCategory(
      id: id,
      name: json['name']?.toString() ?? '',
      iri: json['@id']?.toString() ?? '/api/categories/$id',
      parentIri: parentIri,
    );
  }
}
