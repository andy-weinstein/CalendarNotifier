package com.calendarnotifier.data.model

data class ReminderTime(
    val minutes: Int,
    val label: String
) {
    companion object {
        val availableTimes = listOf(
            ReminderTime(5, "5 minutes"),
            ReminderTime(10, "10 minutes"),
            ReminderTime(15, "15 minutes"),
            ReminderTime(30, "30 minutes"),
            ReminderTime(60, "1 hour"),
            ReminderTime(120, "2 hours"),
            ReminderTime(1440, "1 day")
        )
    }
}
