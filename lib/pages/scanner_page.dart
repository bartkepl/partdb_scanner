import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../services/api_service.dart';
import '../pages/part_detail_page.dart';

class ScannerPage extends StatefulWidget {
  final ApiService apiService;
  const ScannerPage({required this.apiService, super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _cameraController;
  late BarcodeScanner _barcodeScanner;
  bool _processing = false;
  final bool _captureRequested = false;
  String _status = 'Gotowy do skanowania';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.dataMatrix]);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first);

    final controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();

    await widget.apiService.loadConfig();
    final configuredZoom = widget.apiService.zoomLevel;

    final maxZoom = await controller.getMaxZoomLevel();
    final minZoom = await controller.getMinZoomLevel();

    final desiredZoom = configuredZoom.clamp(minZoom, maxZoom);

    await controller.setZoomLevel(desiredZoom);


    setState(() {
      _cameraController = controller;
      _status = 'Gotowy do skanowania (zoom x${desiredZoom.toStringAsFixed(2)})';
    });
  }

  bool _isValidIpn(String value) {
    final regex = RegExp(r'^\d{7}$');
    return regex.hasMatch(value);
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

      setState(() {
        _status = "Token API zapisany";
      });
    }
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() => _status = 'Kamera nie gotowa');
      return;
    }
    if (_processing) return;

    setState(() {
      _processing = true;
      _status = 'Wykonywanie zdjęcia...';
    });

    try {
      final XFile xfile = await _cameraController!.takePicture();
      final file = File(xfile.path);

      final inputImage = InputImage.fromFile(file);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isEmpty) {
        setState(() {
          _status = 'Nie znaleziono kodu DataMatrix';
          _processing = false;
        });
        return;
      }

      final scannedValue = barcodes.first.rawValue?.trim() ?? '';

      if (scannedValue.isEmpty) {
        setState(() {
          _status = 'Kod nie zawiera danych';
          _processing = false;
        });
        return;
      }

// 🔎 Sprawdzenie czy to 7 cyfr (IPN)
      if (!_isValidIpn(scannedValue)) {
        setState(() {
          _processing = false;
          _status = 'To nie jest poprawny IPN';
        });

        await _showTokenDialog(scannedValue);
        return;
      }

      print('📦 Zeskanowano IPN: $scannedValue');
      setState(() => _status = 'Pobieram dane z serwera...');

      await widget.apiService.loadConfig();
      final part = await widget.apiService.findPartByIPN(scannedValue);

      if (!mounted) return;

      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PartDetailPage(part: part, apiService: widget.apiService),
      ));

      setState(() {
        _status = 'Gotowy do skanowania';
      });
    } catch (e) {
      setState(() {
        _status = 'Błąd skanowania: $e';
      });
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    return Scaffold(
      appBar: AppBar(title: const Text('Skaner DataMatrix')),
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
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera),
                  label: Text(_processing ? 'Przetwarzanie...' : 'Zeskanuj kod'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: _processing ? null : _captureAndScan,
                ),
                const SizedBox(height: 8),
                Text(_status, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
