import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/part.dart';
import '../services/api_service.dart';
import 'barcode_scan_page.dart';

class _StockEntry {
  final Part part;
  final PartLot lot;
  final int originalAmount;
  int countedAmount;

  _StockEntry({
    required this.part,
    required this.lot,
    required this.originalAmount,
    required this.countedAmount,
  });

  bool get hasDiscrepancy => countedAmount != originalAmount;
  int get delta => countedAmount - originalAmount;
}

class StockTakingPage extends StatefulWidget {
  final ApiService apiService;
  const StockTakingPage({required this.apiService, super.key});

  @override
  State<StockTakingPage> createState() => _StockTakingPageState();
}

class _StockTakingPageState extends State<StockTakingPage> {
  final List<_StockEntry> _scanned = [];
  bool _scanning = false;
  bool _saving = false;

  Future<void> _scanNext() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => BarcodeScanPage(apiService: widget.apiService)),
    );
    if (raw == null || raw.isEmpty) return;

    setState(() => _scanning = true);
    try {
      final part = RegExp(r'^\d{7}$').hasMatch(raw)
          ? await widget.apiService.findPartByIPN(raw)
          : (await widget.apiService.searchByName(raw)).firstOrNull;

      if (!mounted) return;

      if (part == null) {
        _showMsg(l10n.notFound(raw), isError: true);
        return;
      }

      if (part.partLots.isEmpty) {
        _showMsg(l10n.noStorageLocations(part.name), isError: true);
        return;
      }

      final lot = part.partLots.length == 1
          ? part.partLots.first
          : await _chooseLot(part);
      if (lot == null) return;

      final existing = _scanned.where((e) => e.lot.id == lot.id).firstOrNull;
      if (existing != null) {
        _showMsg(l10n.alreadyOnList(part.name, lot.locationName), isError: false);
        return;
      }

      setState(() {
        _scanned.insert(0, _StockEntry(
          part: part,
          lot: lot,
          originalAmount: lot.amount.toInt(),
          countedAmount: lot.amount.toInt(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      _showMsg(l10n.errorGeneric(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<PartLot?> _chooseLot(Part part) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<PartLot>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chooseLocation(part.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: part.partLots
              .map((l) => ListTile(
                    title: Text(l.locationName),
                    subtitle: Text(AppLocalizations.of(ctx)!.stockAmount(l.amount.toInt())),
                    onTap: () => Navigator.pop(ctx, l),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context)!;
    final toSave = _scanned.where((e) => e.hasDiscrepancy).toList();
    if (toSave.isEmpty) {
      _showMsg(l10n.noDiscrepancies);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveCorrectionsTitle),
        content: Text(l10n.willUpdatePositions(toSave.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    int ok = 0, fail = 0;
    for (final e in toSave) {
      try {
        await widget.apiService.patchPartLot(
          e.lot.id,
          e.countedAmount.toDouble(),
          comment: 'Stock taking',
        );
        ok++;
      } catch (_) {
        fail++;
      }
    }
    if (mounted) {
      setState(() => _saving = false);
      _showMsg(l10n.savedWithErrors(ok, fail), isError: fail > 0);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final discrepancies = _scanned.where((e) => e.hasDiscrepancy).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stockTakingTitle),
        actions: [
          if (discrepancies > 0)
            Badge(
              label: Text('$discrepancies'),
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(Icons.save),
                tooltip: l10n.saveCorrectionsTooltip,
                onPressed: _saving ? null : _saveAll,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: l10n.saveCorrectionsTooltip,
              onPressed: _saving ? null : _saveAll,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_scanning) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.scanNextPart),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _scanning ? null : _scanNext,
            ),
          ),
          if (_scanned.isEmpty)
            Expanded(child: Center(child: Text(l10n.scanIpnOrName)))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _scanned.length,
                itemBuilder: (ctx, i) {
                  final e = _scanned[i];
                  return Card(
                    color: e.hasDiscrepancy ? Colors.orange.withAlpha(30) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.part.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${e.lot.locationName} • PartDB: ${e.originalAmount}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (e.countedAmount > 0) setState(() => e.countedAmount--);
                            },
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              '${e.countedAmount}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: e.hasDiscrepancy
                                    ? (e.delta > 0 ? Colors.green : Colors.red)
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => e.countedAmount++),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => setState(() => _scanned.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
