package com.sha.innosphere

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create high-priority notification channel for Android 8+
        createNotificationChannel()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "high_importance_channel"
            val channelName = "Messages"
            val channelDescription = "High priority notifications for messages and alerts"
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableLights(true)
                lightColor = 0xFFf1bcb5.toInt()
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
                
                // Set notification sound
                val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()
                setSound(soundUri, audioAttributes)
                
                // Show badge on app icon
                setShowBadge(true)
                
                // Lock screen visibility
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            
            // Also create a default OneSignal channel with high importance
            val onesignalChannel = NotificationChannel(
                "fcm_fallback_notification_channel",
                "General Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Default notification channel"
                enableLights(true)
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
                val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()
                setSound(soundUri, audioAttributes)
                setShowBadge(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(onesignalChannel)
            
            android.util.Log.d("MainActivity", "🔔 High-priority notification channels created")
        }
    }
}
