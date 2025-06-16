import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// CRNN OCR Utility
class CRNNOCR {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;
  static List<String>? _labels;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      print("Loading crnn_ocr.tflite...");
      _interpreter = await Interpreter.fromAsset(
          'assets/crnn_ocr.tflite'); // <- Use full path
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n');
      _isInitialized = true;
      print("Model and labels loaded successfully");
    } catch (e) {
      print("ERROR LOADING MODEL: $e");
      rethrow;
    }
  }

  static Future<String> recognizeText(Uint8List imageBytes) async {
    await initialize();

    final oriImg = img.decodeImage(imageBytes);
    if (oriImg == null) return "";

    const inputW = 256, inputH = 64;

    img.Image resized = img.copyResize(oriImg, width: inputW, height: inputH);
    img.Image gray = img.grayscale(resized);

    var input = List.generate(
        inputH,
        (y) => List.generate(inputW, (x) {
              double normalized = img.getLuminance(gray.getPixel(x, y)) / 255.0;
              return [normalized];
            }));

    final inputTensor = [input]; // Shape: [1, 64, 256, 1]

    final outputTensor = List.generate(
      1,
      (_) => List.generate(
        64,
        (_) => List.filled(_interpreter!.getOutputTensor(0).shape[2], 0.0),
      ),
    );

    _interpreter!.run(inputTensor, outputTensor);

    List<int> predIndexes = [];
    int prev = -1;

    for (int t = 0; t < outputTensor[0].length; t++) {
      double maxVal = -1e9;
      int maxIdx = 0;

      for (int k = 0; k < outputTensor[0][t].length; k++) {
        if (outputTensor[0][t][k] > maxVal) {
          maxVal = outputTensor[0][t][k];
          maxIdx = k;
        }
      }

      if (maxIdx != prev && maxIdx != 0) {
        predIndexes.add(maxIdx);
      }
      prev = maxIdx;
    }

    final buffer = StringBuffer();
    for (int idx in predIndexes) {
      if (idx < (_labels?.length ?? 0)) {
        buffer.write(_labels![idx]);
      }
    }

    return buffer.toString();
  }
}
