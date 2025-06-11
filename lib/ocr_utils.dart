import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrUtils {
  /// Takes PNG/JPG image bytes and returns recognized text using ML Kit OCR.
  static Future<String> extractText(Uint8List imageBytes) async {
    // Save bytes as a temporary file, ML Kit only works with file path
    final tempDir = await getTemporaryDirectory();
    final tempFile = await File(
            '${tempDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.png')
        .create();
    await tempFile.writeAsBytes(imageBytes);

    final inputImage = InputImage.fromFilePath(tempFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    return recognizedText.text;
  }
}
