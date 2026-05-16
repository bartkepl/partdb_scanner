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
  final _secureStorage = const FlutterSecureStorage();

  ApiService();

  Future<void> loadConfig() async {
    final url = await _secureStorage.read(key: 'partdb_base_url');
    final t = await _secureStorage.read(key: 'partdb_token');
    final zoom = await _secureStorage.read(key: 'camera_zoom');

    baseUrl = url ?? '';
    token = t ?? '';
    zoomLevel = double.tryParse(zoom ?? '2.0') ?? 2.0;
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
        onTimeout: () => throw TimeoutException('Brak odpowiedzi serwera (timeout 10s)'),
      );

  Future<http.Response> _patch(Uri uri, String body) =>
      http.patch(
        uri,
        headers: {..._headers(), 'Content-Type': 'application/merge-patch+json'},
        body: body,
      ).timeout(
        _timeout,
        onTimeout: () => throw TimeoutException('Brak odpowiedzi serwera (timeout 10s)'),
      );

  Future<Map<String, dynamic>> getCurrentTokenInfo() async {
    final r = await _get(Uri.parse(_join('/api/tokens/current')));
    if (r.statusCode == 200) {
      return json.decode(r.body) as Map<String, dynamic>;
    } else {
      throw ApiException(r.statusCode, 'Błąd weryfikacji tokenu (${r.statusCode})');
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
          throw ApiException(404, 'Nie znaleziono części o IPN=$ipn');
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        return Part.fromJson(Map<String, dynamic>.from(decoded.first));
      } else if (decoded is Map && decoded.containsKey('id')) {
        return Part.fromJson(Map<String, dynamic>.from(decoded));
      } else {
        throw ApiException(404, 'Nie znaleziono części o IPN=$ipn');
      }
    } else {
      throw ApiException(r.statusCode, 'Błąd wyszukiwania IPN (${r.statusCode})');
    }
  }

  Future<List<Part>> fetchAllParts() async {
    final List allMembers = [];
    String? nextUrl = _join('/api/parts?itemsPerPage=100');

    while (nextUrl != null && allMembers.length < 2000) {
      final r = await _get(Uri.parse(nextUrl));
      if (r.statusCode != 200) {
        throw ApiException(r.statusCode, 'Błąd pobierania listy części (${r.statusCode})');
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

  Future<PartLot> patchPartLot(int lotId, double newAmount) async {
    final r = await _patch(
      Uri.parse(_join('/api/part_lots/$lotId')),
      json.encode({'amount': newAmount}),
    );

    if (r.statusCode == 200) {
      return PartLot.fromJson(Map<String, dynamic>.from(json.decode(r.body)));
    } else {
      throw ApiException(r.statusCode, 'Błąd zapisu stanu magazynowego (${r.statusCode})');
    }
  }

  Future<void> patchPartParameter(int parameterId, String newValue) async {
    final r = await _patch(
      Uri.parse(_join('/api/part_parameters/$parameterId')),
      json.encode({'value': newValue}),
    );

    if (r.statusCode != 200) {
      throw ApiException(r.statusCode, 'Błąd zapisu parametru (${r.statusCode})');
    }
  }

  Future<void> patchPartIPN(int partId, String newIpn) async {
    final r = await _patch(
      Uri.parse(_join('/api/parts/$partId')),
      json.encode({'ipn': newIpn}),
    );

    if (r.statusCode != 200) {
      throw ApiException(r.statusCode, 'Błąd zapisu IPN (${r.statusCode})');
    }
  }

  Future<List<PartParameter>> fetchPartParameters(int partId) async {
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

      return params;
    } else {
      throw ApiException(r.statusCode, 'Błąd pobierania parametrów (${r.statusCode})');
    }
  }
}
