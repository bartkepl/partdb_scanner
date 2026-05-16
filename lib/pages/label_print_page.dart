import 'package:flutter/material.dart';
import '../models/label_config.dart';
import '../models/part.dart';
import '../services/niimbot_service.dart';

class LabelPrintPage extends StatefulWidget {
  final Part part;
  const LabelPrintPage({required this.part, super.key});

  @override
  State<LabelPrintPage> createState() => _LabelPrintPageState();
}

class _LabelPrintPageState extends State<LabelPrintPage> {
  final _niimbot = NiimbotService.instance;

  bool _printDrawer = true;
  bool _printSpoolParam = false;
  bool _printSpoolBarcode = false;

  int _drawerFontSize = 18;
  static const _drawerFontMin = 10;
  static const _drawerFontMax = 26;

  bool _loadingConfig = true;
  bool _printing = false;
  String _status = '';

  late LabelConfig _config;

  /// Kontrolery wartości parametrów – klucz: nazwa parametru.
  /// Wstępnie wypełnione wartościami z bazy, edytowalne bez zapisu.
  final Map<String, TextEditingController> _valueControllers = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    for (final c in _valueControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final saved = await LabelConfig.load();
    final partParams = widget.part.parameters
        .where((p) => p.value.isNotEmpty && p.value != '0')
        .toList();
    final paramNames = partParams.map((p) => p.name).toList();

    final config = LabelConfig.mergeWithParams(saved, paramNames);

    // Utwórz kontrolery dla każdego parametru, wstępnie z wartością z bazy
    for (final entry in config.entries) {
      final dbParam = partParams.where((p) => p.name == entry.name).firstOrNull;
      final dbValue = dbParam != null
          ? (dbParam.unit.isNotEmpty
              ? '${dbParam.value} ${dbParam.unit}'
              : dbParam.value)
          : '';
      _valueControllers[entry.name] = TextEditingController(text: dbValue);
    }

    setState(() {
      _config = config;
      _loadingConfig = false;
    });
  }

  List<PrintParam> _buildPrintParams() {
    return _config.entries
        .where((e) => e.enabled)
        .map((e) {
          final val = _valueControllers[e.name]?.text.trim() ?? '';
          return (name: e.name, value: val, bold: e.bold);
        })
        .where((p) => p.value.isNotEmpty)
        .toList();
  }

  Future<void> _connect() async {
    setState(() => _status = 'Łączenie z drukarką...');
    try {
      await _niimbot.connect();
      setState(() => _status = '✅ Połączono');
    } catch (e) {
      setState(() => _status = '❌ Błąd połączenia: $e');
    }
  }

  Future<void> _disconnect() async {
    await _niimbot.disconnect();
    setState(() => _status = 'Rozłączono');
  }

  Future<void> _print() async {
    if (!_niimbot.isConnected) {
      await _connect();
      if (!_niimbot.isConnected) return;
    }

    if (!_printDrawer && !_printSpoolParam && !_printSpoolBarcode) {
      setState(() => _status = '⚠️ Wybierz co najmniej jeden typ etykiety');
      return;
    }

    setState(() {
      _printing = true;
      _status = 'Drukuję...';
    });

    try {
      await _config.save();
      final params = _buildPrintParams();

      if (_printDrawer) {
        setState(() => _status = 'Drukuję etykietę szufladkową...');
        await _niimbot.printDrawerLabel(widget.part, fontSize: _drawerFontSize);
      }

      if (_printSpoolParam && _printSpoolBarcode) {
        setState(() => _status = 'Drukuję etykiety szpulki...');
        await _niimbot.printSpoolLabels(widget.part, params);
      } else if (_printSpoolParam) {
        setState(() => _status = 'Drukuję etykietę parametrów...');
        await _niimbot.printSpoolParamLabel(widget.part, params);
      } else if (_printSpoolBarcode) {
        setState(() => _status = 'Drukuję etykietę z kodem 1D...');
        await _niimbot.printSpoolBarcodeLabel(widget.part);
      }

      setState(() => _status = '✅ Wydrukowano');
    } catch (e) {
      setState(() => _status = '❌ Błąd drukowania: $e');
    } finally {
      setState(() => _printing = false);
    }
  }

  void _moveParam(int index, int delta) {
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _config.entries.length) return;
    setState(() {
      // Przenieś też kontroler wartości (trzymamy go w mapie po nazwie – OK)
      final entry = _config.entries.removeAt(index);
      _config.entries.insert(newIndex, entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Etykiety: ${widget.part.name}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_niimbot.isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_connected, color: Colors.blue),
              tooltip: 'Rozłącz drukarkę',
              onPressed: _printing ? null : _disconnect,
            )
          else
            IconButton(
              icon: const Icon(Icons.bluetooth, color: Colors.grey),
              tooltip: 'Połącz z drukarką',
              onPressed: _printing ? null : _connect,
            ),
        ],
      ),
      body: _loadingConfig
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _buildLabelTypeSection(),
                      if (_printDrawer) ...[
                        const SizedBox(height: 16),
                        _buildDrawerConfigSection(),
                      ],
                      if (_printSpoolParam) ...[
                        const SizedBox(height: 16),
                        _buildParamConfigSection(),
                      ],
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildLabelTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Typ etykiety',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            _LabelTypeRow(
              icon: Icons.inventory_2_outlined,
              label: 'Szufladkowa 22×14mm',
              sublabel: 'Nazwa + DataMatrix',
              value: _printDrawer,
              onChanged: (v) => setState(() => _printDrawer = v),
            ),
            const Divider(height: 1, indent: 16),
            _LabelTypeRow(
              icon: Icons.view_list_outlined,
              label: 'Szpulka – parametry 12×40mm',
              sublabel: 'Tekst + DataMatrix',
              value: _printSpoolParam,
              onChanged: (v) => setState(() => _printSpoolParam = v),
            ),
            const Divider(height: 1, indent: 16),
            _LabelTypeRow(
              icon: Icons.qr_code_2,
              label: 'Szpulka – kod 1D 12×40mm',
              sublabel: 'Kod kreskowy Code128',
              value: _printSpoolBarcode,
              onChanged: (v) => setState(() => _printSpoolBarcode = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konfiguracja etykiety szufladkowej',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.format_size, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Rozmiar tekstu nazwy:'),
                const Spacer(),
                // Przycisk zmniejszenia
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _drawerFontSize > _drawerFontMin
                        ? () => setState(() => _drawerFontSize -= 1)
                        : null,
                  ),
                ),
                // Podgląd rozmiaru – tekst przykładowy
                Container(
                  width: 80,
                  alignment: Alignment.center,
                  child: Text(
                    'Aa $_drawerFontSize',
                    style: TextStyle(
                      fontSize: _drawerFontSize.toDouble().clamp(12, 22),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Przycisk zwiększenia
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _drawerFontSize < _drawerFontMax
                        ? () => setState(() => _drawerFontSize += 1)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Parametry na etykiecie szpulki',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            ..._config.entries.asMap().entries.map((mapEntry) {
              final i = mapEntry.key;
              final param = mapEntry.value;
              final ctrl = _valueControllers[param.name];

              return Column(
                children: [
                  if (i > 0) const Divider(height: 1, indent: 56),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        // Toggle włącz/wyłącz
                        Switch(
                          value: param.enabled,
                          onChanged: (v) => setState(() => param.enabled = v),
                        ),
                        const SizedBox(width: 4),

                        // Pole edytowalne wartości + etykieta nazwy
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                param.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: param.enabled
                                      ? Colors.grey
                                      : Colors.grey.shade700,
                                ),
                              ),
                              TextField(
                                controller: ctrl,
                                enabled: param.enabled,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: param.enabled
                                      ? Colors.orange
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Przyciski kolejności + Bold
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 28,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                icon: const Icon(Icons.arrow_upward),
                                onPressed: i > 0 ? () => _moveParam(i, -1) : null,
                              ),
                            ),
                            // Przycisk Bold
                            SizedBox(
                              width: 32,
                              height: 28,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  foregroundColor: param.bold
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                                onPressed: param.enabled
                                    ? () => setState(() => param.bold = !param.bold)
                                    : null,
                                child: Text(
                                  'B',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: param.bold
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 28,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 18,
                                icon: const Icon(Icons.arrow_downward),
                                onPressed: i < _config.entries.length - 1
                                    ? () => _moveParam(i, 1)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _status.startsWith('❌') ? Colors.red : null,
                  ),
                ),
              ),
            Row(
              children: [
                if (!_niimbot.isConnected) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('Połącz'),
                      onPressed: _printing ? null : _connect,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: _printing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.print),
                    label: const Text('Drukuj'),
                    onPressed: _printing ? null : _print,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelTypeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LabelTypeRow({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: value ? Colors.orange : null),
      title: Text(label),
      subtitle: Text(sublabel),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
