import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';
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
  String _selectedLocale = 'en';

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
    _selectedLocale = widget.apiService.locale;
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
    final l10n = AppLocalizations.of(context)!;
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
        _status = l10n.configTokenOk(info['user']?.toString() ?? 'unknown');
        _tokenHidden = true;
      });
    } catch (e) {
      setState(() {
        _status = l10n.configTokenSavedButFailed(e.toString());
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.configTitle)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: l10n.configBaseUrlHint,
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
                  tooltip: l10n.configScanToken,
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
                  : Text(l10n.configSaveAndVerify),
            ),
            const SizedBox(height: 12),
            Text(_status),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.configZoomLevel,
                  style: const TextStyle(fontSize: 16),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.configLanguage,
                  style: const TextStyle(fontSize: 16),
                ),
                DropdownButton<String>(
                  value: _selectedLocale,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'pl', child: Text('Polski')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLocale = value);
                      widget.apiService.saveLocale(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  l10n.configPrinters,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SwitchListTile(
              title: Text(l10n.configSunmiTitle),
              subtitle: Text(l10n.configSunmiSubtitle),
              value: _sunmiEnabled,
              onChanged: (value) {
                setState(() => _sunmiEnabled = value);
                widget.apiService.saveSunmiEnabled(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text(l10n.configNiimbotTitle),
              subtitle: Text(l10n.configNiimbotSubtitle),
              value: _niimbotEnabled,
              onChanged: (value) {
                setState(() => _niimbotEnabled = value);
                widget.apiService.saveNiimbotEnabled(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Spacer(),
            const SizedBox(height: 16),
            if (_appVersion.isNotEmpty)
              Text(
                l10n.configAppVersion(_appVersion),
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
