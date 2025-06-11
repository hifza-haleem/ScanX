
package com.example.scanx

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "scanx_cv"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "processDocument") {
                // Get byte array from Dart
                val imageBytes = call.argument<ByteArray>("image")
                // TODO: Add OpenCV document scan code here!
                // For now, just return the same image (no processing)
                if (imageBytes != null) {
                    result.success(imageBytes)
                } else {
                    result.error("NO_IMAGE", "No image provided", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
