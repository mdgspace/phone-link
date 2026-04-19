package com.example.flutter_ui.features

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.provider.Telephony
import android.telephony.SmsManager
import android.telephony.SmsMessage
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class SmsHandler(
    private val activity: FlutterActivity,
    messenger: BinaryMessenger
) {
    private val channel = MethodChannel(messenger, "com.example.flutter_ui/sms")

    private val smsReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            messages.forEach { msg ->
                val map = mapOf(
                    "id" to System.currentTimeMillis().toString(),
                    "address" to (msg.originatingAddress ?: ""),
                    "body" to (msg.messageBody ?: ""),
                    "is_incoming" to true,
                    "timestamp" to (msg.timestampMillis / 1000)
                )
                channel.invokeMethod("onSmsReceived", map)
            }
        }
    }

    init {
        activity.registerReceiver(
            smsReceiver,
            IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        )

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestSmsPermission" -> {
                    val perms = arrayOf(
                        Manifest.permission.READ_SMS,
                        Manifest.permission.SEND_SMS,
                        Manifest.permission.RECEIVE_SMS
                    )
                    val allGranted = perms.all {
                        ContextCompat.checkSelfPermission(activity, it) ==
                                PackageManager.PERMISSION_GRANTED
                    }
                    if (allGranted) {
                        result.success(true)
                    } else {
                        ActivityCompat.requestPermissions(activity, perms, 101)
                        result.success(false)
                    }
                }

                "getAllSms" -> {
                    try {
                        result.success(readAllSms())
                    } catch (e: Exception) {
                        result.error("SMS_ERROR", e.message, null)
                    }
                }

                "sendSms" -> {
                    val address = call.argument<String>("address") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    try {
                        val manager = activity.getSystemService(SmsManager::class.java)
                        manager.sendTextMessage(address, null, body, null, null)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SEND_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun readAllSms(): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val cursor = activity.contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf("_id", "address", "body", "date", "type"),
            null, null,
            "date DESC LIMIT 500"
        ) ?: return messages

        cursor.use {
            val idIdx = it.getColumnIndex("_id")
            val addrIdx = it.getColumnIndex("address")
            val bodyIdx = it.getColumnIndex("body")
            val dateIdx = it.getColumnIndex("date")
            val typeIdx = it.getColumnIndex("type")

            while (it.moveToNext()) {
                messages.add(mapOf(
                    "id" to it.getLong(idIdx).toString(),
                    "address" to (it.getString(addrIdx) ?: ""),
                    "body" to (it.getString(bodyIdx) ?: ""),
                    "timestamp" to (it.getLong(dateIdx) / 1000),
                    // type 1 = inbox (incoming), type 2 = sent
                    "is_incoming" to (it.getInt(typeIdx) == 1)
                ))
            }
        }
        return messages
    }
}
