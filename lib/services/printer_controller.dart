import 'dart:typed_data';

import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

class PrinterController {
  final SunmiPrinterPlus _printer;

  PrinterController({required SunmiPrinterPlus printer}) : _printer = printer;

  Future<String?> printText(String text, {SunmiTextStyle? style}) async {
    return await _printer.printText(text: text, style: style);
  }

  Future<bool?> reconnectPrinter() async {
    return await _printer.rebindPrinter();
  }

  Future<String?> printCustomText({required SunmiText sunmiText}) async {
    return await _printer.printCustomText(sunmiText: sunmiText);
  }

  Future<String?> addText({required List<SunmiText> sunmiTexts}) async {
    return await _printer.addText(sunmiTexts: sunmiTexts);
  }

  Future<String?> printQRCode(String text, {SunmiQrcodeStyle? style}) async {
    return await _printer.printQrcode(text: text, style: style);
  }

  Future<String?> printBarcode(
      {required String text, SunmiBarcodeStyle? style}) async {
    return await _printer.printBarcode(text, style: style);
  }

  Future<String?> line({SunmiPrintLine? style}) async {
    return await _printer.line(type: style?.name);
  }

  Future<String?> lineWrap([int times = 3]) async {
    return await _printer.lineWrap(times: times);
  }

  Future<String?> cutPaper() async {
    return await _printer.cutPaper();
  }

  Future<String?> printImage(
      {required Uint8List image,
        SunmiPrintAlign align = SunmiPrintAlign.LEFT}) async {
    return await _printer.printImage(image, align: align);
  }
  Future<String?> printRow({required List<SunmiColumn> cols}) async {
    return await _printer.printRow(cols: cols);
  }
}
