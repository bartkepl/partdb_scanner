import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/api_service.dart';
import 'part_detail_page.dart';

class _CategoryNode {
  final PartCategory category;
  final List<_CategoryNode> children = [];
  bool expanded = false;

  _CategoryNode(this.category);
}

class CategoryBrowserPage extends StatefulWidget {
  final ApiService apiService;
  const CategoryBrowserPage({required this.apiService, super.key});

  @override
  State<CategoryBrowserPage> createState() => _CategoryBrowserPageState();
}

class _CategoryBrowserPageState extends State<CategoryBrowserPage> {
  List<_CategoryNode> _roots = [];
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
      setState(() => _roots = _buildTree(cats));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<_CategoryNode> _buildTree(List<PartCategory> cats) {
    final Map<String, _CategoryNode> byIri = {
      for (final c in cats) c.iri: _CategoryNode(c),
    };

    final List<_CategoryNode> roots = [];

    for (final node in byIri.values) {
      final parentIri = node.category.parentIri;
      if (parentIri != null && byIri.containsKey(parentIri)) {
        byIri[parentIri]!.children.add(node);
      } else {
        roots.add(node);
      }
    }

    // Sortuj alfabetycznie na każdym poziomie
    void sortNodes(List<_CategoryNode> nodes) {
      nodes.sort((a, b) => a.category.name.compareTo(b.category.name));
      for (final n in nodes) { sortNodes(n.children); }
    }
    sortNodes(roots);

    return roots;
  }

  void _openParts(PartCategory cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryPartsPage(
          apiService: widget.apiService,
          category: cat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorie'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text('Błąd: $_error'))
              : _roots.isEmpty
                  ? const Center(child: Text('Brak kategorii'))
                  : ListView(
                      children: _roots
                          .map((n) => _CategoryTile(
                                node: n,
                                depth: 0,
                                onOpenParts: _openParts,
                                onToggle: (node) => setState(() => node.expanded = !node.expanded),
                              ))
                          .toList(),
                    ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _CategoryNode node;
  final int depth;
  final void Function(PartCategory) onOpenParts;
  final void Function(_CategoryNode) onToggle;

  const _CategoryTile({
    required this.node,
    required this.depth,
    required this.onOpenParts,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasChildren = node.children.isNotEmpty;
    final indent = depth * 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Przycisk +/- (expand/collapse) — osobny obszar kliknięcia
            SizedBox(
              width: 28 + 12 + indent,
              child: hasChildren
                  ? InkWell(
                      onTap: () => onToggle(node),
                      child: Padding(
                        padding: EdgeInsets.only(left: 12 + indent, top: 10, bottom: 10),
                        child: Icon(
                          node.expanded ? Icons.remove : Icons.add,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                    )
                  : SizedBox(width: 12 + indent + 28),
            ),
            // Nazwa kategorii — osobny obszar kliknięcia, otwiera listę części
            Expanded(
              child: InkWell(
                onTap: () => onOpenParts(node.category),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          node.category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: depth == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.white38),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasChildren && node.expanded)
          ...node.children.map((child) => _CategoryTile(
                node: child,
                depth: depth + 1,
                onOpenParts: onOpenParts,
                onToggle: onToggle,
              )),
        if (depth == 0) const Divider(height: 1, indent: 12),
      ],
    );
  }
}

// ─── Lista części dla wybranej kategorii ─────────────────────────────────────

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
                          subtitle: Text([
                            if (p.partNumber.isNotEmpty) 'IPN: ${p.partNumber}',
                            'Stan: ${p.totalStock}',
                            if (p.manufacturer.isNotEmpty) p.manufacturer,
                          ].join(' • ')),
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
