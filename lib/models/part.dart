class PartLot {
  final int id;
  final String locationName;
  double amount;

  PartLot({
    required this.id,
    required this.locationName,
    required this.amount,
  });

  factory PartLot.fromJson(Map<String, dynamic> json) {
    final loc = json['storage_location'] ?? {};
    return PartLot(
      id: json['id'] ?? 0,
      locationName: loc['name']?.toString() ?? 'Brak',
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
  final List<PartLot> partLots;
  final List<PartParameter> parameters;

  Part({
    required this.id,
    required this.name,
    required this.partNumber,
    required this.unit,
    this.minAmount = 0,
    required this.partLots,
    required this.parameters,
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
      partLots: lots,
      parameters: params,
    );
  }
}
