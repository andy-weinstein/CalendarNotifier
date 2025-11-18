package com.calendarnotifier.data.model

import android.media.RingtoneManager

data class NotificationSound(
    val id: String,
    val name: String,
    val uri: String? = null
) {
    companion object {
        val availableSounds = listOf(
            NotificationSound("default", "Default"),
            NotificationSound("alarm", "Alarm"),
            NotificationSound("notification", "Notification"),
            NotificationSound("ringtone", "Ringtone"),
            NotificationSound("silent", "Silent")
        )

        fun getSystemUri(id: String): android.net.Uri? {
            return when (id) {
                "default" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                "alarm" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                "notification" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                "ringtone" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                "silent" -> null
                else -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            }
        }
    }
}
