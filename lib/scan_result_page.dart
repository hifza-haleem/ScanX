import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'ocr_utils.dart';
import 'pdf_utils.dart';
import 'models.dart';

class ScanResultPage extends StatefulWidget {
  final List<Uint8List> processedImages;

  const ScanResultPage({Key? key, required this.processedImages})
      : super(key: key);

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  int _currentPage = 0;
  List<String?> _ocrResults = [];
  bool _isOcrLoading = false;
  bool _isPdfLoading = false;

  @override
  void initState() {
    super.initState();
    _ocrResults = List<String?>.filled(widget.processedImages.length, null);
  }

  Future<void> _runOcr() async {
    setState(() {
      _isOcrLoading = true;
    });
    String text =
        await OcrUtils.extractText(widget.processedImages[_currentPage]);
    setState(() {
      _ocrResults[_currentPage] = text;
      _isOcrLoading = false;
    });
  }

  Future<void> _copyText() async {
    final text = _ocrResults[_currentPage] ?? '';
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied to clipboard!')),
      );
    }
  }

  Future<void> _exportPDF() async {
    setState(() {
      _isPdfLoading = true;
    });
    final file = await PdfUtils.exportToPdf(widget.processedImages);
    setState(() {
      _isPdfLoading = false;
    });
    if (file != null) {
      // Share or save PDF
      await Share.shareXFiles([XFile(file.path)],
          text: "Here's my scanned PDF from ScanX!");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to export PDF.")),
      );
    }
  }

  Future<void> _saveToHistory() async {
    List<String> ocrTexts = _ocrResults.map((e) => e ?? '').toList();
    await ScanHistory.saveScan(widget.processedImages, ocrTexts);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan saved to history!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanned Pages"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Save to History",
            onPressed: _saveToHistory,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export as PDF",
            onPressed: _isPdfLoading ? null : _exportPDF,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: widget.processedImages.isEmpty
                  ? const Text("No scanned images.")
                  : Image.memory(widget.processedImages[_currentPage]),
            ),
          ),
          if (widget.processedImages.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 32),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text(
                    "Page ${_currentPage + 1} of ${widget.processedImages.length}",
                    style: TextStyle(fontSize: 16, color: color),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 32),
                    onPressed: _currentPage < widget.processedImages.length - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.text_snippet),
                      label: const Text("Extract Text"),
                      onPressed: _isOcrLoading ? null : _runOcr,
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy Text"),
                      onPressed:
                          (_ocrResults[_currentPage]?.isNotEmpty ?? false)
                              ? _copyText
                              : null,
                    ),
                  ],
                ),
                if (_isOcrLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                if (_ocrResults[_currentPage]?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _ocrResults[_currentPage]!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back to Camera"),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
