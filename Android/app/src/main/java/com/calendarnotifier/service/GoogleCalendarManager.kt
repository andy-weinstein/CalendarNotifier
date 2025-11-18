package com.calendarnotifier.service

import android.content.Context
import android.content.Intent
import com.calendarnotifier.data.model.CalendarEvent
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.Scope
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential
import com.google.api.client.http.javanet.NetHttpTransport
import com.google.api.client.json.gson.GsonFactory
import com.google.api.client.util.DateTime
import com.google.api.services.calendar.Calendar
import com.google.api.services.calendar.CalendarScopes
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.util.Date

class GoogleCalendarManager(private val context: Context) {

    private val signInOptions = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
        .requestEmail()
        .requestScopes(Scope(CalendarScopes.CALENDAR_READONLY))
        .build()

    val googleSignInClient: GoogleSignInClient = GoogleSignIn.getClient(context, signInOptions)

    val isSignedIn: Boolean
        get() = GoogleSignIn.getLastSignedInAccount(context) != null

    val currentAccount: GoogleSignInAccount?
        get() = GoogleSignIn.getLastSignedInAccount(context)

    fun getSignInIntent(): Intent = googleSignInClient.signInIntent

    suspend fun handleSignInResult(data: Intent?): Boolean {
        return try {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            task.await()
            true
        } catch (e: Exception) {
            false
        }
    }

    suspend fun signOut() {
        try {
            googleSignInClient.signOut().await()
        } catch (e: Exception) {
            // Ignore errors
        }
    }

    suspend fun fetchEvents(): List<CalendarEvent> = withContext(Dispatchers.IO) {
        val account = currentAccount ?: return@withContext emptyList()

        try {
            val credential = GoogleAccountCredential.usingOAuth2(
                context,
                listOf(CalendarScopes.CALENDAR_READONLY)
            ).apply {
                selectedAccount = account.account
            }

            val calendarService = Calendar.Builder(
                NetHttpTransport(),
                GsonFactory.getDefaultInstance(),
                credential
            )
                .setApplicationName("Calendar Notifier")
                .build()

            val now = DateTime(System.currentTimeMillis())
            val oneWeekLater = DateTime(System.currentTimeMillis() + 7 * 24 * 60 * 60 * 1000L)

            val events = calendarService.events().list("primary")
                .setTimeMin(now)
                .setTimeMax(oneWeekLater)
                .setOrderBy("startTime")
                .setSingleEvents(true)
                .setMaxResults(50)
                .execute()

            events.items?.mapNotNull { event ->
                val startDateTime = event.start?.dateTime ?: event.start?.date
                startDateTime?.let {
                    CalendarEvent(
                        id = event.id,
                        title = event.summary ?: "Untitled Event",
                        startDate = Date(it.value),
                        location = event.location,
                        description = event.description
                    )
                }
            } ?: emptyList()
        } catch (e: Exception) {
            e.printStackTrace()
            emptyList()
        }
    }
}
