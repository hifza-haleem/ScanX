import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// CRNN OCR Utility for Handwritten Text
class CRNNOCR {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;
  static List<String>? _labels;

  /// Load model and labels.txt once (singleton)
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _interpreter = await Interpreter.fromAsset('crnn_ocr.tflite');
    // Load labels file (ensure you added to pubspec.yaml assets!)
    final labelData = await rootBundle.loadString('assets/labels.txt');
    _labels = labelData
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _isInitialized = true;
  }

  /// Recognize text from a single image (bytes)
  static Future<String> recognize(Uint8List imageBytes) async {
    await initialize();

    // 1. Decode & resize to 256x64 grayscale
    img.Image? oriImg = img.decodeImage(imageBytes);
    if (oriImg == null) return "";
    final inputW = 256, inputH = 64;
    img.Image procImg = img.copyResize(oriImg, width: inputW, height: inputH);
    procImg = img.grayscale(procImg);

    // 2. Convert to normalized float32 tensor [1, 64, 256, 1]
    final input = List.generate(
      inputH,
      (y) => List.generate(
        inputW,
        (x) => [img.getLuminance(procImg.getPixel(x, y)) / 255.0],
      ),
    ); // shape [64][256][1]
    final inputTensor = [input]; // shape [1, 64, 256, 1]

    // 3. Prepare output tensor [1, 64, num_classes]
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    // 4. Run inference
    _interpreter!.run(inputTensor, output);

    // 5. CTC greedy decode
    List<int> predIndexes = [];
    int prev = -1;
    for (int t = 0; t < output[0].length; t++) {
      final scores = output[0][t];
      double maxVal = scores[0];
      int maxIdx = 0;
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxVal) {
          maxVal = scores[i];
          maxIdx = i;
        }
      }
      if (maxIdx != prev && maxIdx != 0) predIndexes.add(maxIdx);
      prev = maxIdx;
    }

    // 6. Map indexes to chars using labels
    if (_labels == null) return "";
    StringBuffer sb = StringBuffer();
    for (final idx in predIndexes) {
      if (idx < _labels!.length) {
        sb.write(_labels![idx]);
      }
    }
    return sb.toString();
  }
}
