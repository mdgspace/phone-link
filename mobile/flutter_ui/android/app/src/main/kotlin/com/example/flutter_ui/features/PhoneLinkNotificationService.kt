package com.example.flutter_ui.features

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class PhoneLinkNotificationService : NotificationListenerService() {

    companion object {
        var handler: NotificationHandler? = null
            set(value) {
                field = value
            }

        private var instance: PhoneLinkNotificationService? = null

        /**
         * Cancels the Android notification identified by StatusBarNotification.key.
         * Returns false if the listener service is not currently connected.
         */
        fun cancelNotification(key: String): Boolean {
            val service = instance ?: return false
            return try {
                service.cancelNotification(key)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
    }

    override fun onListenerDisconnected() {
        if (instance === this) {
            instance = null
        }
        super.onListenerDisconnected()
    }

    override fun onDestroy() {
        if (instance === this) {
            instance = null
        }
        super.onDestroy()
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
