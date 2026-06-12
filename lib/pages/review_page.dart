import 'dart:math';
import 'package:flutter/material.dart';
import '../models/label_config.dart';
import '../models/part.dart';
import '../services/api_service.dart';
import '../services/niimbot_service.dart';

enum LabelTypeChoice { drawer, spool }

class ReviewPage extends StatefulWidget {
  final ApiService apiService;
  const ReviewPage({required this.apiService, super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<Part> _parts = [];
  final List<Part> _confirmedParts = [];
  List<StorageLocation> _locations = [];

  bool _loading = false;
  String? _error;
  bool _confirming = false;
  bool _printing = false;

  final Map<int, TextEditingController> _ipnControllers = {};
  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, StorageLocation?> _locationDraft = {};
  Set<int> _selected = {};

  LabelTypeChoice? _labelType;

  ApiService get _api => widget.apiService;
  NiimbotService get _niimbot => NiimbotService.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _ipnControllers.values) {
      c.dispose();
    }
    for (final c in _amountControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchPartsNeedingReview(),
        _api.fetchStorageLocations(),
      ]);
      final parts = results[0] as List<Part>;
      final locations = results[1] as List<StorageLocation>;

      for (final c in _ipnControllers.values) {
        c.dispose();
      }
      for (final c in _amountControllers.values) {
        c.dispose();
      }
      _ipnControllers.clear();
      _amountControllers.clear();
      _locationDraft.clear();

      for (final p in parts) {
        _ipnControllers[p.id] = TextEditingController(text: p.partNumber);
        final stock = p.totalStock > 0 ? p.totalStock.toString() : '1';
        _amountControllers[p.id] = TextEditingController(text: stock);

        StorageLocation? preselected;
        if (p.partLots.isNotEmpty && p.partLots.first.locationIri.isNotEmpty) {
          final iri = p.partLots.first.locationIri;
          try {
            preselected = locations.firstWhere((l) => l.iri == iri);
          } catch (_) {}
        }
        _locationDraft[p.id] = preselected;
      }

      setState(() {
        _parts = parts;
        _locations = locations;
        _selected = {};
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _isReady(Part p) {
    final ipn = _ipnControllers[p.id]?.text.trim() ?? '';
    final loc = _locationDraft[p.id];
    return ipn.isNotEmpty && loc != null;
  }

  // ─── Generowanie IPN ────────────────────────────────────────────────────

  Future<void> _generateIpns() async {
    final targets = _parts
        .where((p) => _selected.contains(p.id) && (_ipnControllers[p.id]?.text.trim().isEmpty ?? true))
        .toList();

    if (targets.isEmpty) {
      _showSnack('Brak zaznaczonych części bez IPN', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final all = await _api.fetchAllParts();
      final existingIpns = all.map((p) => p.partNumber.trim()).toSet();
      final generated = _buildIpns(targets, existingIpns);
      for (final entry in generated.entries) {
        _ipnControllers[entry.key]?.text = entry.value;
      }
      setState(() {});
      _showSnack('Wygenerowano IPN dla ${generated.length} części');
    } catch (e) {
      _showSnack('Błąd generowania IPN: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<int, String> _buildIpns(List<Part> targets, Set<String> existing) {
    final rng = Random();
    final usedNow = <String>{};
    final result = <int, String>{};
    for (final p in targets) {
      String ipn;
      int attempts = 0;
      do {
        ipn = (rng.nextInt(9000000) + 1000000).toString();
        attempts++;
      } while ((existing.contains(ipn) || usedNow.contains(ipn)) && attempts < 100);
      usedNow.add(ipn);
      result[p.id] = ipn;
    }
    return result;
  }

  // ─── Przypisanie lokalizacji ─────────────────────────────────────────────

  Future<void> _assignLocation() async {
    if (_selected.isEmpty) {
      _showSnack('Zaznacz części', isError: true);
      return;
    }
    if (_locations.isEmpty) return;

    StorageLocation? chosen = _locations.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Przypisz lokalizację'),
          content: DropdownButton<StorageLocation>(
            isExpanded: true,
            value: chosen,
            items: _locations
                .map((l) => DropdownMenuItem(value: l, child: Text(l.fullPath)))
                .toList(),
            onChanged: (v) => setS(() => chosen = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Przypisz')),
          ],
        ),
      ),
    );

    if (confirmed == true && chosen != null) {
      setState(() {
        for (final id in _selected) {
          _locationDraft[id] = chosen;
        }
      });
    }
  }

  // ─── Zatwierdzanie ───────────────────────────────────────────────────────

  Future<void> _confirmSelected() async {
    final toConfirm = _parts.where((p) => _selected.contains(p.id) && _isReady(p)).toList();
    if (toConfirm.isEmpty) {
      _showSnack('Brak gotowych części (wymagane IPN + lokalizacja)', isError: true);
      return;
    }

    setState(() => _confirming = true);
    final errors = <String>[];

    for (final part in toConfirm) {
      try {
        final ipn = _ipnControllers[part.id]!.text.trim();
        final location = _locationDraft[part.id]!;
        final amount = double.tryParse(_amountControllers[part.id]?.text ?? '1') ?? 1.0;
        final locationIri = '/api/storage_locations/${location.id}';

        // 1. PATCH IPN
        if (ipn != part.partNumber) {
          await _api.patchPartIPN(part.id, ipn);
        }

        // 2. Lot: utwórz lub zaktualizuj
        if (part.partLots.isEmpty) {
          await _api.createPartLot(part.id, amount, locationIri);
        } else {
          final lot = part.partLots.first;
          await _api.patchPartLotStorageLocation(lot.id, locationIri);
          if (lot.amount != amount) {
            await _api.patchPartLotAmount(lot.id, amount);
          }
        }

        // 3. Kasuj flagę needs_review
        await _api.patchPartNeedsReview(part.id, false);

        // 4. Re-fetch aktualnych danych do druku
        final fresh = await _api.fetchPartById(part.id);

        setState(() {
          _parts.removeWhere((p) => p.id == part.id);
          _confirmedParts.add(fresh);
          _selected.remove(part.id);
        });
      } catch (e) {
        errors.add('${part.name}: $e');
      }
    }

    setState(() => _confirming = false);

    if (errors.isNotEmpty) {
      _showSnack('Błędy: ${errors.join('; ')}', isError: true);
    } else {
      _showSnack('Zatwierdzono ${toConfirm.length} części');
    }
  }

  // ─── Drukowanie ──────────────────────────────────────────────────────────

  Future<void> _printConfirmed() async {
    if (_labelType == null) {
      _showSnack('Wybierz typ etykiety', isError: true);
      return;
    }
    if (_confirmedParts.isEmpty) return;

    setState(() => _printing = true);
    try {
      if (!_niimbot.isConnected) {
        await _niimbot.connect();
      }

      LabelConfig? config;
      if (_labelType == LabelTypeChoice.spool) {
        config = await LabelConfig.load();
      }

      for (final part in _confirmedParts) {
        if (_labelType == LabelTypeChoice.drawer) {
          await _niimbot.printDrawerLabel(part);
        } else {
          final paramNames = part.parameters.map((p) => p.name).toList();
          final merged = LabelConfig.mergeWithParams(config!, paramNames);
          final params = merged.entries
              .where((e) => e.enabled)
              .map((e) => (
                    name: e.name,
                    value: _paramValue(part, e.name),
                    bold: e.bold,
                  ))
              .toList();
          await _niimbot.printSpoolLabels(part, params);
        }
      }

      _showSnack('Wydrukowano ${_confirmedParts.length} etykiet');
    } catch (e) {
      _showSnack('Błąd drukowania: $e', isError: true);
    } finally {
      setState(() => _printing = false);
    }
  }

  String _paramValue(Part part, String name) {
    try {
      return part.parameters.firstWhere((p) => p.name == name).value;
    } catch (_) {
      return '';
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_parts.isEmpty && !_loading
            ? 'Przegląd części'
            : 'Przegląd (${_parts.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Spróbuj ponownie')),
            ],
          ),
        ),
      );

  Widget _buildBody() {
    if (_parts.isEmpty && _confirmedParts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 12),
            Text('Brak części do przeglądu'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildLabelTypeSelector(),
        if (_parts.isNotEmpty) _buildTopActions(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              ..._parts.map(_buildPartCard),
              if (_confirmedParts.isNotEmpty) _buildConfirmedBanner(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabelTypeSelector() {
    final locked = _confirmedParts.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          if (locked) const Icon(Icons.lock, size: 16, color: Colors.orange),
          if (locked) const SizedBox(width: 4),
          Expanded(
            child: SegmentedButton<LabelTypeChoice>(
              segments: const [
                ButtonSegment(
                  value: LabelTypeChoice.drawer,
                  icon: Icon(Icons.view_module, size: 16),
                  label: Text('Szufladkowa'),
                ),
                ButtonSegment(
                  value: LabelTypeChoice.spool,
                  icon: Icon(Icons.radio_button_checked, size: 16),
                  label: Text('Szpulkowa'),
                ),
              ],
              selected: _labelType != null ? {_labelType!} : {},
              emptySelectionAllowed: true,
              onSelectionChanged: locked
                  ? null
                  : (s) => setState(() => _labelType = s.isEmpty ? null : s.first),
              style: ButtonStyle(
                textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
              ),
            ),
          ),
          if (locked)
            TextButton(
              onPressed: () => setState(() {
                _confirmedParts.clear();
                _labelType = null;
              }),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Reset'),
            ),
        ],
      ),
    );
  }

  Widget _buildTopActions() {
    final selCount = _selected.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: _selected.length == _parts.length && _parts.isNotEmpty,
            tristate: _selected.isNotEmpty && _selected.length < _parts.length,
            onChanged: (v) => setState(() {
              if (v == true) {
                _selected = _parts.map((p) => p.id).toSet();
              } else {
                _selected = {};
              }
            }),
          ),
          Text('$selCount / ${_parts.length}',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text('Generuj IPN'),
            onPressed: _selected.isEmpty ? null : _generateIpns,
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            icon: const Icon(Icons.place, size: 16),
            label: const Text('Lokalizacja'),
            onPressed: _selected.isEmpty ? null : _assignLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(Part p) {
    final ready = _isReady(p);
    final selected = _selected.contains(p.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: ready
            ? const BorderSide(color: Colors.green, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(p.id);
                    } else {
                      _selected.remove(p.id);
                    }
                  }),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                      if (p.category.isNotEmpty)
                        Text('${p.category} · ID ${p.id}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(
                  ready ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: ready ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _ipnControllers[p.id],
                      decoration: const InputDecoration(
                        labelText: 'IPN',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: _buildLocationDropdown(p),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _amountControllers[p.id],
                      decoration: const InputDecoration(
                        labelText: 'Ilość',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDropdown(Part p) {
    final current = _locationDraft[p.id];
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Lokalizacja',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StorageLocation>(
          value: current,
          isExpanded: true,
          isDense: true,
          hint: const Text('Wybierz…', style: TextStyle(fontSize: 12)),
          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
          items: [
            const DropdownMenuItem<StorageLocation>(
              value: null,
              child: Text('— brak —', style: TextStyle(fontSize: 12)),
            ),
            ..._locations.map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(l.fullPath, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) => setState(() => _locationDraft[p.id] = v),
        ),
      ),
    );
  }

  Widget _buildConfirmedBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text('Zatwierdzone: ${_confirmedParts.length} części',
              style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final readyCount = _parts
        .where((p) => _selected.contains(p.id) && _isReady(p))
        .length;

    return SafeArea(
      child: Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_confirmedParts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      _niimbot.isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      color: _niimbot.isConnected ? Colors.blue : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _niimbot.isConnected ? 'Podłączono' : 'Brak drukarki',
                      style: TextStyle(
                          fontSize: 12,
                          color: _niimbot.isConnected ? Colors.blue : Colors.grey),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: _printing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print, size: 16),
                      label: Text('Drukuj ${_confirmedParts.length} etykiet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: (_printing || _labelType == null) ? null : _printConfirmed,
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      readyCount > 0
                          ? 'Zatwierdź ($readyCount)'
                          : 'Zatwierdź zaznaczone',
                    ),
                    onPressed: (_confirming || readyCount == 0) ? null : _confirmSelected,
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
