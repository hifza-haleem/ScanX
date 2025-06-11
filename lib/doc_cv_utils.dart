import 'dart:typed_data';
import 'package:flutter/services.dart';

class OpenCVNative {
  static const MethodChannel _channel = MethodChannel('scanx_cv');

  /// Processes an image using native OpenCV.
  static Future<Uint8List?> processDocument(Uint8List imageBytes) async {
    try {
      final result = await _channel.invokeMethod('processDocument', {
        'image': imageBytes,
      });
      if (result is Uint8List) {
        return result;
      }
      if (result is List<int>) {
        return Uint8List.fromList(result);
      }
      return null;
    } catch (e) {
      print("OpenCV processing error: $e");
      return null;
    }
  }
}
