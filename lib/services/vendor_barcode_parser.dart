import 'dart:convert';

class VendorBarcode {
  final String vendor;
  final String partNo;
  final int qty;
  final String description;
  final String manufacturer;
  final String package;

  const VendorBarcode({
    required this.vendor,
    required this.partNo,
    this.qty = 0,
    this.description = '',
    this.manufacturer = '',
    this.package = '',
  });

  @override
  String toString() =>
      '$vendor: $partNo${qty > 0 ? ' ($qty szt.)' : ''}${description.isNotEmpty ? ' — $description' : ''}';
}

class VendorBarcodeParser {
  /// Próbuje rozpoznać kod dostawcy. Zwraca null jeśli to zwykły IPN/tekst.
  static VendorBarcode? parse(String raw) {
    return _parseLCSC(raw) ?? _parseTME(raw);
  }

  // ─── LCSC ────────────────────────────────────────────────────────────────
  // Formaty LCSC/JLCPCB:
  //   JSON: {"PN":"C14663","PM":"100nF X7R 0402","qty":10,"Cust":...}
  //   CSV:  C14663,10,100nF,0402,...
  //   Stary: {C14663}{10}{...}
  static VendorBarcode? _parseLCSC(String raw) {
    final trimmed = raw.trim();

    // Format JSON
    if (trimmed.startsWith('{')) {
      try {
        final m = json.decode(trimmed) as Map<String, dynamic>;
        final partNo = (m['PN'] ?? m['pn'] ?? '').toString().trim();
        if (partNo.isEmpty || !_isLcscPart(partNo)) return null;
        return VendorBarcode(
          vendor: 'LCSC',
          partNo: partNo,
          qty: _parseInt(m['qty'] ?? m['Qty'] ?? m['QTY'] ?? 0),
          description: (m['PM'] ?? m['pm'] ?? m['description'] ?? '').toString().trim(),
          manufacturer: (m['mfr'] ?? m['Mfr'] ?? m['manufacturer'] ?? '').toString().trim(),
          package: (m['package'] ?? m['Package'] ?? '').toString().trim(),
        );
      } catch (_) {
        // nie JSON
      }
    }

    // Format CSV: C14663,100,opis,...
    final csvParts = trimmed.split(',');
    if (csvParts.length >= 2 && _isLcscPart(csvParts[0].trim())) {
      return VendorBarcode(
        vendor: 'LCSC',
        partNo: csvParts[0].trim(),
        qty: _parseInt(csvParts.length > 1 ? csvParts[1] : '0'),
        description: csvParts.length > 2 ? csvParts.sublist(2).join(' ').trim() : '',
      );
    }

    // Bare LCSC part number (C + 4-8 cyfr)
    if (_isLcscPart(trimmed)) {
      return VendorBarcode(vendor: 'LCSC', partNo: trimmed);
    }

    return null;
  }

  static bool _isLcscPart(String s) =>
      RegExp(r'^C\d{4,8}$', caseSensitive: false).hasMatch(s.trim());

  // ─── TME ─────────────────────────────────────────────────────────────────
  // Znane formaty TME:
  //   Tilde-separated: {orderId}~{pos}~{symbol}~{qty}
  //   Lub: TME~{symbol}~{qty}~...
  //   URL: https://www.tme.eu/...
  static VendorBarcode? _parseTME(String raw) {
    final trimmed = raw.trim();

    // URL TME
    if (trimmed.startsWith('https://www.tme.eu') ||
        trimmed.startsWith('http://www.tme.eu')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final segments = uri.pathSegments;
        final symbol = segments.isNotEmpty ? segments.last : '';
        return VendorBarcode(
          vendor: 'TME',
          partNo: symbol,
          description: 'TME URL',
        );
      }
    }

    // Tilde-separated
    if (trimmed.contains('~')) {
      final parts = trimmed.split('~');
      // Format: orderId~lineNo~symbol~qty  lub  TME~symbol~qty
      if (parts.length >= 3) {
        // Jeśli pierwszy segment to "TME": TME~symbol~qty
        if (parts[0].toUpperCase() == 'TME') {
          return VendorBarcode(
            vendor: 'TME',
            partNo: parts[1].trim(),
            qty: _parseInt(parts.length > 2 ? parts[2] : '0'),
          );
        }
        // Ogólny: orderId~pos~symbol~qty
        final symbol = parts[2].trim();
        final qty = parts.length > 3 ? _parseInt(parts[3]) : 0;
        if (symbol.isNotEmpty) {
          return VendorBarcode(
            vendor: 'TME',
            partNo: symbol,
            qty: qty,
            description: 'Zam. ${parts[0]}',
          );
        }
      }
    }

    // Pipe-separated (alternatywny format TME)
    if (trimmed.contains('|') && trimmed.toUpperCase().contains('TME')) {
      final parts = trimmed.split('|');
      final symbol = parts.firstWhere((p) => !p.toUpperCase().contains('TME') && p.isNotEmpty, orElse: () => '');
      if (symbol.isNotEmpty) {
        return VendorBarcode(vendor: 'TME', partNo: symbol);
      }
    }

    return null;
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }
}
