import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class BarcodeScanPage extends StatefulWidget {
  final ApiService apiService;
  const BarcodeScanPage({required this.apiService,super.key});


  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {

  CameraController? _cameraController;
  late BarcodeScanner _scanner;
  bool _processing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scanner = BarcodeScanner();
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

  bool _isScanToken(String value) {
    return value.length > 15;
  }

  Future<void> _showTokenDialog(String scannedValue) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("To nie jest IPN"),
        content: Text(
            "Zeskanowana wartość:\n\n$scannedValue\n\n"
                "Nie wygląda na numer IPN (7 cyfr).\n"
                "Czy zapisać jako API Token?"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Nie"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Tak"),
          ),
        ],
      ),
    );

    if (result == true) {
      await widget.apiService.saveConfig(
        widget.apiService.baseUrl,
        scannedValue,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Token API zapisany")),
      );

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

      final scannedValue = barcodes.first.rawValue?.trim() ?? '';



      if (value != null) {
        if (_isScanToken(scannedValue)) {
          await _showTokenDialog(scannedValue);
          Navigator.pop(context, '');
          _processing = false;
          return;
        }

        Navigator.pop(context, value);
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

          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 3),
              ),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [

                /// 🔦 LATARKA (mały okrągły)
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
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                /// 📷 SKANUJ (duży)
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera),
                    label: const Text("Skanuj"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _scan,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}