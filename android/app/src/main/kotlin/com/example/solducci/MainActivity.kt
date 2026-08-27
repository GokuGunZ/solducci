package com.gokugunz.solducci

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gokugunz.solducci/intent"
    private var initialFilePath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent, true)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent, false)
    }

    private fun handleIntent(intent: Intent?, isInitial: Boolean) {
        if (intent?.action == Intent.ACTION_VIEW) {
            intent.data?.let { uri ->
                val filePath = copyUriToCache(uri)
                if (isInitial) {
                    initialFilePath = filePath
                } else {
                    flutterEngine?.dartExecutor?.binaryMessenger?.let {
                        MethodChannel(it, CHANNEL).invokeMethod("onNewFile", filePath)
                    }
                }
            }
        }
    }

    private fun copyUriToCache(uri: Uri): String? {
        try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            // We can try to extract original name from content resolver, but for simplicity we generate a name
            val fileName = "imported_${System.currentTimeMillis()}.md"
            val file = File(cacheDir, fileName)
            val outputStream = FileOutputStream(file)
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            return file.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getInitialFile") {
                result.success(initialFilePath)
                initialFilePath = null // consume it
            } else {
                result.notImplemented()
            }
        }
    }
}
