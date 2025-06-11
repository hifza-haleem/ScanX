import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfUtils {
  /// Exports a list of PNG/JPG images as a multi-page PDF file.
  static Future<File?> exportToPdf(List<Uint8List> images) async {
    try {
      final pdf = pw.Document();
      for (final imgBytes in images) {
        final image = pw.MemoryImage(imgBytes);
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Center(child: pw.Image(image)),
          ),
        );
      }
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/scanx_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print("PDF export error: $e");
      return null;
    }
  }
}
