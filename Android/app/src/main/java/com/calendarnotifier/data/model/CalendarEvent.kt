package com.calendarnotifier.data.model

import java.util.Date

data class CalendarEvent(
    val id: String,
    val title: String,
    val startDate: Date,
    val location: String? = null,
    val description: String? = null
)
