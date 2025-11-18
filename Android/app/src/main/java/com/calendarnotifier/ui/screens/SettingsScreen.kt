package com.calendarnotifier.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.calendarnotifier.R
import com.calendarnotifier.data.model.NotificationSound
import com.calendarnotifier.data.model.ReminderTime
import com.calendarnotifier.ui.MainViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: MainViewModel,
    onDismiss: () -> Unit
) {
    val scope = rememberCoroutineScope()

    val firstReminderMinutes by viewModel.settingsRepository.firstReminderMinutes.collectAsState(initial = 60)
    val secondReminderMinutes by viewModel.settingsRepository.secondReminderMinutes.collectAsState(initial = 15)
    val firstReminderSound by viewModel.settingsRepository.firstReminderSound.collectAsState(initial = "default")
    val secondReminderSound by viewModel.settingsRepository.secondReminderSound.collectAsState(initial = "default")

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .padding(bottom = 32.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = stringResource(R.string.settings),
                    style = MaterialTheme.typography.headlineSmall
                )
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, contentDescription = "Close")
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Reminder Times Section
            Text(
                text = "Reminder Times",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(8.dp))

            // First Reminder Time
            ReminderTimePicker(
                label = stringResource(R.string.first_reminder),
                selectedMinutes = firstReminderMinutes,
                onMinutesSelected = { minutes ->
                    scope.launch {
                        viewModel.settingsRepository.setFirstReminderMinutes(minutes)
                    }
                }
            )

            // Second Reminder Time
            ReminderTimePicker(
                label = stringResource(R.string.second_reminder),
                selectedMinutes = secondReminderMinutes,
                onMinutesSelected = { minutes ->
                    scope.launch {
                        viewModel.settingsRepository.setSecondReminderMinutes(minutes)
                    }
                }
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Reminder Sounds Section
            Text(
                text = stringResource(R.string.reminder_sounds),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(8.dp))

            // First Reminder Sound
            SoundPicker(
                label = stringResource(R.string.first_reminder),
                selectedSound = firstReminderSound,
                onSoundSelected = { soundId ->
                    scope.launch {
                        viewModel.settingsRepository.setFirstReminderSound(soundId)
                    }
                }
            )

            // Second Reminder Sound
            SoundPicker(
                label = stringResource(R.string.second_reminder),
                selectedSound = secondReminderSound,
                onSoundSelected = { soundId ->
                    scope.launch {
                        viewModel.settingsRepository.setSecondReminderSound(soundId)
                    }
                }
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Test Notifications Section
            Text(
                text = stringResource(R.string.test_notifications),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = { viewModel.sendTestNotification("first") },
                    modifier = Modifier.weight(1f)
                ) {
                    Text(stringResource(R.string.test_first_reminder))
                }

                OutlinedButton(
                    onClick = { viewModel.sendTestNotification("second") },
                    modifier = Modifier.weight(1f)
                ) {
                    Text(stringResource(R.string.test_second_reminder))
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Account Section
            Text(
                text = stringResource(R.string.account),
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(modifier = Modifier.height(8.dp))

            viewModel.calendarManager.currentAccount?.let { account ->
                Text(
                    text = account.email ?: "",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(8.dp))
            }

            TextButton(
                onClick = {
                    viewModel.signOut()
                    onDismiss()
                },
                colors = ButtonDefaults.textButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text(stringResource(R.string.sign_out))
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ReminderTimePicker(
    label: String,
    selectedMinutes: Int,
    onMinutesSelected: (Int) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedLabel = ReminderTime.availableTimes.find { it.minutes == selectedMinutes }?.label ?: ""

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it }
    ) {
        OutlinedTextField(
            value = selectedLabel,
            onValueChange = {},
            readOnly = true,
            label = { Text(label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .fillMaxWidth()
                .menuAnchor()
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            ReminderTime.availableTimes.forEach { time ->
                DropdownMenuItem(
                    text = { Text(time.label) },
                    onClick = {
                        onMinutesSelected(time.minutes)
                        expanded = false
                    }
                )
            }
        }
    }

    Spacer(modifier = Modifier.height(8.dp))
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SoundPicker(
    label: String,
    selectedSound: String,
    onSoundSelected: (String) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val selectedLabel = NotificationSound.availableSounds.find { it.id == selectedSound }?.name ?: ""

    ExposedDropdownMenuBox(
        expanded = expanded,
        onExpandedChange = { expanded = it }
    ) {
        OutlinedTextField(
            value = selectedLabel,
            onValueChange = {},
            readOnly = true,
            label = { Text(label) },
            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
            modifier = Modifier
                .fillMaxWidth()
                .menuAnchor()
        )

        ExposedDropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false }
        ) {
            NotificationSound.availableSounds.forEach { sound ->
                DropdownMenuItem(
                    text = { Text(sound.name) },
                    onClick = {
                        onSoundSelected(sound.id)
                        expanded = false
                    }
                )
            }
        }
    }

    Spacer(modifier = Modifier.height(8.dp))
}
