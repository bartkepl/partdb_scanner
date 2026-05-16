import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:niim_blue_flutter/niim_blue_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/part.dart';

/// Parametr do drukowania na etykiecie szpulki.
/// [name] – nazwa wyświetlana, [value] – treść edytowana przez użytkownika,
/// [bold] – czy tekst pogrubiony.
typedef PrintParam = ({String name, String value, bool bold});

/// Serwis drukowania etykiet na Niimbot D101 (203 DPI, BT).
///
/// Wymiary etykiet (203 DPI → 1mm ≈ 8px):
///   22×14mm szufladka  → landscape: PrintPage(112, 176) obrócone 90° CCW
///                         → fizyczna 176×112 px = 22mm×14mm, treść z rotate:90
///   12×40mm szpulka    → portrait:  PrintPage(96, 320)
///   12×40mm kod 1D     → landscape: PrintPage(96, 320) obrócone 90° CCW
///                         → fizyczna 320×96 px = 40mm×12mm
class NiimbotService {
  NiimbotService._();
  static final NiimbotService instance = NiimbotService._();

  final _client = NiimbotBluetoothClient();
  bool _connected = false;

  // Drawer 22×14mm – printhead = 14mm (112px), feed = 22mm (176px), landscape
  static const _drawerPH = 112; // printhead width = 14mm
  static const _drawerFD = 176; // feed direction  = 22mm

  // Spool 12×40mm – printhead = 12mm (96px), feed = 40mm (320px)
  static const _spoolW = 96;
  static const _spoolH = 320;

  bool get isConnected => _connected;

  // ─── Bluetooth ──────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> connect() async {
    if (_connected) return;
    await _requestPermissions();
    await _client.connect();
    _client.stopHeartbeat();
    _client.setPacketInterval(0);
    _connected = true;
  }

  Future<void> disconnect() async {
    if (!_connected) return;
    _client.startHeartbeat();
    await _client.disconnect();
    _connected = false;
  }

  // ─── Generowanie DataMatrix jako PNG ────────────────────────────────────

  /// Generuje kod DataMatrix jako PNG [Uint8List] o wymiarach [size]×[size] px.
  ///
  /// Używa biblioteki `barcode` do wygenerowania elementów i `dart:ui`
  /// do renderowania na bitmapie monochromatycznej.
  static Future<Uint8List> generateDataMatrix(String data, {int size = 100}) async {
    final bc = Barcode.dataMatrix();
    final double s = size.toDouble();

    final elements = bc.make(data, width: s, height: s, drawText: false);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Białe tło
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, s, s),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );

    // Czarne moduły DataMatrix
    final black = ui.Paint()..color = const ui.Color(0xFF000000);
    for (final el in elements) {
      if (el is BarcodeBar && el.black) {
        canvas.drawRect(
          ui.Rect.fromLTWH(el.left, el.top, el.width, el.height),
          black,
        );
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  // ─── Drukowanie ─────────────────────────────────────────────────────────

  Future<void> _executePrint(PrintPage page) async {
    final task = _client.createPrintTask(
      PrintOptions(totalPages: 1, density: 3, labelType: LabelType.withGaps),
    );
    if (task == null) throw Exception('Nie wykryto modelu drukarki Niimbot');
    await task.printInit();
    await task.printPage(page.toEncodedImage(), 1);
    await task.waitForFinished();
  }

  // ─── Etykieta szufladkowa 22×14mm (landscape) ───────────────────────────

  /// Drukuje etykietę szufladkową 22×14mm w orientacji landscape:
  ///   [lewa strona] nazwa części
  ///   [prawa strona] kod DataMatrix z IPN
  ///
  /// Układ współrzędnych landscape (PrintPage 112×176, obrót 90° CCW):
  ///   Fizyczna lewo  = internal y mała (top internal)
  ///   Fizyczna prawo = internal y duża (bottom internal)
  ///   Fizyczne środek wysokości (7mm) = internal x ≈ 55
  ///   Wszystkie elementy rotate:90 aby tekst był poziomy na fizycznej etykiecie.
  Future<void> printDrawerLabel(Part part, {int fontSize = 18}) async {
    final page = PrintPage(_drawerPH, _drawerFD, PageOrientation.landscape);

    await page.addText(
      part.name,
      TextOptions(
        x: _drawerFD ~/ 2,
        y: 6,
        width: _drawerFD - 24,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        align: HAlignment.center,
        vAlign: VAlignment.top,
        rotate: 0,
      ),
    );

    // DataMatrix przy dolnej krawędzi canvas (large y = prawa strona po rotacji)
    final dm = await generateDataMatrix(part.partNumber, size: 72);
    page.addImageFromBuffer(ImageFromBufferOptions(
      buffer: dm,
      x: _drawerFD ~/ 2, // 56 – środek
      y: _drawerPH - 8,   // 170 – 6px od dołu canvas
      width: 72,
      height: 72,
      align: HAlignment.center,
      vAlign: VAlignment.bottom,
      threshold: 128,
      rotate: 0,
    ));

    await _executePrint(page);
  }

  // ─── Etykieta szpulki 12×40mm – parametry + DataMatrix ──────────────────

  /// Drukuje etykietę szpulki 12×40mm (portrait).
  ///
  /// [params] – lista (name, value) w żądanej kolejności z wartościami
  /// edytowanymi przez użytkownika (nie zapisywanymi do bazy danych).
  /// Na dole zawsze kod DataMatrix z IPN.
  Future<void> printSpoolParamLabel(Part part, List<PrintParam> params) async {
    final page = await _buildParamPage(part, params);
    await _executePrint(page);
  }

  // ─── Etykieta szpulki 12×40mm – kod 1D ──────────────────────────────────

  /// Drukuje etykietę szpulki w orientacji landscape (fizycznie 40×12mm):
  ///   kod Code128 z IPN rozciągnięty wzdłuż 40mm.
  Future<void> printSpoolBarcodeLabel(Part part) async {
    final page = _buildBarcodePage(part);
    await _executePrint(page);
  }

  // ─── Obie etykiety szpulki naraz ────────────────────────────────────────

  Future<void> printSpoolLabels(Part part, List<PrintParam> params) async {
    await _executePrint(await _buildParamPage(part, params));
    await _executePrint(_buildBarcodePage(part));
  }

  // ─── Budowanie stron ─────────────────────────────────────────────────────

  Future<PrintPage> _buildParamPage(Part part, List<PrintParam> params) async {
    const qrSize = 76;
    const qrY = _spoolH - 12;
    const usableH = _spoolH - qrSize - 10;

    final page = PrintPage(_spoolW, _spoolH, PageOrientation.portrait);

    final fontSize = params.length <= 5 ? 22 : 18;
    final lineH = (fontSize * 1.35).round();

    int y = 12;
    for (final param in params) {
      if (y + lineH > usableH) break;
      await page.addText(
        param.value,
        TextOptions(
          x: _spoolW ~/ 2,
          y: y,
          width: _spoolW - 4,
          fontSize: fontSize,
          fontWeight: param.bold ? FontWeight.bold : FontWeight.normal,
          align: HAlignment.center,
          vAlign: VAlignment.top,
        ),
      );
      y += lineH;
    }

    // DataMatrix z IPN na dole
    final dm = await generateDataMatrix(part.partNumber, size: qrSize);
    page.addImageFromBuffer(ImageFromBufferOptions(
      buffer: dm,
      x: _spoolW ~/ 2,
      y: qrY,
      width: qrSize,
      height: qrSize,
      align: HAlignment.center,
      vAlign: VAlignment.bottom,
      threshold: 128,
    ));

    return page;
  }

  PrintPage _buildBarcodePage(Part part) {
    // landscape: 96×320 internal → obrót 90° CCW → fizyczna 320×96 = 40mm×12mm
    final page = PrintPage(_spoolW, _spoolH, PageOrientation.landscape);

    page.addBarcode(
      part.partNumber,
      BarcodeOptions(
        x: _spoolH ~/ 2, // środek 320px (długość) → środek 40mm fizycznego
        y: _spoolW ~/ 2, // środek 96px (szerokość) → środek 12mm fizycznego
        width: 280,
        height: 72,
        align: HAlignment.center,
        vAlign: VAlignment.middle,
        encoding: BarcodeEncoding.code128,
        rotate: 0,
      ),
    );

    return page;
  }
}
