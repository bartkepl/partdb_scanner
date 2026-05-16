import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final int id;
  final String name;
  final String ipn;

  const HistoryEntry({required this.id, required this.name, required this.ipn});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'ipn': ipn};

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as int,
        name: j['name'] as String,
        ipn: j['ipn'] as String,
      );
}

class HistoryService {
  static const _key = 'part_history';
  static const _maxEntries = 20;

  static Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => HistoryEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> add(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final entries = raw
        .map((s) => HistoryEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .where((e) => e.id != entry.id)
        .toList();
    entries.insert(0, entry);
    if (entries.length > _maxEntries) entries.removeRange(_maxEntries, entries.length);
    await prefs.setStringList(_key, entries.map((e) => json.encode(e.toJson())).toList());
  }
}
