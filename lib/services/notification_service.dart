import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'language_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const _mealEnabledKey = 'notif_meal_enabled';
  static const _mealHourKey = 'notif_meal_hour';
  static const _mealMinuteKey = 'notif_meal_minute';

  static const _waterEnabledKey = 'notif_water_enabled';
  static const _waterHourKey = 'notif_water_hour';
  static const _waterMinuteKey = 'notif_water_minute';

  static const int mealNotifId = 101;
  static const int waterNotifId = 102;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize timezone database
    tz.initializeTimeZones();

    // 2. Set the actual local device timezone
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not set local timezone: $e');
    }

    // 3. Android Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/app_notification_icon');

    // 4. Darwin / iOS Initialization Settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 5. Create Android Notification Channels explicitly with sound & popup
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      const AndroidNotificationChannel mealChannel = AndroidNotificationChannel(
        'fitlyfe_daily_meal_v2',
        'Daily Meal Reminder',
        description: 'Reminds you to log your meals and hit daily macro targets',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel waterChannel = AndroidNotificationChannel(
        'fitlyfe_daily_water_v2',
        'Daily Hydration Reminder',
        description: 'Reminds you to stay hydrated and log water intake',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidPlugin?.createNotificationChannel(mealChannel);
      await androidPlugin?.createNotificationChannel(waterChannel);
    }

    _initialized = true;

    // Reschedule on app launch based on saved settings
    await rescheduleAll();
  }

  /// Request permissions (Android 13+ and iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      // On Android 12+ (API 31+), check exact alarms permission
      await androidPlugin?.requestExactAlarmsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Show an instant test notification (useful to confirm notifications work on device)
  Future<void> showTestNotification(String title, String body) async {
    await init();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fitlyfe_daily_meal_v2',
      'Daily Meal Reminder',
      channelDescription: 'Reminds you to log your meals and hit daily macro targets',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/app_notification_icon',
      largeIcon: DrawableResourceAndroidBitmap('@drawable/app_notification_icon'),
      color: Color(0xFF8B5CF6),
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      999,
      title,
      body,
      details,
    );
  }

  // ── Preferences Getters & Setters ──

  Future<bool> isMealReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mealEnabledKey) ?? true; // Default ON
  }

  Future<TimeOfDay> getMealReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_mealHourKey) ?? 20; // Default 8:00 PM
    final minute = prefs.getInt(_mealMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setMealReminder({required bool enabled, TimeOfDay? time}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mealEnabledKey, enabled);
    if (time != null) {
      await prefs.setInt(_mealHourKey, time.hour);
      await prefs.setInt(_mealMinuteKey, time.minute);
    }
    await rescheduleAll();
  }

  Future<bool> isWaterReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_waterEnabledKey) ?? true; // Default ON
  }

  Future<TimeOfDay> getWaterReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_waterHourKey) ?? 14; // Default 2:00 PM
    final minute = prefs.getInt(_waterMinuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setWaterReminder({required bool enabled, TimeOfDay? time}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_waterEnabledKey, enabled);
    if (time != null) {
      await prefs.setInt(_waterHourKey, time.hour);
      await prefs.setInt(_waterMinuteKey, time.minute);
    }
    await rescheduleAll();
  }

  // ── Scheduling Logic ──

  Future<void> rescheduleAll([String? langCode]) async {
    await init();

    final prefs = await SharedPreferences.getInstance();
    final effectiveLang = langCode ?? prefs.getString('app_language') ?? 'en';

    // 1. Meal Reminder
    final mealEnabled = prefs.getBool(_mealEnabledKey) ?? true;
    final mealHour = prefs.getInt(_mealHourKey) ?? 20;
    final mealMinute = prefs.getInt(_mealMinuteKey) ?? 0;

    if (mealEnabled) {
      await _scheduleDailyNotification(
        id: mealNotifId,
        channelId: 'fitlyfe_daily_meal_v2',
        channelName: 'Daily Meal Reminder',
        channelDesc: 'Reminds you to log your meals and hit daily macro targets',
        title: AppTranslations.translate('meal_notif_title', effectiveLang),
        body: AppTranslations.translate('meal_notif_body', effectiveLang),
        time: TimeOfDay(hour: mealHour, minute: mealMinute),
      );
    } else {
      await _notificationsPlugin.cancel(mealNotifId);
    }

    // 2. Water Reminder
    final waterEnabled = prefs.getBool(_waterEnabledKey) ?? true;
    final waterHour = prefs.getInt(_waterHourKey) ?? 14;
    final waterMinute = prefs.getInt(_waterMinuteKey) ?? 0;

    if (waterEnabled) {
      await _scheduleDailyNotification(
        id: waterNotifId,
        channelId: 'fitlyfe_daily_water_v2',
        channelName: 'Daily Hydration Reminder',
        channelDesc: 'Reminds you to stay hydrated and log water intake',
        title: AppTranslations.translate('water_notif_title', effectiveLang),
        body: AppTranslations.translate('water_notif_body', effectiveLang),
        time: TimeOfDay(hour: waterHour, minute: waterMinute),
      );
    } else {
      await _notificationsPlugin.cancel(waterNotifId);
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final scheduledDate = _nextInstanceOfTime(time);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/app_notification_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@drawable/app_notification_icon'),
      color: channelId.contains('water')
          ? const Color(0xFF0EA5E9)
          : const Color(0xFF8B5CF6),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cancel existing alarm with this ID before rescheduling
    await _notificationsPlugin.cancel(id);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
    );

    // If the scheduled time has already passed for today (or is right now), schedule for tomorrow
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
