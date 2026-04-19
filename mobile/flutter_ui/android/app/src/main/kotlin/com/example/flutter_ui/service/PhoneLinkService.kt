package com.example.flutter_ui.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Foreground service that keeps the app alive in the background.
 * The actual socket connection is managed on the Dart side via dart:io;
 * this service just holds the foreground notification so Android doesn't
 * kill the process when the UI is closed.
 */
class PhoneLinkService : Service() {

    companion object {
        private const val CHANNEL_ID = "phone_link_service"
        private const val NOTIFICATION_ID = 1
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Restart automatically if the system kills us
        return START_STICKY
    }

    private fun buildNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Phone Link")
        .setContentText("Keeping your connection alive")
        .setSmallIcon(android.R.drawable.ic_menu_share)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .setOngoing(true)
        .build()

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Phone Link Service",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Keeps the Phone Link connection alive in the background"
        }
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }
}
