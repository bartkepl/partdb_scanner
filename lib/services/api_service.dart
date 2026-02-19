import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/part.dart';

bool kDebugMode = false;


class ApiService {
  String baseUrl = '';
  String token = '';
  double zoomLevel = 2.0; // domyślnie x2
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
  }

  Future<void> saveZoomLevel(double zoom) async {
    await _secureStorage.write(key: 'camera_zoom', value: zoom.toString());
    zoomLevel = zoom;
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: 'partdb_token');
    token = '';
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

  // 🔧 PRZYWRÓCONA METODA _join()
  String _join(String path) {
    if (baseUrl.endsWith('/')) {
      return '$baseUrl${path.startsWith('/') ? path.substring(1) : path}';
    } else {
      return '$baseUrl$path';
    }
  }

  Future<Map<String, dynamic>> getCurrentTokenInfo() async {
    final url = _join('/api/tokens/current');
    final r = await http.get(Uri.parse(url), headers: _headers());
    if (r.statusCode == 200) {
      return json.decode(r.body) as Map<String, dynamic>;
    } else {
      throw Exception('Token info error: ${r.statusCode} ${r.body}');
    }
  }

  Future<Part> findPartByIPN(String ipn) async {
    final url = _join('/api/parts?ipn=${Uri.encodeQueryComponent(ipn)}');
    final r = await http.get(Uri.parse(url), headers: _headers());

    if (r.statusCode == 200) {
      final decoded = json.decode(r.body);
      if (kDebugMode) {
        print('DEBUG: findPartByIPN response = $decoded');
      } // 👈 Debug

      if (decoded is Map && decoded.containsKey('hydra:member')) {
        final members = decoded['hydra:member'];
        if (members is List && members.isNotEmpty) {
          return Part.fromJson(Map<String, dynamic>.from(members.first));
        } else {
          throw Exception('Nie znaleziono części o IPN=$ipn');
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        return Part.fromJson(Map<String, dynamic>.from(decoded.first));
      } else if (decoded is Map && decoded.containsKey('id')) {
        return Part.fromJson(Map<String, dynamic>.from(decoded));
      } else {
        throw Exception('Nie znaleziono części o IPN=$ipn');
      }
    } else {
      throw Exception('Błąd wyszukiwania IPN: ${r.statusCode} ${r.body}');
    }
  }

  Future<List<Part>> searchPartsAdvanced(String query,
      {bool searchInParams = true, bool searchInValues = true}) async {
    final lowerQuery = query.toLowerCase();
    final List<Part> results = [];

    final url = _join('/api/parts?itemsPerPage=300');
    final r = await http.get(Uri.parse(url), headers: _headers());

    if (r.statusCode == 200) {
      final decoded = json.decode(r.body);
      List members = [];
      if (decoded is Map && decoded.containsKey('hydra:member')) {
        members = decoded['hydra:member'];
      } else if (decoded is List) {
        members = decoded;
      }

      for (final m in members) {
        final part = Part.fromJson(Map<String, dynamic>.from(m));
        final name = part.name.toLowerCase();
        final ipn = part.partNumber.toLowerCase();
        final unit = part.unit.toLowerCase();
        final description = (m is Map && m['description'] != null)
            ? m['description'].toString().toLowerCase()
            : '';
        final locations =
        part.partLots.map((l) => l.locationName.toLowerCase()).join(' ');
        final paramNames =
        part.parameters.map((p) => p.name.toLowerCase()).join(' ');
        final paramValues =
        part.parameters.map((p) => p.value.toLowerCase()).join(' ');

        bool match = false;

        if (name.contains(lowerQuery) ||
            ipn.contains(lowerQuery) ||
            unit.contains(lowerQuery) ||
            description.contains(lowerQuery) ||
            locations.contains(lowerQuery)) {
          match = true;
        }

        if (!match && searchInParams && paramNames.contains(lowerQuery)) {
          match = true;
        }

        if (!match &&
            searchInValues &&
            (paramValues.contains(lowerQuery) ||
                description.contains(lowerQuery) ||
                name.contains(lowerQuery) ||
                ipn.contains(lowerQuery))) {
          match = true;
        }

        if (match) results.add(part);
      }
    } else {
      throw Exception('Błąd pobierania listy części: ${r.statusCode} ${r.body}');
    }

    return results;
  }

  Future<PartLot> patchPartLot(int lotId, double newAmount) async {
    final url = _join('/api/part_lots/$lotId');
    final r = await http.patch(
      Uri.parse(url),
      headers: {
        ..._headers(),
        'Content-Type': 'application/merge-patch+json',
      },
      body: json.encode({'amount': newAmount}),
    );

    if (r.statusCode == 200) {
      final body = json.decode(r.body);
      return PartLot.fromJson(Map<String, dynamic>.from(body));
    } else {
      throw Exception('Patch partLot error: ${r.statusCode} ${r.body}');
    }
  }

  Future<void> patchPartParameter(int parameterId, String newValue) async {
    final url = _join('/api/part_parameters/$parameterId');
    final r = await http.patch(
      Uri.parse(url),
      headers: {
        ..._headers(),
        'Content-Type': 'application/merge-patch+json',
      },
      body: json.encode({'value': newValue}),
    );

    if (r.statusCode != 200) {
      throw Exception('Błąd zapisu parametru: ${r.statusCode} ${r.body}');
    }
  }

  Future<List<PartParameter>> fetchPartParameters(int partId) async {
    final url = _join('/api/parts/$partId');
    final r = await http.get(Uri.parse(url), headers: _headers());

    if (r.statusCode == 200) {
      final decoded = json.decode(r.body);
      if (kDebugMode) {
        print('DEBUG: fetchPartParameters for partId=$partId -> $decoded');
      } // 👈

      final List<PartParameter> params = [];
      final rawParams = (decoded['parameters'] is List)
          ? decoded['parameters']
          : (decoded['part_parameters'] ?? []);

      for (final p in rawParams) {
        if (p is Map) {
          final casted = p.map((k, v) => MapEntry(k.toString(), v));
          params.add(PartParameter.fromJson(casted));
        } else if (p is String) {
          params.add(
              PartParameter(id: 0, name: p, value: '', unit: ''));
        }
      }

      return params;
    } else {
      throw Exception('Błąd pobierania parametrów: ${r.statusCode} ${r.body}');
    }
  }
}
