import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LabelParamEntry {
  String name;
  bool enabled;
  bool bold;

  LabelParamEntry({required this.name, required this.enabled, this.bold = false});

  Map<String, dynamic> toJson() => {'name': name, 'enabled': enabled, 'bold': bold};

  factory LabelParamEntry.fromJson(Map<String, dynamic> j) => LabelParamEntry(
        name: j['name'] as String,
        enabled: j['enabled'] as bool,
        bold: (j['bold'] as bool?) ?? false,
      );
}

class LabelConfig {
  static const _prefsKey = 'niimbot_label_params';

  List<LabelParamEntry> entries;

  LabelConfig({required this.entries});

  List<String> get enabledNames =>
      entries.where((e) => e.enabled).map((e) => e.name).toList();

  static Future<LabelConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return LabelConfig(entries: []);
    final list = json.decode(raw) as List;
    return LabelConfig(
      entries: list
          .map((e) => LabelParamEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, json.encode(entries.map((e) => e.toJson()).toList()));
  }

  static LabelConfig mergeWithParams(LabelConfig saved, List<String> partParamNames) {
    final existing = Map.fromEntries(saved.entries.map((e) => MapEntry(e.name, e)));
    final merged = <LabelParamEntry>[];

    for (final e in saved.entries) {
      if (partParamNames.contains(e.name)) {
        merged.add(LabelParamEntry(name: e.name, enabled: e.enabled, bold: e.bold));
      }
    }
    for (final name in partParamNames) {
      if (!existing.containsKey(name)) {
        merged.add(LabelParamEntry(name: name, enabled: true, bold: false));
      }
    }
    return LabelConfig(entries: merged);
  }
}
