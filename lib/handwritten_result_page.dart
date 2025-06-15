import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HandwrittenResultPage extends StatelessWidget {
  final Uint8List image;
  final String ocrText;

  const HandwrittenResultPage(
      {Key? key, required this.image, required this.ocrText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handwritten OCR Result'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.memory(image, fit: BoxFit.contain, height: 220),
            const SizedBox(height: 24),
            const Text(
              "Predicted Text:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                ocrText.isNotEmpty ? ocrText : "No text detected.",
                style: const TextStyle(fontSize: 17),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy Text'),
              onPressed: ocrText.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: ocrText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard!')),
                      );
                    },
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text("Back"),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
