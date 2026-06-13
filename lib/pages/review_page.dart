import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
    for (final c in _ipnControllers.values) { c.dispose(); }
    for (final c in _amountControllers.values) { c.dispose(); }
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

      for (final c in _ipnControllers.values) { c.dispose(); }
      for (final c in _amountControllers.values) { c.dispose(); }
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

  Future<void> _generateIpns() async {
    final l10n = AppLocalizations.of(context)!;
    final targets = _parts
        .where((p) => _selected.contains(p.id) && (_ipnControllers[p.id]?.text.trim().isEmpty ?? true))
        .toList();

    if (targets.isEmpty) {
      _showSnack(l10n.noPartsWithoutIpnSelected, isError: true);
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
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.generatedIpnCount(generated.length));
    } catch (e) {
      if (!mounted) return;
      _showSnack(AppLocalizations.of(context)!.generateIpnError(e.toString()), isError: true);
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

  Future<void> _assignLocation() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selected.isEmpty) {
      _showSnack(l10n.selectParts, isError: true);
      return;
    }
    if (_locations.isEmpty) return;

    StorageLocation? chosen = _locations.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.assignLocationTitle),
          content: DropdownButton<StorageLocation>(
            isExpanded: true,
            value: chosen,
            items: _locations
                .map((l) => DropdownMenuItem(value: l, child: Text(l.fullPath)))
                .toList(),
            onChanged: (v) => setS(() => chosen = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.assign)),
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

  Future<void> _confirmSelected() async {
    final l10n = AppLocalizations.of(context)!;
    final toConfirm = _parts.where((p) => _selected.contains(p.id) && _isReady(p)).toList();
    if (toConfirm.isEmpty) {
      _showSnack(l10n.noReadyParts, isError: true);
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

        if (ipn != part.partNumber) {
          await _api.patchPartIPN(part.id, ipn);
        }

        if (part.partLots.isEmpty) {
          await _api.createPartLot(part.id, amount, locationIri);
        } else {
          final lot = part.partLots.first;
          await _api.patchPartLotStorageLocation(lot.id, locationIri);
          if (lot.amount != amount) {
            await _api.patchPartLotAmount(lot.id, amount);
          }
        }

        await _api.patchPartNeedsReview(part.id, false);
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

    if (!mounted) return;
    if (errors.isNotEmpty) {
      _showSnack(l10n.confirmErrors(errors.join('; ')), isError: true);
    } else {
      _showSnack(l10n.confirmedPartsCount(toConfirm.length));
    }
  }

  Future<void> _printConfirmed() async {
    final l10n = AppLocalizations.of(context)!;
    if (_labelType == null) {
      _showSnack(l10n.selectLabelType, isError: true);
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

      if (!mounted) return;
      _showSnack(l10n.printedLabelsCount(_confirmedParts.length));
    } catch (e) {
      if (!mounted) return;
      _showSnack(l10n.printError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _printing = false);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_parts.isEmpty && !_loading
            ? l10n.reviewTitleEmpty
            : l10n.reviewTitle(_parts.length)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(l10n)
              : _buildBody(l10n),
      bottomNavigationBar: _buildBottomBar(l10n),
    );
  }

  Widget _buildError(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text(l10n.tryAgain)),
            ],
          ),
        ),
      );

  Widget _buildBody(AppLocalizations l10n) {
    if (_parts.isEmpty && _confirmedParts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 12),
            Text(l10n.noPartsToReview),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildLabelTypeSelector(l10n),
        if (_parts.isNotEmpty) _buildTopActions(l10n),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              ..._parts.map(_buildPartCard),
              if (_confirmedParts.isNotEmpty) _buildConfirmedBanner(l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabelTypeSelector(AppLocalizations l10n) {
    final locked = _confirmedParts.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          if (locked) const Icon(Icons.lock, size: 16, color: Colors.orange),
          if (locked) const SizedBox(width: 4),
          Expanded(
            child: SegmentedButton<LabelTypeChoice>(
              segments: [
                ButtonSegment(
                  value: LabelTypeChoice.drawer,
                  icon: const Icon(Icons.view_module, size: 16),
                  label: Text(l10n.drawerLabel),
                ),
                ButtonSegment(
                  value: LabelTypeChoice.spool,
                  icon: const Icon(Icons.radio_button_checked, size: 16),
                  label: Text(l10n.spoolLabel),
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
              child: Text(l10n.reset),
            ),
        ],
      ),
    );
  }

  Widget _buildTopActions(AppLocalizations l10n) {
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
            label: Text(l10n.generateIpnBtn),
            onPressed: _selected.isEmpty ? null : _generateIpns,
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            icon: const Icon(Icons.place, size: 16),
            label: Text(l10n.location),
            onPressed: _selected.isEmpty ? null : _assignLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(Part p) {
    final ready = _isReady(p);
    final selected = _selected.contains(p.id);
    final l10n = AppLocalizations.of(context)!;

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
                    child: _buildLocationDropdown(p, l10n),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _amountControllers[p.id],
                      decoration: InputDecoration(
                        labelText: l10n.quantity,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: const OutlineInputBorder(),
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

  Widget _buildLocationDropdown(Part p, AppLocalizations l10n) {
    final current = _locationDraft[p.id];
    return InputDecorator(
      decoration: InputDecoration(
        labelText: l10n.locationLabel,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StorageLocation>(
          value: current,
          isExpanded: true,
          isDense: true,
          hint: Text(l10n.chooseDots, style: const TextStyle(fontSize: 12)),
          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
          items: [
            DropdownMenuItem<StorageLocation>(
              value: null,
              child: Text(l10n.none, style: const TextStyle(fontSize: 12)),
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

  Widget _buildConfirmedBanner(AppLocalizations l10n) {
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
          Text(l10n.confirmedBanner(_confirmedParts.length),
              style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
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
                      _niimbot.isConnected ? l10n.printerConnected : l10n.noPrinter,
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
                      label: Text(l10n.printLabelsCount(_confirmedParts.length)),
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
                          ? l10n.confirmReady(readyCount)
                          : l10n.confirmSelected,
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
