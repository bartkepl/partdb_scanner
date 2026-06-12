class PartLot {
  final int id;
  final String locationName;
  final String locationIri;
  double amount;

  PartLot({
    required this.id,
    required this.locationName,
    required this.locationIri,
    required this.amount,
  });

  factory PartLot.fromJson(Map<String, dynamic> json) {
    final loc = json['storage_location'];
    final locMap = loc is Map ? loc : <String, dynamic>{};
    final locId = locMap['id'];
    final locIdInt = locId is int ? locId : int.tryParse(locId?.toString() ?? '') ?? 0;
    return PartLot(
      id: json['id'] ?? 0,
      locationName: locMap['name']?.toString() ?? 'Brak',
      locationIri: locIdInt != 0 ? '/api/storage_locations/$locIdInt' : '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toPatchJson() => {'amount': amount};
}

class PartParameter {
  final int id;
  final String name;
  String value;
  final String unit;

  PartParameter({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
  });

  factory PartParameter.fromJson(Map<String, dynamic> json) {
    // Obsługa różnych możliwych pól w API Part-DB
    String value = '';

    if (json['value'] != null && json['value'].toString().isNotEmpty) {
      value = json['value'].toString();
    } else if (json['value_text'] != null && json['value_text'].toString().isNotEmpty) {
      value = json['value_text'].toString();
    } else if (json['formatted'] != null && json['formatted'].toString().isNotEmpty) {
      value = json['formatted'].toString();
    } else if (json['value_typical'] != null) {
      value = json['value_typical'].toString();
    } else if (json['value_min'] != null || json['value_max'] != null) {
      final min = json['value_min']?.toString() ?? '';
      final max = json['value_max']?.toString() ?? '';
      value = '$min ... $max'.trim();
    }

    final unit = json['unit'] is Map
        ? (json['unit']['name']?.toString() ?? '')
        : json['unit']?.toString() ?? '';

    return PartParameter(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      value: value,
      unit: unit,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value,
    'unit': unit,
  };
}

class Part {
  final int id;
  final String name;
  final String partNumber;
  final String unit;
  final double minAmount;
  final String description;
  final String comment;
  String category;
  int categoryId;
  String manufacturer;
  final String tags;
  final List<PartLot> partLots;
  final List<PartParameter> parameters;
  final bool needsReview;

  Part({
    required this.id,
    required this.name,
    required this.partNumber,
    required this.unit,
    this.minAmount = 0,
    this.description = '',
    this.comment = '',
    this.category = '',
    this.categoryId = 0,
    this.manufacturer = '',
    this.tags = '',
    required this.partLots,
    required this.parameters,
    this.needsReview = false,
  });

  int get totalStock => partLots.isEmpty
      ? 0
      : partLots.map((l) => l.amount.toInt()).reduce((a, b) => a + b);

  bool get isLowStock => minAmount > 0 && totalStock < minAmount;

  factory Part.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] is int)
        ? json['id']
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;

    final name = json['name']?.toString() ?? '';
    final partNumber =
        json['partNumber']?.toString() ?? json['ipn']?.toString() ?? '';

    final unit = json['unit'] is Map
        ? (json['unit']['name']?.toString() ?? '')
        : json['unit']?.toString() ?? '';

    final minAmount = (json['minAmount'] is num)
        ? (json['minAmount'] as num).toDouble()
        : double.tryParse(json['minAmount']?.toString() ?? '0') ?? 0.0;

    final description = json['description']?.toString() ?? '';
    final comment = json['comment']?.toString() ?? '';
    final tags = json['tags']?.toString() ?? '';

    String category = '';
    int categoryId = 0;
    if (json['category'] is Map) {
      category = json['category']['name']?.toString() ?? '';
      final rawId = json['category']['id'];
      categoryId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;
    } else if (json['category'] is String) {
      final s = json['category'] as String;
      // IRI string like /api/categories/42 — extract id from end
      final match = RegExp(r'/(\d+)$').firstMatch(s);
      if (match != null) {
        categoryId = int.tryParse(match.group(1)!) ?? 0;
      } else if (!s.startsWith('/api/') && !s.startsWith('http')) {
        category = s;
      }
    }

    String manufacturer = '';
    if (json['manufacturer'] is Map) {
      manufacturer = json['manufacturer']['name']?.toString() ?? '';
    } else if (json['manufacturer'] is String) {
      final s = json['manufacturer'] as String;
      if (!s.startsWith('/api/') && !s.startsWith('http')) manufacturer = s;
    } else if (json['manufacturers'] is List && (json['manufacturers'] as List).isNotEmpty) {
      final m = (json['manufacturers'] as List).first;
      if (m is Map) {
        final mfr = m['manufacturer'];
        if (mfr is Map) manufacturer = mfr['name']?.toString() ?? '';
      }
    }

    final List<PartLot> lots = [];
    if (json['partLots'] is List) {
      for (final lot in json['partLots']) {
        lots.add(PartLot.fromJson(lot));
      }
    }

    final List<PartParameter> params = [];
    if (json['parameters'] is List) {
      for (final p in json['parameters']) {
        if (p is Map) {
          final casted = p.map((key, value) => MapEntry(key.toString(), value));
          params.add(PartParameter.fromJson(casted));
        }
      }
    }

    return Part(
      id: id,
      name: name,
      partNumber: partNumber,
      unit: unit,
      minAmount: minAmount,
      description: description,
      comment: comment,
      category: category,
      categoryId: categoryId,
      manufacturer: manufacturer,
      tags: tags,
      partLots: lots,
      parameters: params,
      needsReview: json['needs_review'] as bool? ?? false,
    );
  }
}

class StorageLocation {
  final int id;
  final String name;
  final String fullPath;

  String get iri => '/api/storage_locations/$id';

  StorageLocation({required this.id, required this.name, required this.fullPath});

  factory StorageLocation.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    return StorageLocation(
      id: id,
      name: json['name']?.toString() ?? '',
      fullPath: json['full_path']?.toString() ?? json['name']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) => other is StorageLocation && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => fullPath.isNotEmpty ? fullPath : name;
}
