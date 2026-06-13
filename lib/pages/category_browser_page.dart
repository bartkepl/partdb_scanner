import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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

    void sortNodes(List<_CategoryNode> nodes) {
      nodes.sort((a, b) => a.category.name.compareTo(b.category.name));
      for (final n in nodes) { sortNodes(n.children); }
    }
    sortNodes(roots);

    return roots;
  }

  Set<int> _collectIds(_CategoryNode node) {
    final ids = <int>{node.category.id};
    for (final child in node.children) {
      ids.addAll(_collectIds(child));
    }
    return ids;
  }

  void _openParts(_CategoryNode node) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryPartsPage(
          apiService: widget.apiService,
          categoryTitle: node.category.name,
          categoryIds: _collectIds(node),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(l10n.errorText(_error)))
              : _roots.isEmpty
                  ? Center(child: Text(l10n.noCategories))
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
  final void Function(_CategoryNode) onOpenParts;
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
            Expanded(
              child: InkWell(
                onTap: () => onOpenParts(node),
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

class _CategoryPartsPage extends StatefulWidget {
  final ApiService apiService;
  final String categoryTitle;
  final Set<int> categoryIds;
  const _CategoryPartsPage({required this.apiService, required this.categoryTitle, required this.categoryIds});

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
          .where((p) => widget.categoryIds.contains(p.categoryId))
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(l10n.errorText(_error)))
              : _parts.isEmpty
                  ? Center(child: Text(l10n.noPartsInCategory))
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
                            'Stock: ${p.totalStock}',
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
