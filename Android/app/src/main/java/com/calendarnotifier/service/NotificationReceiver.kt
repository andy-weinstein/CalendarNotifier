package com.calendarnotifier.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val eventId = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_ID) ?: return
        val eventTitle = intent.getStringExtra(NotificationScheduler.EXTRA_EVENT_TITLE) ?: return
        val reminderType = intent.getStringExtra(NotificationScheduler.EXTRA_REMINDER_TYPE) ?: return
        val soundId = intent.getStringExtra(NotificationScheduler.EXTRA_SOUND_ID) ?: "default"

        val notificationScheduler = NotificationScheduler(context)
        notificationScheduler.showNotification(eventId, eventTitle, reminderType, soundId)
    }
}
