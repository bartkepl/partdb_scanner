import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScanPage extends StatefulWidget {
  final ApiService apiService;
  const BarcodeScanPage({required this.apiService, super.key});

  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

/// 🔀 Typy skanowania
enum ScanType {
  all,
  qr,
  dataMatrix,
  ean13,
  code128,
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  CameraController? _cameraController;
  late BarcodeScanner _scanner;

  bool _processing = false;
  bool _torchOn = false;

  ScanType _scanType = ScanType.all;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scanner = BarcodeScanner(
      formats: _getFormats(),
    );
  }

  /// 🔧 Mapowanie typów
  List<BarcodeFormat> _getFormats() {
    switch (_scanType) {
      case ScanType.qr:
        return [BarcodeFormat.qrCode];
      case ScanType.dataMatrix:
        return [BarcodeFormat.dataMatrix];
      case ScanType.ean13:
        return [BarcodeFormat.ean13];
      case ScanType.code128:
        return [BarcodeFormat.code128];
      case ScanType.all:
        return [
          BarcodeFormat.qrCode,
          BarcodeFormat.dataMatrix,
          BarcodeFormat.ean13,
          BarcodeFormat.code128,
        ];
    }
  }

  bool _is2D() {
    return _scanType == ScanType.qr ||
        _scanType == ScanType.dataMatrix ||
        _scanType == ScanType.all;
  }

  String _getScanTypeLabel() {
    switch (_scanType) {
      case ScanType.qr:
        return "QR Code";
      case ScanType.dataMatrix:
        return "Data Matrix";
      case ScanType.ean13:
        return "EAN-13";
      case ScanType.code128:
        return "Code 128";
      case ScanType.all:
        return "Auto";
    }
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null) return;

    _torchOn = !_torchOn;

    await _cameraController!.setFlashMode(
      _torchOn ? FlashMode.torch : FlashMode.off,
    );

    setState(() {});
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await widget.apiService.loadConfig();
    await controller.initialize();

    final configuredZoom = widget.apiService.zoomLevel;
    final maxZoom = await controller.getMaxZoomLevel();
    final minZoom = await controller.getMinZoomLevel();

    final desiredZoom = configuredZoom.clamp(minZoom, maxZoom);
    await controller.setZoomLevel(desiredZoom);

    setState(() {
      _cameraController = controller;
    });
  }

  /// 🔀 Popup wyboru typu
  Future<void> _selectScanType() async {
    final result = await showDialog<ScanType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Wybierz typ kodu"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ScanType.all),
            child: const Text("Wszystkie"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ScanType.qr),
            child: const Text("QR Code"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ScanType.dataMatrix),
            child: const Text("Data Matrix"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ScanType.ean13),
            child: const Text("EAN-13 (1D)"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ScanType.code128),
            child: const Text("Code 128"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _scanType = result;

        /// restart skanera
        _scanner.close();
        _scanner = BarcodeScanner(
          formats: _getFormats(),
        );
      });
    }
  }

  Future<void> _scan() async {
    if (_cameraController == null) return;
    if (_processing) return;

    _processing = true;

    try {
      final file = await _cameraController!.takePicture();
      final image = InputImage.fromFile(File(file.path));

      final barcodes = await _scanner.processImage(image);

      if (barcodes.isEmpty) return;

      final value = barcodes.first.rawValue;
      final scannedValue = value?.trim() ?? '';

      if (value != null) {
        if (!mounted) return;
        Navigator.pop(context, scannedValue);
      }
    } catch (e) {
      debugPrint("Scan error: $e");
    }

    _processing = false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanner.close();
    super.dispose();
  }

  /// 🎯 Overlay
  Widget _buildOverlay() {
    final size = MediaQuery.of(context).size.width;

    if (_is2D()) {
      /// 🔳 2D (QR / DataMatrix)
      return Center(
        child: Container(
          width: size * 0.6,
          height: size * 0.6,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 3),
          ),
        ),
      );
    } else {
      /// 📏 1D (EAN / Code128)
      return Center(
        child: Container(
          width: size * 0.8,
          height: size * 0.25,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 3),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      appBar: AppBar(title: const Text("Skanuj kod")),
      backgroundColor: Colors.black,
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CameraPreview(controller),

          /// 🎯 Overlay dynamiczny
          _buildOverlay(),

          /// ℹ️ Informacja o trybie
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                color: Colors.black54,
                child: Text(
                  "Tryb: ${_getScanTypeLabel()}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                /// 🔦 LATARKA
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _toggleTorch,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _torchOn
                          ? Icons.flash_on
                          : Icons.flash_off,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// 📷 SKANUJ
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera),
                    label: const Text("Skanuj"),
                    style: ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _scan,
                  ),
                ),

                const SizedBox(width: 12),

                /// 🔀 WYBÓR TYPU
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectScanType,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.qr_code_scanner),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}