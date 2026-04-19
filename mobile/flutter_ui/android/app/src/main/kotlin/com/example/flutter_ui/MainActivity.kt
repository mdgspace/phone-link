package com.example.flutter_ui

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.flutter_ui.features.SmsHandler
import com.example.flutter_ui.features.NotificationHandler
import com.example.flutter_ui.features.ClipboardHandler
import com.example.flutter_ui.service.PhoneLinkService

class MainActivity : FlutterActivity() {

    private lateinit var smsHandler: SmsHandler
    private lateinit var notificationHandler: NotificationHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        smsHandler = SmsHandler(this, flutterEngine.dartExecutor.binaryMessenger)
        notificationHandler = NotificationHandler(this, flutterEngine.dartExecutor.binaryMessenger)
        ClipboardHandler(this, flutterEngine.dartExecutor.binaryMessenger)

        // Start the foreground service so the connection persists when UI is backgrounded
        startForegroundServiceIfNeeded()
    }

    private fun startForegroundServiceIfNeeded() {
        val intent = Intent(this, PhoneLinkService::class.java)
        startForegroundService(intent)
    }
}
