package com.example.flutter_ui.features

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class ClipboardHandler(
    private val activity: FlutterActivity,
    messenger: BinaryMessenger
) {
    private val channel = MethodChannel(messenger, "com.example.flutter_ui/clipboard")
    private val manager = activity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getText" -> {
                    val text = manager.primaryClip?.getItemAt(0)?.text?.toString()
                    result.success(text)
                }
                "setText" -> {
                    val text = call.argument<String>("text") ?: ""
                    manager.setPrimaryClip(ClipData.newPlainText("phone_link", text))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
