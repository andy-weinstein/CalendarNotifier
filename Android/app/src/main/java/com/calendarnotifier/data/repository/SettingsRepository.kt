package com.calendarnotifier.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

class SettingsRepository(private val context: Context) {

    companion object {
        private val FIRST_REMINDER_MINUTES = intPreferencesKey("first_reminder_minutes")
        private val SECOND_REMINDER_MINUTES = intPreferencesKey("second_reminder_minutes")
        private val FIRST_REMINDER_SOUND = stringPreferencesKey("first_reminder_sound")
        private val SECOND_REMINDER_SOUND = stringPreferencesKey("second_reminder_sound")

        // Defaults
        const val DEFAULT_FIRST_REMINDER = 60  // 1 hour
        const val DEFAULT_SECOND_REMINDER = 15 // 15 minutes
        const val DEFAULT_SOUND = "default"
    }

    val firstReminderMinutes: Flow<Int> = context.dataStore.data.map { preferences ->
        preferences[FIRST_REMINDER_MINUTES] ?: DEFAULT_FIRST_REMINDER
    }

    val secondReminderMinutes: Flow<Int> = context.dataStore.data.map { preferences ->
        preferences[SECOND_REMINDER_MINUTES] ?: DEFAULT_SECOND_REMINDER
    }

    val firstReminderSound: Flow<String> = context.dataStore.data.map { preferences ->
        preferences[FIRST_REMINDER_SOUND] ?: DEFAULT_SOUND
    }

    val secondReminderSound: Flow<String> = context.dataStore.data.map { preferences ->
        preferences[SECOND_REMINDER_SOUND] ?: DEFAULT_SOUND
    }

    suspend fun setFirstReminderMinutes(minutes: Int) {
        context.dataStore.edit { preferences ->
            preferences[FIRST_REMINDER_MINUTES] = minutes
        }
    }

    suspend fun setSecondReminderMinutes(minutes: Int) {
        context.dataStore.edit { preferences ->
            preferences[SECOND_REMINDER_MINUTES] = minutes
        }
    }

    suspend fun setFirstReminderSound(soundId: String) {
        context.dataStore.edit { preferences ->
            preferences[FIRST_REMINDER_SOUND] = soundId
        }
    }

    suspend fun setSecondReminderSound(soundId: String) {
        context.dataStore.edit { preferences ->
            preferences[SECOND_REMINDER_SOUND] = soundId
        }
    }
}
