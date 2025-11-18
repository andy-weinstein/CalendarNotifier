package com.calendarnotifier.service

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.calendarnotifier.data.repository.EventRepository
import com.calendarnotifier.data.repository.SettingsRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Reschedule all notifications after device boot
            rescheduleNotifications(context)
        }
    }

    private fun rescheduleNotifications(context: Context) {
        CoroutineScope(Dispatchers.IO).launch {
            val eventRepository = EventRepository(context)
            val settingsRepository = SettingsRepository(context)
            val notificationScheduler = NotificationScheduler(context)

            val events = eventRepository.loadEvents()
            val firstMinutes = settingsRepository.firstReminderMinutes.first()
            val secondMinutes = settingsRepository.secondReminderMinutes.first()
            val firstSound = settingsRepository.firstReminderSound.first()
            val secondSound = settingsRepository.secondReminderSound.first()

            events.forEach { event ->
                notificationScheduler.scheduleNotifications(
                    event = event,
                    firstReminderMinutes = firstMinutes,
                    secondReminderMinutes = secondMinutes,
                    firstSound = firstSound,
                    secondSound = secondSound
                )
            }
        }
    }
}
