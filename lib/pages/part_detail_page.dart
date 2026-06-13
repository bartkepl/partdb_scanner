import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/part.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../services/printer_service.dart';
import 'label_print_page.dart';

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
  final Map<int, TextEditingController> _commentControllers = {};
  final Map<int, TextEditingController> _paramControllers = {};

  @override
  void initState() {
    super.initState();
    _part = widget.part;
    _initControllers();
    _loadParameters();
    HistoryService.add(HistoryEntry(
      id: _part.id,
      name: _part.name,
      ipn: _part.partNumber,
    ));
  }

  void _initControllers() {
    final newIds = _part.partLots.map((l) => l.id).toSet();
    for (final id in _controllers.keys.where((id) => !newIds.contains(id)).toList()) {
      _controllers.remove(id)!.dispose();
      _commentControllers.remove(id)?.dispose();
    }
    for (final lot in _part.partLots) {
      _controllers.putIfAbsent(
        lot.id,
        () => TextEditingController(text: lot.amount.toInt().toString()),
      );
      _commentControllers.putIfAbsent(lot.id, () => TextEditingController());
    }
  }

  void _initParamControllers(List<PartParameter> params) {
    final newIds = params.map((p) => p.id).toSet();
    _paramControllers.keys.where((id) => !newIds.contains(id)).toList().forEach((id) {
      _paramControllers.remove(id)!.dispose();
    });
    for (final param in params) {
      _paramControllers.putIfAbsent(
        param.id,
        () => TextEditingController(text: param.value),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    for (final c in _commentControllers.values) { c.dispose(); }
    for (final c in _paramControllers.values) { c.dispose(); }
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

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addPhoto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: Text(l10n.cameraSource),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: Text(l10n.gallerySource),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (source == null) return;

    final xfile = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1920);
    if (xfile == null) return;

    setState(() => _saving = true);
    try {
      final bytes = await xfile.readAsBytes();
      final filename = '${_part.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await widget.apiService.uploadAttachment(_part.id, bytes, filename);
      if (!mounted) return;
      _showToast(l10n.photoAdded);
    } catch (e) {
      if (!mounted) return;
      _showToast(l10n.uploadError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refreshData() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _refreshing = true);

    try {
      final refreshed =
      await widget.apiService.findPartByIPN(_part.partNumber);
      setState(() {
        _part = refreshed;
        _initControllers();
      });

      await _loadParameters();
      if (!mounted) return;
      _showToast(l10n.dataRefreshed);
    } catch (e) {
      if (!mounted) return;
      _showToast(l10n.refreshError(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _loadParameters() async {
    try {
      final details = await widget.apiService.fetchPartParameters(_part.id);
      setState(() {
        _part.parameters
          ..clear()
          ..addAll(details.params);
        _initParamControllers(details.params);
        if (details.category.isNotEmpty) _part.category = details.category;
        if (details.manufacturer.isNotEmpty) _part.manufacturer = details.manufacturer;
      });
    } catch (e) {
      _showToast(AppLocalizations.of(context)!.fetchParamsError, isError: true);
    }
  }

  Future<void> _saveLot(PartLot lot) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);

    try {
      final controller = _controllers[lot.id];
      final commentCtrl = _commentControllers[lot.id];
      final enteredValue =
          int.tryParse(controller?.text.trim() ?? '') ?? lot.amount.toInt();
      lot.amount = enteredValue.toDouble();

      final comment = commentCtrl?.text.trim();
      final updated = await widget.apiService.patchPartLot(
        lot.id,
        lot.amount,
        comment: (comment != null && comment.isNotEmpty) ? comment : null,
      );

      setState(() {
        lot.amount = updated.amount;
        controller?.text = lot.amount.toInt().toString();
        commentCtrl?.clear();
      });

      _showToast(l10n.savedLot(lot.locationName, lot.amount.toInt()));
    } catch (e) {
      _showToast(l10n.errorGeneric(e.toString()), isError: true);
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
    final l10n = AppLocalizations.of(context)!;
    final part = _part;
    final sortedParams = _sortedParameters(
        part.parameters
            .where((p) => p.value.isNotEmpty && p.value != '0')
            .toList());

    return Scaffold(
      appBar: AppBar(
        title: Text(part.name),
        actions: [
          MenuAnchor(
            builder: (BuildContext context, MenuController controller, Widget? child) {
              return IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.refresh),
                onPressed: _refreshing ? null : _refreshData,
                child: Text(l10n.refresh),
              ),
              if (widget.apiService.sunmiEnabled)
                MenuItemButton(
                  leadingIcon: const Icon(Icons.print),
                  onPressed: () async {
                    final loc = AppLocalizations.of(context)!;
                    try {
                      await PrinterService.printPart(_part);
                      if (!mounted) return;
                      _showToast(loc.printed);
                    } catch (e) {
                      if (!mounted) return;
                      _showToast(loc.printError(e.toString()), isError: true);
                    }
                  },
                  child: Text(l10n.printSunmi),
                ),
              if (widget.apiService.niimbotEnabled)
                MenuItemButton(
                  leadingIcon: const Icon(Icons.label_outline),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabelPrintPage(part: _part),
                    ),
                  ),
                  child: Text(l10n.niimbotLabels),
                ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.add_a_photo),
                onPressed: _saving ? null : _addPhoto,
                child: Text(l10n.addPhoto),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('ID: ${part.id}'),
            if (part.partNumber.isNotEmpty) Text('IPN: ${part.partNumber}'),
            if (part.category.isNotEmpty)
              Text(l10n.categoryText(part.category),
                  style: const TextStyle(color: Colors.grey)),
            if (part.manufacturer.isNotEmpty)
              Text(l10n.manufacturerText(part.manufacturer),
                  style: const TextStyle(color: Colors.grey)),
            if (part.tags.isNotEmpty)
              Text(l10n.tagsText(part.tags),
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (part.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(part.description,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (part.comment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(l10n.noteText(part.comment),
                  style: const TextStyle(color: Colors.amber, fontSize: 12)),
            ],
            const Divider(),

            ...part.partLots.map((lot) {
              final controller = _controllers[lot.id]!;
              final commentCtrl = _commentControllers[lot.id]!;
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
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => setState(() => _increment(lot, -1)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _increment(lot, 1)),
                          ),
                        ],
                      ),
                      TextField(
                        controller: commentCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.commentOptional,
                          hintText: l10n.commentHint,
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _saving ? null : () => _saveLot(lot),
                        child: Text(l10n.saveChanges),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Divider(),
            const SizedBox(height: 12),

            Text(l10n.parametersLabel,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),

            ...sortedParams.map((param) {
              final ctrl = _paramControllers[param.id];
              return Card(
                child: ListTile(
                  title: Text(param.name),
                  subtitle: TextField(
                    controller: ctrl,
                    onSubmitted: (v) async {
                      try {
                        await widget.apiService.patchPartParameter(param.id, v);
                        setState(() => param.value = v);
                        _showToast(l10n.paramUpdated(param.name));
                      } catch (e) {
                        _showToast(l10n.saveError(e.toString()), isError: true);
                      }
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
