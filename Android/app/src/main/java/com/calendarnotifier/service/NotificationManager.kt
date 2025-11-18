package com.calendarnotifier.service

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import androidx.core.app.NotificationCompat
import com.calendarnotifier.MainActivity
import com.calendarnotifier.R
import com.calendarnotifier.data.model.CalendarEvent
import com.calendarnotifier.data.model.NotificationSound
import com.calendarnotifier.data.model.ReminderTime

class NotificationScheduler(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "calendar_reminders"
        const val EXTRA_EVENT_ID = "event_id"
        const val EXTRA_EVENT_TITLE = "event_title"
        const val EXTRA_REMINDER_TYPE = "reminder_type"
        const val EXTRA_SOUND_ID = "sound_id"
    }

    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = context.getString(R.string.notification_channel_description)
                enableVibration(true)
                setSound(
                    NotificationSound.getSystemUri("default"),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun scheduleNotifications(
        event: CalendarEvent,
        firstReminderMinutes: Int,
        secondReminderMinutes: Int,
        firstSound: String,
        secondSound: String
    ) {
        // Cancel existing notifications for this event
        cancelNotifications(event.id)

        // Schedule first reminder
        scheduleNotification(
            event = event,
            minutesBefore = firstReminderMinutes,
            reminderType = "first",
            soundId = firstSound
        )

        // Schedule second reminder
        scheduleNotification(
            event = event,
            minutesBefore = secondReminderMinutes,
            reminderType = "second",
            soundId = secondSound
        )
    }

    private fun scheduleNotification(
        event: CalendarEvent,
        minutesBefore: Int,
        reminderType: String,
        soundId: String
    ) {
        val triggerTime = event.startDate.time - (minutesBefore * 60 * 1000L)

        // Don't schedule if time has passed
        if (triggerTime <= System.currentTimeMillis()) return

        val intent = Intent(context, NotificationReceiver::class.java).apply {
            putExtra(EXTRA_EVENT_ID, event.id)
            putExtra(EXTRA_EVENT_TITLE, event.title)
            putExtra(EXTRA_REMINDER_TYPE, reminderType)
            putExtra(EXTRA_SOUND_ID, soundId)
        }

        val requestCode = "${event.id}-$reminderType".hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                }
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
        } catch (e: SecurityException) {
            // Fall back to inexact alarm
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
        }
    }

    fun cancelNotifications(eventId: String) {
        listOf("first", "second").forEach { reminderType ->
            val requestCode = "$eventId-$reminderType".hashCode()
            val intent = Intent(context, NotificationReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            pendingIntent?.let {
                alarmManager.cancel(it)
                it.cancel()
            }
        }
    }

    fun cancelAllNotifications() {
        notificationManager.cancelAll()
    }

    fun showNotification(
        eventId: String,
        eventTitle: String,
        reminderType: String,
        soundId: String
    ) {
        val reminderLabel = if (reminderType == "first") {
            ReminderTime.availableTimes.find { it.minutes == 60 }?.label ?: "1 hour"
        } else {
            ReminderTime.availableTimes.find { it.minutes == 15 }?.label ?: "15 minutes"
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )

        val soundUri = NotificationSound.getSystemUri(soundId)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(eventTitle)
            .setContentText("Starting in $reminderLabel")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .apply {
                if (soundUri != null) {
                    setSound(soundUri)
                } else {
                    setSilent(true)
                }
            }
            .build()

        val notificationId = "$eventId-$reminderType".hashCode()
        notificationManager.notify(notificationId, notification)
    }

    fun sendTestNotification(reminderType: String, soundId: String, minutesLabel: String) {
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Test Notification")
            .setContentText("This is your $minutesLabel reminder sound")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .apply {
                val soundUri = NotificationSound.getSystemUri(soundId)
                if (soundUri != null) {
                    setSound(soundUri)
                } else {
                    setSilent(true)
                }
            }
            .build()

        val notificationId = "test-$reminderType".hashCode()
        notificationManager.notify(notificationId, notification)
    }
}
