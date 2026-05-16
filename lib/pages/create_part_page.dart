import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/vendor_barcode_parser.dart';
import 'part_detail_page.dart';

class CreatePartPage extends StatefulWidget {
  final ApiService apiService;
  final VendorBarcode? prefill;

  const CreatePartPage({required this.apiService, this.prefill, super.key});

  @override
  State<CreatePartPage> createState() => _CreatePartPageState();
}

class _CreatePartPageState extends State<CreatePartPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ipnCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<PartCategory> _categories = [];
  List<StorageLocation> _locations = [];
  PartCategory? _selectedCategory;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _nameCtrl.text = p.description.isNotEmpty ? p.description : p.partNo;
      if (p.description.isNotEmpty) _descCtrl.text = '${p.vendor}: ${p.partNo}';
    }
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipnCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.apiService.fetchCategories().catchError((_) => <PartCategory>[]),
        widget.apiService.fetchStorageLocations().catchError((_) => <StorageLocation>[]),
      ]);
      setState(() {
        _categories = results[0] as List<PartCategory>;
        _locations = results[1] as List<StorageLocation>;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final part = await widget.apiService.createPart(
        name: _nameCtrl.text.trim(),
        ipn: _ipnCtrl.text.trim().isEmpty ? null : _ipnCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        categoryIri: _selectedCategory?.iri,
      );

      if (!mounted) return;

      // Krok 2: opcjonalne dodanie stanu magazynowego
      if (_locations.isNotEmpty) {
        await _showAddLotDialog(part.id);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PartDetailPage(part: part, apiService: widget.apiService),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddLotDialog(int partId) async {
    StorageLocation? selectedLocation = _locations.first;
    final qtyCtrl = TextEditingController(text: '0');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Dodaj stan magazynowy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<StorageLocation>(
                initialValue: selectedLocation,
                decoration: const InputDecoration(labelText: 'Lokalizacja'),
                items: _locations
                    .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                    .toList(),
                onChanged: (v) => setDialog(() => selectedLocation = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Ilość'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Pomiń'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (selectedLocation == null) {
                  Navigator.pop(ctx);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await widget.apiService.createPartLot(
                    partId: partId,
                    storageLocationIri: selectedLocation!.iri,
                    amount: qty,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Dodano ${qty.toInt()} szt. w ${selectedLocation!.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Błąd lotu: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
    qtyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowa część')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nazwa *',
                        hintText: 'np. 100nF X7R 0402',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nazwa jest wymagana' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ipnCtrl,
                      decoration: const InputDecoration(
                        labelText: 'IPN (opcjonalnie)',
                        hintText: 'np. 1234567',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Opis (opcjonalnie)',
                        hintText: 'np. LCSC: C14663, 100nF 50V X7R',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PartCategory>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategoria (opcjonalnie)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— brak —')),
                        ..._categories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                    if (_locations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Po utworzeniu zostaniesz zapytany o stan magazynowy.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Utwórz część'),
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
