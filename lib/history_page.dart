import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'models.dart';
import 'scan_result_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ScanHistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await ScanHistory.getHistory();
    setState(() {
      _history = history.reversed.toList(); // most recent first
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(int idx) async {
    await ScanHistory.deleteScan(_history.length - 1 - idx);
    await _loadHistory();
  }

  void _openScan(ScanHistoryItem item) {
    final images = item.base64Pages.map((b64) => base64Decode(b64)).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultPage(processedImages: images),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan History"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text("No scan history yet."))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, idx) {
                    final item = _history[idx];
                    final date = item.time;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      child: ListTile(
                        leading: Image.memory(
                            base64Decode(item.base64Pages.first),
                            width: 54,
                            height: 68,
                            fit: BoxFit.cover),
                        title: Text(
                          "Scanned on ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: color),
                        ),
                        subtitle: Text("Pages: ${item.base64Pages.length}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteItem(idx),
                        ),
                        onTap: () => _openScan(item),
                      ),
                    );
                  },
                ),
    );
  }
}
