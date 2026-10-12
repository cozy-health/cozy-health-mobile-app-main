package com.example.cozy_health

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.media.AudioAttributes
import android.net.Uri

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("gentle_reminders_v2", "Gentle reminders", NotificationManager.IMPORTANCE_DEFAULT)
            channel.description = "Optional mood, journal, streak and affirmation reminders"
            channel.setSound(
                Uri.parse("android.resource://$packageName/${R.raw.cozy_notification}"),
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cozy_health/screen_capture")
            .setMethodCallHandler { call, result ->
                if (call.method == "setProtected") {
                    // Screenshot protection disabled app-wide.
                    // if (call.arguments == true) {
                    //     window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    // } else {
                    //     window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    // }
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(false)
                } else result.notImplemented()
            }
    }
}
