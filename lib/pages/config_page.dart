import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAppVersion();

    widget.apiService.loadConfig().then((_) {
      setState(() {
        _urlController.text = widget.apiService.baseUrl;
        _tokenController.text = widget.apiService.token;
        if (_tokenController.text.isNotEmpty) _tokenHidden = true;
      });
      _selectedZoom = widget.apiService.zoomLevel;
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
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

    await widget.apiService.saveZoomLevel(_selectedZoom);


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
            TextField(
              controller: _tokenController,
              obscureText: _tokenHidden,
              decoration: InputDecoration(
                labelText: 'API Token',
                suffixIcon: IconButton(
                  icon: Icon(
                      _tokenHidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() {
                    _tokenHidden = !_tokenHidden;
                  }),
                ),
              ),
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
            const Spacer(),
            const SizedBox(height: 16),

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
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

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
