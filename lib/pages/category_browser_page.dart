import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/api_service.dart';
import 'part_detail_page.dart';

class CategoryBrowserPage extends StatefulWidget {
  final ApiService apiService;
  const CategoryBrowserPage({required this.apiService, super.key});

  @override
  State<CategoryBrowserPage> createState() => _CategoryBrowserPageState();
}

class _CategoryBrowserPageState extends State<CategoryBrowserPage> {
  List<PartCategory> _categories = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final cats = await widget.apiService.fetchCategories();
      cats.sort((a, b) => a.name.compareTo(b.name));
      setState(() => _categories = cats);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Przeglądaj kategorie'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Błąd: $_error'))
              : _categories.isEmpty
                  ? const Center(child: Text('Brak kategorii'))
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (ctx, i) {
                        final cat = _categories[i];
                        return ListTile(
                          leading: const Icon(Icons.folder, color: Colors.orange),
                          title: Text(cat.name),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _CategoryPartsPage(
                                apiService: widget.apiService,
                                category: cat,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _CategoryPartsPage extends StatefulWidget {
  final ApiService apiService;
  final PartCategory category;
  const _CategoryPartsPage({required this.apiService, required this.category});

  @override
  State<_CategoryPartsPage> createState() => _CategoryPartsPageState();
}

class _CategoryPartsPageState extends State<_CategoryPartsPage> {
  List<Part> _parts = [];
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final all = await widget.apiService.fetchAllParts();
      final filtered = all
          .where((p) => p.category == widget.category.name)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      setState(() => _parts = filtered);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Błąd: $_error'))
              : _parts.isEmpty
                  ? const Center(child: Text('Brak części w tej kategorii'))
                  : ListView.builder(
                      itemCount: _parts.length,
                      itemBuilder: (ctx, i) {
                        final p = _parts[i];
                        return ListTile(
                          leading: Icon(
                            Icons.memory,
                            color: p.isLowStock ? Colors.red : Colors.orange,
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            [
                              if (p.partNumber.isNotEmpty) 'IPN: ${p.partNumber}',
                              'Stan: ${p.totalStock}',
                              if (p.manufacturer.isNotEmpty) p.manufacturer,
                            ].join(' • '),
                          ),
                          trailing: p.isLowStock
                              ? const Icon(Icons.warning_amber, color: Colors.red, size: 18)
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PartDetailPage(
                                part: p,
                                apiService: widget.apiService,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
