// lib/state/notifications.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around `flutter_local_notifications` for the single
/// "your Digimon misses you" care reminder. No game state is read or
/// mutated here.
class Notifications {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const int _needsYouId = 1;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleNeedsYou() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'care',
        'Care reminders',
        channelDescription: 'Reminders that your Digimon needs attention',
        importance: Importance.defaultImportance,
      ),
    );
    await _plugin.show(
      id: _needsYouId,
      title: 'Your Digimon misses you',
      body: 'Come back and check on it!',
      notificationDetails: details,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
