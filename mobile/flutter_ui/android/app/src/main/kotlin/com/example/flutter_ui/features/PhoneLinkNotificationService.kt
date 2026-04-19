package com.example.flutter_ui.features

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class PhoneLinkNotificationService : NotificationListenerService() {

    companion object {
        var handler: NotificationHandler? = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val map = mapOf(
            "key" to sbn.key,
            "app_package" to sbn.packageName,
            "app_name" to getAppName(sbn.packageName),
            "title" to (extras.getCharSequence("android.title")?.toString() ?: ""),
            "text" to (extras.getCharSequence("android.text")?.toString() ?: ""),
            "posted_at" to (sbn.postTime / 1000)
        )
        handler?.onNotificationPosted(map)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        handler?.onNotificationRemoved(sbn.key)
    }

    private fun getAppName(packageName: String): String {
        return try {
            val info = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(info).toString()
        } catch (_: Exception) {
            packageName
        }
    }
}
