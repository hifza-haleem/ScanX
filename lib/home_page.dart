import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'scan_result_page.dart';
import 'doc_cv_utils.dart';
import 'crnn_ocr_utils.dart';
import 'handwritten_result_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color deepBlue = Color(0xFF1e354e);
  static const Color darkGrey = Color(0xFF171e26);

  CameraController? _controller;
  bool _isCameraMode = false;
  bool _isProcessing = false;
  String? _error;
  List<File> _pickedFiles = [];
  List<Uint8List> _thumbnails = [];

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startCameraMode() async {
    setState(() {
      _isCameraMode = true;
      _pickedFiles.clear();
      _thumbnails.clear();
    });
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      setState(() {
        _error = "Camera initialization failed: $e";
      });
    }
  }

  Future<void> _addCameraPage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final file = await _controller!.takePicture();
      setState(() {
        _pickedFiles.add(File(file.path));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Capture failed: $e")),
      );
    }
  }

  Future<void> _exitCameraMode() async {
    _controller?.dispose();
    setState(() {
      _isCameraMode = false;
      _pickedFiles.clear();
      _thumbnails.clear();
      _error = null;
    });
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      _isCameraMode = false;
      _pickedFiles.clear();
      _thumbnails.clear();
    });
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images == null || images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No images selected.")),
      );
      return;
    }
    setState(() {
      _pickedFiles = images.map((x) => File(x.path)).toList();
    });
    _processAndShow(_pickedFiles);
  }

  Future<void> _processAndShow(List<File> files) async {
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add/select at least one page!")),
      );
      return;
    }
    setState(() {
      _isProcessing = true;
    });
    List<Uint8List> processedPages = [];
    for (final file in files) {
      final imageBytes = await file.readAsBytes();
      final processed = await OpenCVNative.processDocument(imageBytes);
      if (processed != null) {
        processedPages.add(processed);
      }
    }
    setState(() {
      _isProcessing = false;
      _pickedFiles.clear();
      _thumbnails.clear();
    });
    if (processedPages.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(processedImages: processedPages),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No pages could be processed.")),
      );
    }
  }

  Future<void> _pickHandwrittenImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imgFile = await picker.pickImage(source: ImageSource.gallery);

    if (imgFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image selected.")),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bytes = await imgFile.readAsBytes();
      String text = await CRNNOCR.recognizeText(bytes);

      setState(() => _isProcessing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HandwrittenResultPage(image: bytes, ocrText: text),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OCR failed: $e")),
      );
    }
  }

  Widget _buildMainMenu() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 92,
              height: 92,
              fit: BoxFit.contain,
            ),
            const Text(
              "ScanX",
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "AI-powered Document Scanner",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text("Open Camera", style: TextStyle(fontSize: 20)),
              onPressed: _isProcessing ? null : _startCameraMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: deepBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(250, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library, size: 28),
              label: const Text("Upload from Gallery",
                  style: TextStyle(fontSize: 20)),
              onPressed: _isProcessing ? null : _pickFromGallery,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(250, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              icon: const Icon(Icons.gesture, size: 28),
              label: const Text("Handwritten OCR (CRNN)",
                  style: TextStyle(fontSize: 20)),
              onPressed: _isProcessing ? null : _pickHandwrittenImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(250, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 18),
            if (_isProcessing) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraMode() {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Text(
          "Capture Documents",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _controller == null || !_controller!.value.isInitialized
              ? (_error != null
                  ? Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.white)))
                  : const Center(child: CircularProgressIndicator()))
              : Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                    if (_isProcessing)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
        ),
        if (_pickedFiles.isNotEmpty)
          SizedBox(
            height: 86,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedFiles.length,
              itemBuilder: (context, idx) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Image.file(_pickedFiles[idx],
                    width: 60, height: 78, fit: BoxFit.cover),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add Page"),
                onPressed: _isProcessing ? null : _addCameraPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Scan All"),
                onPressed:
                    _isProcessing ? null : () => _processAndShow(_pickedFiles),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.close),
                label: const Text("Exit Camera"),
                onPressed: _isProcessing ? null : _exitCameraMode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        backgroundColor: deepBlue,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            const Text(
              "ScanX",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: "History",
              onPressed: () => Navigator.pushNamed(context, '/history'),
            ),
          ],
        ),
      ),
      body: _isCameraMode ? _buildCameraMode() : _buildMainMenu(),
    );
  }
}
