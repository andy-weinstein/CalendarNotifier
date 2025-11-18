package com.calendarnotifier

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import kotlinx.coroutines.launch
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import com.calendarnotifier.ui.MainViewModel
import com.calendarnotifier.ui.screens.MainScreen
import com.calendarnotifier.ui.theme.CalendarNotifierTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            CalendarNotifierTheme {
                val viewModel: MainViewModel = viewModel()
                val isSignedIn by viewModel.isSignedIn.collectAsState()

                // Request notification permission for Android 13+
                val notificationPermissionLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.RequestPermission()
                ) { _ -> }

                LaunchedEffect(Unit) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (ContextCompat.checkSelfPermission(
                                this@MainActivity,
                                Manifest.permission.POST_NOTIFICATIONS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                        }
                    }

                    // Auto-sync on launch if signed in
                    if (isSignedIn) {
                        viewModel.syncCalendar()
                    }
                }

                // Coroutine scope for sign-in handling
                val scope = rememberCoroutineScope()

                // Google Sign-In launcher
                val signInLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.StartActivityForResult()
                ) { result ->
                    scope.launch {
                        val success = viewModel.calendarManager.handleSignInResult(result.data)
                        if (success) {
                            viewModel.updateSignInState()
                            viewModel.syncCalendar()
                        }
                    }
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen(
                        viewModel = viewModel,
                        onSignInClick = {
                            signInLauncher.launch(viewModel.calendarManager.getSignInIntent())
                        }
                    )
                }
            }
        }
    }
}
