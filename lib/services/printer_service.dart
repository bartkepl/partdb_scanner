import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import './printer_controller.dart';
import '../models/part.dart';

class PrinterService {
  static final SunmiPrinterPlus _sunmiPrinter = SunmiPrinterPlus();

  static final PrinterController _controller =
  PrinterController(printer: _sunmiPrinter);

  static Future<void> printPart(Part part) async {
    try {
      /// NAZWA
      await _controller.printText(
        part.name,
        style: SunmiTextStyle(
          bold: true,
          align: SunmiPrintAlign.CENTER,
          fontSize: 40,
        ),
      );

      await _controller.lineWrap(1);

      /// IPN
      await _controller.printText(
        "ID: ${part.id}",
        style: SunmiTextStyle(bold: true),
      );
      await _controller.printText(
        "IPN: ${part.partNumber}",
        style: SunmiTextStyle(bold: true),
      );
      if (part.unit.isNotEmpty) {
        await _controller.printText("Jednostka: ${part.unit}");
      }

      await _controller.line();

      /// PARAMETRY
      if (part.parameters.isNotEmpty) {
        await _controller.printText(
          "Parametry:",
          style: SunmiTextStyle(bold: true),
        );

        for (var p in part.parameters) {
          if (p.value.isEmpty || p.value == '0') continue;

          await _controller.printRow(
            cols: [
              SunmiColumn(text: p.name, width: 18),
              SunmiColumn(text: p.value, width: 12),
            ],
          );
        }

        await _controller.line();
      }

      /// LOKALIZACJE
      await _controller.printText(
        "Lokalizacje:",
        style: SunmiTextStyle(bold: true),
      );

      for (var lot in part.partLots) {
        await _controller.printRow(
          cols: [
            SunmiColumn(text: lot.locationName, width: 24),
            SunmiColumn(text: lot.amount.toInt().toString(), width: 6),
          ],
        );
      }

      await _controller.lineWrap(2);

      /// kod kreskowy IPN
      await _controller.printQRCode(
        part.partNumber,
          style: SunmiQrcodeStyle(
            align: SunmiPrintAlign.CENTER,
            errorLevel: SunmiQrcodeLevel.LEVEL_H,
            qrcodeSize: 7,
          ),
      );

      await _controller.lineWrap(3);
      await _controller.cutPaper();
    } catch (e) {
      throw Exception("Błąd drukowania: $e");
    }
  }
}