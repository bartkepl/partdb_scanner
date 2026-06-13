import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/part.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/export_service.dart';
import 'part_detail_page.dart';
import 'barcode_scan_page.dart';
import 'stock_taking_page.dart';

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
  String _sortBy = 'none';
  String _filterCategory = '';

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
    final l10n = AppLocalizations.of(context)!;
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _results = [];
      _message = l10n.searching;
    });

    try {
      List<Part> found = [];

      if (_searchType == 'ipn') {
        found.add(await widget.apiService.findPartByIPN(query));
      } else if (_searchType == 'name') {
        found = await widget.apiService.searchByName(query);
        if (found.isEmpty && query.length >= 2) {
          found = await widget.apiService.searchPartsAdvanced(
            query,
            searchInParams: false,
            searchInValues: false,
          );
        }
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
        found = await widget.apiService.searchByName(query);
        if (found.isEmpty) {
          found = await widget.apiService.searchPartsAdvanced(query);
        }
      }

      setState(() {
        _results = found;
        _message = found.isEmpty
            ? l10n.searchNoResults(query)
            : l10n.searchFound(found.length);
      });
    } catch (e) {
      setState(() => _message = l10n.errorGeneric(e.toString()));
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

    if (part.partLots.length > 1) {
      _openPart(part);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final lot = part.partLots.first;
    int current = lot.amount.toInt();
    final commentController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: l10n.commentOptional,
                      hintText: l10n.commentHint,
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final comment = commentController.text.trim();
                            Navigator.pop(ctx);
                            try {
                              await widget.apiService.patchPartLot(
                                lot.id,
                                current.toDouble(),
                                comment: comment.isEmpty ? null : comment,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.savedQty(part.name, current)),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.errorGeneric(e.toString())),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text(l10n.save),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openPart(part);
                        },
                        child: Text(l10n.more),
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
    commentController.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final part = await widget.apiService.findPartByIPN(entry.ipn);
      if (!mounted) return;
      _openPart(part);
    } catch (e) {
      setState(() => _message = l10n.errorGeneric(e.toString()));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showHistory = _results.isEmpty && !_loading && _searchController.text.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTitle),
        actions: [
          if (_results.isNotEmpty) ...[
            IconButton(
              icon: Icon(
                Icons.warning_amber,
                color: _showOnlyLowStock ? Colors.orange : Colors.white54,
              ),
              tooltip: l10n.searchOnlyLowStock,
              onPressed: () => setState(() => _showOnlyLowStock = !_showOnlyLowStock),
            ),
            IconButton(
              icon: Icon(
                Icons.sort,
                color: _sortBy != 'none' || _filterCategory.isNotEmpty
                    ? Colors.orange
                    : Colors.white,
              ),
              tooltip: l10n.searchSortFilter,
              onPressed: _showSortFilter,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: l10n.searchExportCsv,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ExportService.exportAndShare(_results);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.searchExportError(e.toString())), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: l10n.searchInventory,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockTakingPage(apiService: widget.apiService),
              ),
            ),
          ),
          PopupMenuButton<String>(
            initialValue: _searchType,
            onSelected: (v) => setState(() => _searchType = v),
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'auto', child: Text(l10n.filterAll)),
              const PopupMenuItem(value: 'ipn', child: Text('IPN')),
              const PopupMenuItem(value: 'name', child: Text('Name')),
              const PopupMenuItem(value: 'param', child: Text('Parameter')),
              const PopupMenuItem(value: 'value', child: Text('Value')),
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
              decoration: InputDecoration(
                labelText: l10n.searchHint,
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
                    label: Text(l10n.search),
                    onPressed: _search,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(l10n.scan),
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
    final l10n = AppLocalizations.of(context)!;
    if (_history.isEmpty) {
      return Center(child: Text(l10n.searchOrScan));
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l10n.recentlyViewed,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
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

  Future<void> _showSortFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final categories = _results.map((p) => p.category).where((c) => c.isNotEmpty).toSet().toList()..sort();

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sortSectionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: [
                  for (final opt in [
                    ('none', l10n.sortNone),
                    ('name_asc', l10n.sortNameAsc),
                    ('name_desc', l10n.sortNameDesc),
                    ('stock_asc', l10n.sortStockAsc),
                    ('stock_desc', l10n.sortStockDesc),
                  ])
                    ChoiceChip(
                      label: Text(opt.$2),
                      selected: _sortBy == opt.$1,
                      onSelected: (_) => setState(() { _sortBy = opt.$1; setSheet(() {}); }),
                    ),
                ],
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l10n.categoryLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.filterAll),
                      selected: _filterCategory.isEmpty,
                      onSelected: (_) => setState(() { _filterCategory = ''; setSheet(() {}); }),
                    ),
                    for (final cat in categories)
                      ChoiceChip(
                        label: Text(cat),
                        selected: _filterCategory == cat,
                        onSelected: (_) => setState(() { _filterCategory = cat; setSheet(() {}); }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() { _sortBy = 'none'; _filterCategory = ''; });
                  Navigator.pop(ctx);
                },
                child: Text(l10n.resetFilters),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final l10n = AppLocalizations.of(context)!;
    var displayed = _showOnlyLowStock
        ? _results.where((p) => p.isLowStock).toList()
        : List<Part>.from(_results);

    if (_filterCategory.isNotEmpty) {
      displayed = displayed.where((p) => p.category == _filterCategory).toList();
    }

    switch (_sortBy) {
      case 'name_asc':
        displayed.sort((a, b) => a.name.compareTo(b.name));
      case 'name_desc':
        displayed.sort((a, b) => b.name.compareTo(a.name));
      case 'stock_asc':
        displayed.sort((a, b) => a.totalStock.compareTo(b.totalStock));
      case 'stock_desc':
        displayed.sort((a, b) => b.totalStock.compareTo(a.totalStock));
    }

    if (displayed.isEmpty) {
      return Center(child: Text(l10n.noLowStockParts));
    }

    return ListView.builder(
      itemCount: displayed.length,
      itemBuilder: (ctx, i) {
        final p = displayed[i];
        final sub = [
          if (p.partNumber.isNotEmpty) 'IPN: ${p.partNumber}',
          'Stock: ${p.totalStock}',
          if (p.category.isNotEmpty) p.category,
          if (p.manufacturer.isNotEmpty) p.manufacturer,
        ].join(' • ');
        return ListTile(
          leading: Icon(
            Icons.memory,
            color: p.isLowStock ? Colors.red : Colors.orange,
          ),
          title: Text(p.name),
          subtitle: Text(sub),
          trailing: p.isLowStock
              ? const Icon(Icons.warning_amber, color: Colors.red, size: 18)
              : const Icon(Icons.chevron_right),
          onTap: () => _openPart(p),
        );
      },
    );
  }
}
