import 'dart:math';
import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/api_service.dart';

class IpnGeneratorPage extends StatefulWidget {
  final ApiService apiService;
  const IpnGeneratorPage({required this.apiService, super.key});

  @override
  State<IpnGeneratorPage> createState() => _IpnGeneratorPageState();
}

class _IpnGeneratorPageState extends State<IpnGeneratorPage> {
  List<Part> _partsWithoutIpn = [];
  Set<int> _selected = {};
  bool _loading = false;
  bool _saving = false;
  String _message = '';

  // wyniki ostatniego generowania: partId -> wygenerowany IPN
  Map<int, String> _generated = {};
  // wyniki wysyłania: partId -> sukces/błąd
  Map<int, String?> _saveResults = {};

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() {
      _loading = true;
      _message = '';
      _generated = {};
      _saveResults = {};
      _selected = {};
    });
    try {
      final all = await widget.apiService.fetchAllParts();
      setState(() {
        _partsWithoutIpn = all.where((p) => p.partNumber.trim().isEmpty).toList();
        _message = _partsWithoutIpn.isEmpty ? 'Wszystkie części mają już IPN.' : '';
      });
    } catch (e) {
      setState(() => _message = '❌ Błąd pobierania: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<int, String> _generateIPNs(List<Part> targets, Set<String> existing) {
    final rng = Random();
    final usedNow = <String>{};
    final result = <int, String>{};

    for (final part in targets) {
      String ipn;
      int attempts = 0;
      do {
        ipn = (rng.nextInt(9000000) + 1000000).toString();
        attempts++;
      } while ((existing.contains(ipn) || usedNow.contains(ipn)) && attempts < 100);
      usedNow.add(ipn);
      result[part.id] = ipn;
    }
    return result;
  }

  Future<void> _onGeneratePressed() async {
    if (_selected.isEmpty) return;

    setState(() {
      _loading = true;
      _saveResults = {};
    });

    try {
      final all = await widget.apiService.fetchAllParts();
      final existingIPNs = all.map((p) => p.partNumber.trim()).toSet();
      final targets = _partsWithoutIpn.where((p) => _selected.contains(p.id)).toList();
      final generated = _generateIPNs(targets, existingIPNs);

      final confirmed = await _showConfirmDialog(targets, generated);
      if (!confirmed) return;

      setState(() {
        _saving = true;
        _generated = generated;
      });

      final results = <int, String?>{};
      for (final part in targets) {
        final ipn = generated[part.id]!;
        try {
          await widget.apiService.patchPartIPN(part.id, ipn);
          results[part.id] = null; // sukces
        } catch (e) {
          results[part.id] = e.toString();
        }
      }

      setState(() => _saveResults = results);

      final successCount = results.values.where((v) => v == null).length;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Zapisano IPN: $successCount/${targets.length}'),
            backgroundColor: successCount == targets.length ? Colors.green : Colors.orange,
          ),
        );
      }

      // Odśwież listę po zapisaniu
      await _loadParts();
    } catch (e) {
      setState(() => _message = '❌ Błąd: $e');
    } finally {
      setState(() {
        _loading = false;
        _saving = false;
      });
    }
  }

  Future<bool> _showConfirmDialog(List<Part> targets, Map<int, String> generated) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potwierdź generowanie IPN'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: targets.map((p) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(
                      generated[p.id] ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zatwierdź i zapisz'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generator IPN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież listę',
            onPressed: _loading ? null : _loadParts,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _partsWithoutIpn.isEmpty
              ? Center(child: Text(_message.isNotEmpty ? _message : 'Brak części bez IPN'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'Części bez IPN: ${_partsWithoutIpn.length}  •  Zaznaczono: ${_selected.length}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() {
                              if (_selected.length == _partsWithoutIpn.length) {
                                _selected = {};
                              } else {
                                _selected = _partsWithoutIpn.map((p) => p.id).toSet();
                              }
                            }),
                            child: Text(
                              _selected.length == _partsWithoutIpn.length
                                  ? 'Odznacz wszystkie'
                                  : 'Zaznacz wszystkie',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _partsWithoutIpn.length,
                        itemBuilder: (ctx, i) {
                          final p = _partsWithoutIpn[i];
                          final isSelected = _selected.contains(p.id);
                          final savedIpn = _generated[p.id];
                          final saveError = _saveResults[p.id];
                          final wasSaved = _saveResults.containsKey(p.id) && saveError == null;

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(p.id);
                              } else {
                                _selected.remove(p.id);
                              }
                            }),
                            title: Text(p.name),
                            subtitle: Text(
                              savedIpn != null
                                  ? wasSaved
                                      ? '✅ IPN: $savedIpn'
                                      : '❌ $saveError'
                                  : 'ID: ${p.id}',
                              style: TextStyle(
                                color: wasSaved
                                    ? Colors.green
                                    : saveError != null
                                        ? Colors.red
                                        : null,
                              ),
                            ),
                            secondary: Icon(
                              Icons.label_off,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_fix_high),
                          label: Text(
                            _selected.isEmpty
                                ? 'Zaznacz części aby generować IPN'
                                : 'Generuj IPN dla ${_selected.length} części',
                          ),
                          onPressed: (_selected.isEmpty || _saving) ? null : _onGeneratePressed,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
