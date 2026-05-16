import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import 'part_detail_page.dart';
import 'barcode_scan_page.dart';

class SearchPage extends StatefulWidget {
  final ApiService apiService;
  const SearchPage({required this.apiService, super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Part> _results = [];
  List<HistoryEntry> _history = [];
  bool _loading = false;
  String _message = '';
  String _searchType = 'auto';
  bool _showOnlyLowStock = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await HistoryService.load();
    setState(() => _history = h);
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _results = [];
      _message = '🔎 Szukam...';
    });

    try {
      List<Part> found = [];

      if (_searchType == 'ipn') {
        found.add(await widget.apiService.findPartByIPN(query));
      } else if (_searchType == 'name') {
        found = await widget.apiService.searchPartsAdvanced(
          query,
          searchInParams: false,
          searchInValues: false,
        );
      } else if (_searchType == 'param') {
        found = await widget.apiService.searchPartsAdvanced(
          query,
          searchInParams: true,
          searchInValues: false,
        );
      } else if (_searchType == 'value') {
        found = await widget.apiService.searchPartsAdvanced(
          query,
          searchInParams: false,
          searchInValues: true,
        );
      } else {
        found = await widget.apiService.searchPartsAdvanced(query);
      }

      setState(() {
        _results = found;
        _message = found.isEmpty
            ? 'Brak wyników dla "$query"'
            : 'Znaleziono: ${found.length}';
      });
    } catch (e) {
      setState(() => _message = '❌ Błąd: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScanPage(apiService: widget.apiService),
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() => _searchController.text = result);

    // Próbuj szybki bottom sheet dla IPN — jeśli nie, zwykłe wyszukiwanie
    if (RegExp(r'^\d{7}$').hasMatch(result)) {
      setState(() => _loading = true);
      try {
        final part = await widget.apiService.findPartByIPN(result);
        if (!mounted) return;
        await _showQuickAdjust(part);
        _loadHistory();
      } catch (_) {
        _search();
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      _search();
    }
  }

  Future<void> _showQuickAdjust(Part part) async {
    if (part.partLots.isEmpty) {
      _openPart(part);
      return;
    }

    // Dla jednego lotu — bezpośrednio bottom sheet; wiele lotów — pełny widok
    if (part.partLots.length > 1) {
      _openPart(part);
      return;
    }

    final lot = part.partLots.first;
    int current = lot.amount.toInt();

    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(part.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('IPN: ${part.partNumber} • ${lot.locationName}',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          if (current > 0) setSheetState(() => current--);
                        },
                      ),
                      const SizedBox(width: 16),
                      Text('$current',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => setSheetState(() => current++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Anuluj'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            try {
                              await widget.apiService.patchPartLot(lot.id, current.toDouble());
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ ${part.name}: $current szt.'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Błąd: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text('Zapisz'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openPart(part);
                        },
                        child: const Text('Więcej...'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openPart(Part p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartDetailPage(part: p, apiService: widget.apiService),
      ),
    ).then((_) => _loadHistory());
  }

  void _openFromHistory(HistoryEntry entry) async {
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final part = await widget.apiService.findPartByIPN(entry.ipn);
      if (!mounted) return;
      _openPart(part);
    } catch (e) {
      setState(() => _message = '❌ Błąd: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHistory = _results.isEmpty && !_loading && _searchController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyszukaj część'),
        actions: [
          if (_results.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.warning_amber,
                color: _showOnlyLowStock ? Colors.orange : Colors.white54,
              ),
              tooltip: 'Tylko niski stan',
              onPressed: () => setState(() => _showOnlyLowStock = !_showOnlyLowStock),
            ),
          PopupMenuButton<String>(
            initialValue: _searchType,
            onSelected: (v) => setState(() => _searchType = v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'auto', child: Text('Auto')),
              PopupMenuItem(value: 'ipn', child: Text('Tylko IPN')),
              PopupMenuItem(value: 'name', child: Text('Tylko nazwa')),
              PopupMenuItem(value: 'param', child: Text('Po parametrach')),
              PopupMenuItem(value: 'value', child: Text('Po wartościach')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Wpisz fragment IPN, nazwy, parametru...',
              ),
              onChanged: (v) {
                if (v.isEmpty) setState(() => _results = []);
              },
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Szukaj'),
                    onPressed: _search,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Skanuj'),
                    onPressed: _scanBarcode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: showHistory
                  ? _buildHistory()
                  : _results.isEmpty
                      ? Center(child: Text(_message))
                      : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return const Center(child: Text('Wyszukaj lub zeskanuj część'));
    }
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Ostatnio oglądane',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        ..._history.map(
          (e) => ListTile(
            leading: const Icon(Icons.history, color: Colors.orange),
            title: Text(e.name),
            subtitle: Text('IPN: ${e.ipn}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openFromHistory(e),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final displayed = _showOnlyLowStock
        ? _results.where((p) => p.isLowStock).toList()
        : _results;

    if (displayed.isEmpty) {
      return const Center(child: Text('Brak części z niskim stanem'));
    }

    return ListView.builder(
      itemCount: displayed.length,
      itemBuilder: (ctx, i) {
        final p = displayed[i];
        return ListTile(
          leading: Icon(
            Icons.memory,
            color: p.isLowStock ? Colors.red : Colors.orange,
          ),
          title: Text(p.name),
          subtitle: Text('IPN: ${p.partNumber} • Stan: ${p.totalStock}'),
          trailing: p.isLowStock
              ? const Icon(Icons.warning_amber, color: Colors.red, size: 18)
              : const Icon(Icons.chevron_right),
          onTap: () => _openPart(p),
        );
      },
    );
  }
}
