import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/api_service.dart';
import 'part_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SearchPage extends StatefulWidget {
  final ApiService apiService;
  const SearchPage({required this.apiService, super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Part> _results = [];
  bool _loading = false;
  String _message = '';
  String _searchType = 'auto'; // name/ipn/param/value

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
        found = await widget.apiService.searchPartsAdvanced(query,
            searchInParams: false, searchInValues: false);
      } else if (_searchType == 'param') {
        found = await widget.apiService.searchPartsAdvanced(query,
            searchInParams: true, searchInValues: false);
      } else if (_searchType == 'value') {
        found = await widget.apiService.searchPartsAdvanced(query,
            searchInParams: false, searchInValues: true);
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
      setState(() {
        _message = '❌ Błąd: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyszukaj część'),
        actions: [
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
              decoration: InputDecoration(
                labelText: 'Wpisz fragment IPN, nazwy, parametru...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _results.isEmpty
                  ? Center(child: Text(_message))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final p = _results[i];
                  final stock = p.partLots.isNotEmpty
                      ? p.partLots
                      .map((l) => l.amount.toInt())
                      .reduce((a, b) => a + b)
                      : 0;
                  return ListTile(
                    leading: const Icon(Icons.memory, color: Colors.orange),
                    title: Text(p.name),
                    subtitle: Text('IPN: ${p.partNumber} • Stan: $stock'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final visibleParams = prefs.getStringList('visible_params') ?? [];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartDetailPage(
                            part: p,
                            apiService: widget.apiService,
                          ),
                          settings: RouteSettings(arguments: visibleParams),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
