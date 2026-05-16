import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/part.dart';

class ExportService {
  static Future<void> exportAndShare(List<Part> parts) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,IPN,Nazwa,Stan,Min. stan,Kategoria,Producent,Opis');

    for (final p in parts) {
      buffer.writeln([
        p.id,
        _esc(p.partNumber),
        _esc(p.name),
        p.totalStock,
        p.minAmount.toInt(),
        _esc(p.category),
        _esc(p.manufacturer),
        _esc(p.description),
      ].join(','));
    }

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/partdb_export_$ts.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'PartDB eksport ${parts.length} części',
    );
  }

  static String _esc(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
