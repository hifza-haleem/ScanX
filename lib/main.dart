import 'package:flutter/material.dart';
import 'splash_page.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'package:flutter/material.dart';
import 'crnn_ocr_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for async in main()
  await CRNNOCR.initialize(); // Preload TFLite model
  runApp(const ScanXApp());
}

class ScanXApp extends StatelessWidget {
  const ScanXApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanX',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff3f6fb),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff0a2540),
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: const Color(0xff0a2540),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashPage(),
        '/home': (_) => const HomePage(),
        '/history': (_) => const HistoryPage(),
      },
    );
  }
}
