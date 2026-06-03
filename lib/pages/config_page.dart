import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';
import 'barcode_scan_page.dart';

class ConfigPage extends StatefulWidget {
  final ApiService apiService;
  const ConfigPage({required this.apiService, super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  double _selectedZoom = 2.0;

  final List<double> _zoomLevels = [
    1.0, 1.25, 1.5, 1.75,
    2.0, 2.25, 2.5, 2.75,
    3.0,
  ];

  bool _loading = false;
  bool _tokenHidden = false;
  String _status = '';
  String _appVersion = '';
  bool _sunmiEnabled = true;
  bool _niimbotEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _urlController.text = widget.apiService.baseUrl;
    _tokenController.text = widget.apiService.token;
    _tokenHidden = widget.apiService.token.isNotEmpty;
    _selectedZoom = widget.apiService.zoomLevel;
    _sunmiEnabled = widget.apiService.sunmiEnabled;
    _niimbotEnabled = widget.apiService.niimbotEnabled;
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _scanToken() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScanPage(apiService: widget.apiService),
      ),
    );
    if (scanned != null && scanned.isNotEmpty) {
      setState(() {
        _tokenController.text = scanned;
        _tokenHidden = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    final tokenToSave =
    _tokenHidden ? widget.apiService.token : _tokenController.text.trim();

    await widget.apiService
        .saveConfig(_urlController.text.trim(), tokenToSave);

    try {
      final info = await widget.apiService.getCurrentTokenInfo();
      setState(() {
        _status = '✅ Token OK (user: ${info['user'] ?? 'unknown'})';
        _tokenHidden = true;
      });
    } catch (e) {
      setState(() {
        _status = '⚠️ Token zapisany, ale weryfikacja nie powiodła się: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfiguracja Part-DB')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL (np. http://192.168.1.10:8000)',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    obscureText: _tokenHidden,
                    decoration: InputDecoration(
                      labelText: 'API Token',
                      suffixIcon: IconButton(
                        icon: Icon(_tokenHidden ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() {
                          _tokenHidden = !_tokenHidden;
                        }),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Skanuj token',
                  onPressed: _scanToken,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Zapisz i sprawdź token'),
            ),
            const SizedBox(height: 12),
            Text(_status),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Zoom level',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  width: 110,
                  child: DropdownButton<double>(
                    isExpanded: true,
                    value: _selectedZoom,
                    items: _zoomLevels.map((z) {
                      return DropdownMenuItem<double>(
                        value: z,
                        child: Text('x${z.toString().replaceAll('.', ',')}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedZoom = value;
                          widget.apiService.saveZoomLevel(_selectedZoom);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Drukarki',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Drukarka Sunmi'),
              subtitle: const Text('Drukowanie paragonów/etykiet przez Sunmi'),
              value: _sunmiEnabled,
              onChanged: (value) {
                setState(() => _sunmiEnabled = value);
                widget.apiService.saveSunmiEnabled(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Drukarka Niimbot'),
              subtitle: const Text('Drukowanie etykiet przez Niimbot Bluetooth'),
              value: _niimbotEnabled,
              onChanged: (value) {
                setState(() => _niimbotEnabled = value);
                widget.apiService.saveNiimbotEnabled(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Spacer(),
            const SizedBox(height: 16),

            // 🔹 Dyskretna wersja aplikacji
            if (_appVersion.isNotEmpty)
              Text(
                'Wersja aplikacji v$_appVersion',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),




          ],
        ),
      ),
    );
  }
}
