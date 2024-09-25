// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones(); // Initialize time zones
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Reminder App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReminderPage(),
    );
  }
}

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  List<String> activities = [
    'Wake up',
    'Go to gym',
    'Breakfast',
    'Meetings',
    'Lunch',
    'Quick nap',
    'Go to library',
    'Dinner',
    'Go to sleep'
  ];

  String? selectedDay;
  TimeOfDay? selectedTime;
  String? selectedActivity;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification() async {
    try {
      if (selectedTime != null && selectedActivity != null) {
        final now = DateTime.now();
        var scheduledTime = DateTime(now.year, now.month, now.day,
            selectedTime!.hour, selectedTime!.minute);

        // If the scheduled time is before the current time, schedule for the next day
        if (scheduledTime.isBefore(now)) {
          scheduledTime = scheduledTime.add(const Duration(days: 1));
        }

        // Convert to TZDateTime
        final location = tz.local; // Get the local timezone
        final tzScheduledTime = tz.TZDateTime.from(scheduledTime, location);

        await _notificationsPlugin.zonedSchedule(
          0,
          'Reminder: $selectedActivity',
          'Time to ${selectedActivity!.toLowerCase()}!',
          tzScheduledTime, // Use TZDateTime here
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_channel',
              'Reminders',
              channelDescription: 'Channel for daily reminders',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        // Show feedback to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Reminder set for $selectedActivity at ${DateFormat.jm().format(scheduledTime)}')),
        );
      }
    } catch (e) {
      print('Error scheduling notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set reminder: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              hint: const Text('Select Day'),
              value: selectedDay,
              onChanged: (String? newValue) {
                setState(() {
                  selectedDay = newValue;
                });
              },
              items: daysOfWeek.map<DropdownMenuItem<String>>((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                TimeOfDay? time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    selectedTime = time;
                  });
                }
              },
              child: Text(selectedTime == null
                  ? 'Select Time'
                  : 'Selected Time: ${selectedTime!.format(context)}'),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              hint: const Text('Select Activity'),
              value: selectedActivity,
              onChanged: (String? newValue) {
                setState(() {
                  selectedActivity = newValue;
                });
              },
              items:
                  activities.map<DropdownMenuItem<String>>((String activity) {
                return DropdownMenuItem<String>(
                  value: activity,
                  child: Text(activity),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scheduleNotification,
              child: const Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
