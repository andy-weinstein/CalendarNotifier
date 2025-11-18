package com.calendarnotifier.ui

import android.app.Application
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.calendarnotifier.data.model.CalendarEvent
import com.calendarnotifier.data.repository.EventRepository
import com.calendarnotifier.data.repository.SettingsRepository
import com.calendarnotifier.service.GoogleCalendarManager
import com.calendarnotifier.service.NotificationScheduler
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.Date

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val context = application.applicationContext
    val calendarManager = GoogleCalendarManager(context)
    private val eventRepository = EventRepository(context)
    val settingsRepository = SettingsRepository(context)
    private val notificationScheduler = NotificationScheduler(context)

    private val _events = MutableStateFlow<List<CalendarEvent>>(emptyList())
    val events: StateFlow<List<CalendarEvent>> = _events.asStateFlow()

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _lastSyncCount = MutableStateFlow<Int?>(null)
    val lastSyncCount: StateFlow<Int?> = _lastSyncCount.asStateFlow()

    private val _isSignedIn = MutableStateFlow(false)
    val isSignedIn: StateFlow<Boolean> = _isSignedIn.asStateFlow()

    val nextEvent: CalendarEvent?
        get() = _events.value
            .filter { it.startDate.after(Date()) }
            .minByOrNull { it.startDate }

    init {
        _isSignedIn.value = calendarManager.isSignedIn
        loadCachedEvents()
    }

    private fun loadCachedEvents() {
        val cached = eventRepository.loadEvents()
        _events.value = cached
    }

    fun updateSignInState() {
        _isSignedIn.value = calendarManager.isSignedIn
    }

    fun syncCalendar() {
        if (_isSyncing.value) return

        viewModelScope.launch {
            _isSyncing.value = true
            _lastSyncCount.value = null

            try {
                val newEvents = calendarManager.fetchEvents()
                _events.value = newEvents
                eventRepository.saveEvents(newEvents)

                // Schedule notifications
                val firstMinutes = settingsRepository.firstReminderMinutes.first()
                val secondMinutes = settingsRepository.secondReminderMinutes.first()
                val firstSound = settingsRepository.firstReminderSound.first()
                val secondSound = settingsRepository.secondReminderSound.first()

                newEvents.forEach { event ->
                    notificationScheduler.scheduleNotifications(
                        event = event,
                        firstReminderMinutes = firstMinutes,
                        secondReminderMinutes = secondMinutes,
                        firstSound = firstSound,
                        secondSound = secondSound
                    )
                }

                _lastSyncCount.value = newEvents.size
                triggerHapticFeedback()

                // Clear sync count after 3 seconds
                viewModelScope.launch {
                    kotlinx.coroutines.delay(3000)
                    _lastSyncCount.value = null
                }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                _isSyncing.value = false
            }
        }
    }

    private fun triggerHapticFeedback() {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(VibratorManager::class.java)
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Vibrator::class.java)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(100)
            }
        } catch (e: Exception) {
            // Ignore vibration errors
        }
    }

    fun signOut() {
        viewModelScope.launch {
            calendarManager.signOut()
            eventRepository.clearEvents()
            notificationScheduler.cancelAllNotifications()
            _events.value = emptyList()
            _isSignedIn.value = false
        }
    }

    fun sendTestNotification(reminderType: String) {
        viewModelScope.launch {
            val soundId = if (reminderType == "first") {
                settingsRepository.firstReminderSound.first()
            } else {
                settingsRepository.secondReminderSound.first()
            }

            val minutes = if (reminderType == "first") {
                settingsRepository.firstReminderMinutes.first()
            } else {
                settingsRepository.secondReminderMinutes.first()
            }

            val minutesLabel = com.calendarnotifier.data.model.ReminderTime.availableTimes
                .find { it.minutes == minutes }?.label ?: "$minutes minutes"

            notificationScheduler.sendTestNotification(reminderType, soundId, minutesLabel)
        }
    }
}
