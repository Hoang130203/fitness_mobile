import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/models.dart';

/// All reminders are local notifications — nothing leaves the device.
/// No-op on web (plugin unsupported), guards via kIsWeb.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> sync(AppSettings s) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      if (s.mealReminders) {
        await _schedule(1, 'Log lunch?', 'Tap + → Food to record', 12, 30);
        await _schedule(2, 'Log dinner?', 'Tap + → Food to record', 19, 30);
      }
      if (s.weightReminder) {
        await _schedule(3, 'Morning weigh-in', 'Tap + → Weight', 7, 30);
      }
      if (s.workoutReminder) {
        await _schedule(4, 'Workout today?', 'Tap + → Workout', 18, 0);
      }
    } catch (_) {}
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    int hour,
    int minute,
  ) async {
    await _plugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
