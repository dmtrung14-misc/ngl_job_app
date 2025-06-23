package com.example.ngl_job_app_flutter

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.ngljobtracker/shared_content"
    private var sharedContent: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            if ("text/plain" == type) {
                val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (sharedText != null) {
                    sharedContent = sharedText
                    // If Flutter engine is ready, send the content immediately
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, CHANNEL).invokeMethod("onSharedContent", sharedText)
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedContent" -> {
                    result.success(sharedContent)
                    sharedContent = null // Clear after sending
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
