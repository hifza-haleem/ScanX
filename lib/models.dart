import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class ScanHistoryItem {
  final List<String> base64Pages; // each page as base64 PNG
  final List<String> ocrTexts;
  final DateTime time;

  ScanHistoryItem({
    required this.base64Pages,
    required this.ocrTexts,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
        'base64Pages': base64Pages,
        'ocrTexts': ocrTexts,
        'time': time.toIso8601String(),
      };

  static ScanHistoryItem fromMap(Map<String, dynamic> map) => ScanHistoryItem(
        base64Pages: List<String>.from(map['base64Pages']),
        ocrTexts: List<String>.from(map['ocrTexts']),
        time: DateTime.parse(map['time']),
      );
}

class ScanHistory {
  static const String _key = 'scanx_history';

  static Future<void> saveScan(
      List<Uint8List> pages, List<String> ocrTexts) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final newItem = ScanHistoryItem(
      base64Pages: pages.map((p) => base64Encode(p)).toList(),
      ocrTexts: ocrTexts,
      time: now,
    );
    final history = await getHistory();
    history.add(newItem);
    final historyJson = jsonEncode(history.map((e) => e.toMap()).toList());
    await prefs.setString(_key, historyJson);
  }

  static Future<List<ScanHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_key);
    if (historyJson == null) return [];
    final List decoded = jsonDecode(historyJson);
    return decoded.map((e) => ScanHistoryItem.fromMap(e)).toList();
  }

  static Future<void> deleteScan(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      final historyJson = jsonEncode(history.map((e) => e.toMap()).toList());
      await prefs.setString(_key, historyJson);
    }
  }
}
