package com.example.flutter_ui.features

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges Flutter <-> PhoneLinkNotificationService.
 *
 * Flutter can ask Android whether notification access is enabled, open the
 * settings page, or cancel a specific Android notification by StatusBar key.
 */
class NotificationHandler(
    private val activity: FlutterActivity,
    messenger: BinaryMessenger
) {
    private val channel = MethodChannel(messenger, "com.example.flutter_ui/notifications")

    init {
        PhoneLinkNotificationService.handler = this

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isListenerActive" -> result.success(isListenerEnabled())

                "openNotificationSettings" -> {
                    activity.startActivity(
                        Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    )
                    result.success(null)
                }

                "cancelNotification" -> {
                    val key = call.argument<String>("key")
                    if (key.isNullOrEmpty()) {
                        result.error("INVALID_KEY", "Notification key is required", null)
                    } else if (PhoneLinkNotificationService.cancelNotification(key)) {
                        result.success(null)
                    } else {
                        result.error(
                            "NOTIFICATION_SERVICE_UNAVAILABLE",
                            "Notification listener is not connected",
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    fun onNotificationPosted(map: Map<String, Any>) {
        channel.invokeMethod("onNotificationPosted", map)
    }

    fun onNotificationRemoved(key: String) {
        channel.invokeMethod("onNotificationRemoved", mapOf("key" to key))
    }

    private fun isListenerEnabled(): Boolean {
        val listeners = Settings.Secure.getString(
            activity.contentResolver,
            "enabled_notification_listeners"
        ) ?: return false

        return listeners.contains(activity.packageName)
    }
}
