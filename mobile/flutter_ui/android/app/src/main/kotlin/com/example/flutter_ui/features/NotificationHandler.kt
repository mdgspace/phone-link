package com.example.flutter_ui.features

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Handles the notification listener bridge.
 *
 * Android requires a NotificationListenerService subclass to read notifications.
 * That service (PhoneLinkNotificationService) calls back into this handler via
 * a companion object so it can forward events over the MethodChannel.
 */
class NotificationHandler(
    private val activity: FlutterActivity,
    messenger: BinaryMessenger
) {
    private val channel = MethodChannel(messenger, "com.example.flutter_ui/notifications")

    init {
        // Let the notification service know where to send events
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
