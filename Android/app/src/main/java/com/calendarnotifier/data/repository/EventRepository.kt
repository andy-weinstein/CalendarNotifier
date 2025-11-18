package com.calendarnotifier.data.repository

import android.content.Context
import com.calendarnotifier.data.model.CalendarEvent
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.io.File

class EventRepository(private val context: Context) {

    private val gson = Gson()
    private val eventsFile: File
        get() = File(context.filesDir, "events.json")

    fun saveEvents(events: List<CalendarEvent>) {
        val json = gson.toJson(events)
        eventsFile.writeText(json)
    }

    fun loadEvents(): List<CalendarEvent> {
        return try {
            if (eventsFile.exists()) {
                val json = eventsFile.readText()
                val type = object : TypeToken<List<CalendarEvent>>() {}.type
                gson.fromJson(json, type) ?: emptyList()
            } else {
                emptyList()
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun clearEvents() {
        if (eventsFile.exists()) {
            eventsFile.delete()
        }
    }
}
