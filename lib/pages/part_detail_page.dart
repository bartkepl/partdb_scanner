import 'package:flutter/material.dart';
import '../models/part.dart';
import '../services/api_service.dart';

class PartDetailPage extends StatefulWidget {
  final Part part;
  final ApiService apiService;
  const PartDetailPage({required this.part, required this.apiService, super.key});

  @override
  State<PartDetailPage> createState() => _PartDetailPageState();
}

class _PartDetailPageState extends State<PartDetailPage> {
  bool _saving = false;
  bool _refreshing = false;
  late Part _part;
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _part = widget.part;
    _initControllers();
    _loadParameters();
  }

  void _initControllers() {
    _controllers.clear();
    for (final lot in _part.partLots) {
      _controllers[lot.id] =
          TextEditingController(text: lot.amount.toInt().toString());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showToast(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => _refreshing = true);

    try {
      final refreshed =
      await widget.apiService.findPartByIPN(_part.partNumber);
      setState(() {
        _part = refreshed;
        _initControllers();
      });

      await _loadParameters();
      _showToast('Dane odświeżone');
    } catch (e) {
      _showToast('Błąd odświeżania: $e', isError: true);
    } finally {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _loadParameters() async {
    try {
      final params =
      await widget.apiService.fetchPartParameters(_part.id);
      setState(() {
        _part.parameters
          ..clear()
          ..addAll(params);
      });
    } catch (e) {
      _showToast('Nie udało się pobrać parametrów', isError: true);
    }
  }

  Future<void> _saveLot(PartLot lot) async {
    setState(() => _saving = true);

    try {
      final controller = _controllers[lot.id];
      final enteredValue =
          int.tryParse(controller?.text.trim() ?? '') ??
              lot.amount.toInt();
      lot.amount = enteredValue.toDouble();

      final updated =
      await widget.apiService.patchPartLot(lot.id, lot.amount);

      setState(() {
        lot.amount = updated.amount;
        controller?.text = lot.amount.toInt().toString();
      });

      _showToast(
          'Zapisano: ${lot.locationName} = ${lot.amount.toInt()}');
    } catch (e) {
      _showToast('Błąd: $e', isError: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _increment(PartLot lot, int delta) {
    final controller = _controllers[lot.id];
    if (controller == null) return;

    final current =
        int.tryParse(controller.text.trim()) ?? lot.amount.toInt();
    final newValue = (current + delta).clamp(0, 999999);
    controller.text = newValue.toString();
    lot.amount = newValue.toDouble();
  }

  List<PartParameter> _sortedParameters(List<PartParameter> params) {
    final priority = {
      'Wartość': 1,
      'Rezystancja': 1,
      'Pojemność': 1,
      'Indukcyjność': 1,
      'Obudowa': 2,
      'Napięcie': 3,
      'Napięcie pracy': 3,
      'Moc': 4,
      'Producent': 5,
    };

    List<PartParameter> sorted = List.from(params);

    sorted.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      final aPriority = priority.keys.firstWhere(
            (k) => aName.contains(k.toLowerCase()),
        orElse: () => '',
      );
      final bPriority = priority.keys.firstWhere(
            (k) => bName.contains(k.toLowerCase()),
        orElse: () => '',
      );

      final aIndex = aPriority.isEmpty ? 999 : priority[aPriority]!;
      final bIndex = bPriority.isEmpty ? 999 : priority[bPriority]!;

      if (aIndex != bIndex) return aIndex.compareTo(bIndex);
      return aName.compareTo(bName);
    });

    for (var p in sorted) {
      if (p.name.toLowerCase().contains('obudowa') ||
          p.name.toLowerCase().contains('case')) {
        p.value = p.value.replaceAllMapped(
          RegExp(r'\b(\d{3})\b'),
              (m) => m.group(1)!.padLeft(4, '0'),
        );
      }
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final part = _part;
    final sortedParams = _sortedParameters(
        part.parameters
            .where((p) => p.value.isNotEmpty && p.value != '0')
            .toList());

    return Scaffold(
      appBar: AppBar(
        title: Text(part.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshing ? null : _refreshData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('IPN: ${part.partNumber}'),
            Text('Jednostka: ${part.unit}'),
            const Divider(),

            ...part.partLots.map((lot) {
              final controller = _controllers[lot.id]!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📦 ${lot.locationName}'),
                      Row(
                        children: [
                          IconButton(
                            icon:
                            const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                setState(() => _increment(lot, -1)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              textAlign: TextAlign.center,
                              keyboardType:
                              TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () =>
                                setState(() => _increment(lot, 1)),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed:
                        _saving ? null : () => _saveLot(lot),
                        child: const Text('Zapisz zmiany'),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Divider(),
            const SizedBox(height: 12),

            const Text('Parametry:',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),

            ...sortedParams.map((param) => Card(
              child: ListTile(
                title: Text(param.name),
                subtitle: TextField(
                  controller: TextEditingController(
                    text: param.value,
                  ),
                  onSubmitted: (v) async {
                    try {
                      await widget.apiService
                          .patchPartParameter(param.id, v);

                      setState(() => param.value = v);

                      _showToast(
                          'Zaktualizowano: ${param.name}');
                    } catch (e) {
                      _showToast(
                          'Błąd zapisu: $e',
                          isError: true);
                    }
                  },
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
