import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';
import 'persian.dart';
import 'store.dart';

/// Minutes after the dose time when the reminder repeats if the parent has
/// not pressed «خوردم».
const followUpMinutes = [10, 20];

/// How many minutes «بعداً یادم بنداز» waits.
const snoozeMinutes = 10;

/// The calendar day a reminder for [pill] that fires or is opened at [now]
/// belongs to. Opening the app shortly before the dose time still counts as
/// today; opening it after midnight for a late-evening pill counts as
/// yesterday's dose.
DateTime doseDayFor(Pill pill, DateTime now) {
  final nowMin = now.hour * 60 + now.minute;
  final today = DateTime(now.year, now.month, now.day);
  if (nowMin >= pill.minutesOfDay - 60) return today;
  return today.subtract(const Duration(days: 1));
}

/// A tapped notification, decoded.
class ReminderTap {
  ReminderTap(this.pillId, this.day);
  final int pillId;

  /// Day the dose belongs to, or null for the daily repeating reminder.
  final DateTime? day;

  static ReminderTap? parse(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split('|');
    final id = int.tryParse(parts.first);
    if (id == null) return null;
    DateTime? day;
    if (parts.length > 1) day = DateTime.tryParse(parts[1]);
    return ReminderTap(id, day);
  }
}

/// Schedules the phone's own reminders (they work with the app closed and
/// without internet).
///
/// For every pill there is:
///  * one reminder that repeats every day at the pill's time, and
///  * one-off follow-ups 10 and 20 minutes later for today and tomorrow,
///    which are removed as soon as the dose is marked as taken.
/// iPhone keeps at most 64 pending reminders, which allows about ten pills.
class Reminders {
  Reminders._();
  static final Reminders instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = ValueNotifier<ReminderTap?>(null);

  /// Fires when the parent taps a reminder while the app is running.
  ValueListenable<ReminderTap?> get taps => _taps;

  /// Turned off in tests, where no phone is there to schedule on.
  bool enabled = true;

  bool _exactAllowed = true;

  static const _channelId = 'pill_alarm_v1';

  Future<ReminderTap?> init() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Keep UTC if the zone is unknown; times would then be off, so this is
      // only a last resort.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        _taps.value = ReminderTap.parse(r.payload);
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      return ReminderTap.parse(launch!.notificationResponse?.payload);
    }
    return null;
  }

  /// Asks for every permission reminders need. Safe to call repeatedly.
  Future<void> requestPermissions() async {
    if (!enabled) return;
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true, badge: false);
    } else if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      if (!(await android?.canScheduleExactNotifications() ?? true)) {
        await android?.requestExactAlarmsPermission();
      }
      await android?.requestFullScreenIntentPermission();
      _exactAllowed = await android?.canScheduleExactNotifications() ?? true;
    }
  }

  NotificationDetails _details(Store store, Pill pill) {
    final voice = store.voiceFor(pill);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'یادآوری قرص',
        channelDescription: 'زنگ موقع خوردن قرص',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        ongoing: false,
        autoCancel: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        // The family's own recorded voice. iOS falls back to the default
        // sound if the file is missing.
        sound: voice,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  String _title(Store store) {
    final who = store.parentTitle.isEmpty ? '' : '${store.parentTitle}، ';
    return '$whoموقع خوردن قرص است';
  }

  String _body(Pill pill) =>
      'قرص ${pill.name} — ساعت ${timeLabel(pill.hour, pill.minute)}';

  AndroidScheduleMode get _mode => _exactAllowed
      ? AndroidScheduleMode.alarmClock
      : AndroidScheduleMode.inexactAllowWhileIdle;

  /// Clears and rebuilds every reminder from the current list of pills.
  /// Called on start, when the app comes back to the screen, and after any
  /// change, so the schedule never drifts from what is shown.
  Future<void> rescheduleAll(Store store) async {
    if (!enabled) return;
    // Cancel everything except a pending snooze of a pill that still exists.
    for (final r in await _plugin.pendingNotificationRequests()) {
      final keepSnooze = r.id % 10 == 9 && store.pillById(r.id ~/ 10) != null;
      if (!keepSnooze) await _plugin.cancel(id: r.id);
    }
    final now = tz.TZDateTime.now(tz.local);
    for (final pill in store.pills) {
      final details = _details(store, pill);

      var next = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, pill.hour, pill.minute);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: pill.id * 10,
        scheduledDate: next,
        notificationDetails: details,
        androidScheduleMode: _mode,
        title: _title(store),
        body: _body(pill),
        payload: '${pill.id}',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      for (var d = 0; d < 2; d++) {
        final day = DateTime(now.year, now.month, now.day + d);
        if (store.isTaken(pill.id, day)) continue;
        for (var k = 0; k < followUpMinutes.length; k++) {
          final at = tz.TZDateTime(tz.local, day.year, day.month, day.day,
                  pill.hour, pill.minute)
              .add(Duration(minutes: followUpMinutes[k]));
          if (!at.isAfter(now)) continue;
          await _plugin.zonedSchedule(
            id: pill.id * 10 + 1 + d * 2 + k,
            scheduledDate: at,
            notificationDetails: details,
            androidScheduleMode: _mode,
            title: 'یادتان نرود: ${_title(store)}',
            body: _body(pill),
            payload: '${pill.id}|${dayKey(day)}',
          );
        }
      }
    }
  }

  /// Called after «خوردم»: drops a pending snooze and today's follow-ups.
  Future<void> doseTaken(Store store, Pill pill) async {
    if (!enabled) return;
    await _plugin.cancel(id: pill.id * 10 + 9);
    await rescheduleAll(store);
  }

  /// One extra reminder in [snoozeMinutes] minutes.
  Future<void> snooze(Store store, Pill pill, DateTime day) async {
    if (!enabled) return;
    await _plugin.zonedSchedule(
      id: pill.id * 10 + 9,
      scheduledDate:
          tz.TZDateTime.now(tz.local).add(const Duration(minutes: snoozeMinutes)),
      notificationDetails: _details(store, pill),
      androidScheduleMode: _mode,
      title: _title(store),
      body: _body(pill),
      payload: '${pill.id}|${dayKey(day)}',
    );
  }

  /// Shows a reminder right away so the family can hear how it sounds.
  Future<void> test(Store store, Pill pill) async {
    if (!enabled) return;
    await _plugin.zonedSchedule(
      id: 9999,
      scheduledDate:
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      notificationDetails: _details(store, pill),
      androidScheduleMode: _mode,
      title: _title(store),
      body: _body(pill),
      payload: '${pill.id}|${dayKey(DateTime.now())}',
    );
  }
}
