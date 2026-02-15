import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/api_service.dart';
import '../models/part.dart';
import '../pages/part_detail_page.dart';

class ScannerPage extends StatefulWidget {
  final ApiService apiService;
  const ScannerPage({required this.apiService, Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _cameraController;
  late BarcodeScanner _barcodeScanner;
  bool _processing = false;
  bool _captureRequested = false;
  String _status = 'Gotowy do skanowania';
  double _zoom = 2.0; // 🔍 domyślny zoom x2

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

    // 🔍 ustawienie zoom x2 (jeśli wspierany)
    final maxZoom = await controller.getMaxZoomLevel();
    final desiredZoom = (_zoom <= maxZoom) ? _zoom : maxZoom;
    await controller.setZoomLevel(desiredZoom);

    setState(() {
      _cameraController = controller;
      _status = 'Gotowy do skanowania (zoom x2)';
    });
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

      final ipn = barcodes.first.rawValue?.trim() ?? '';
      if (ipn.isEmpty) {
        setState(() {
          _status = 'Kod nie zawiera IPN';
          _processing = false;
        });
        return;
      }

      print('📦 Zeskanowano IPN: $ipn');
      setState(() => _status = 'Pobieram dane z serwera...');

      await widget.apiService.loadConfig();
      final part = await widget.apiService.findPartByIPN(ipn);

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
