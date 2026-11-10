import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'formatting.dart';
import 'position.dart';

/// 本地到价/复盘提醒：只在设备本地排期通知，不连接行情接口。
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: initSettings);

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  int _notificationId(String positionId) => positionId.hashCode & 0x7fffffff;

  /// 根据持仓当前的提醒时间同步本地通知：已设置则排期，未设置则取消。
  Future<void> sync(Position position) async {
    await init();
    final id = _notificationId(position.id);
    final reminderAt = position.reminderAt;
    if (reminderAt == null) {
      await _plugin.cancel(id: id);
      return;
    }
    final when = tz.TZDateTime.from(reminderAt, tz.local);
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;

    final label = position.name.isEmpty ? 'your position' : position.name;
    final avg = position.averageCost > 0
        ? 'avg cost \$${Format.price(position.averageCost)}'
        : 'your position';
    final targets = <String>[];
    if (position.takeProfitTarget != null) {
      targets.add('TP \$${Format.price(position.takeProfitTarget!)}');
    }
    if (position.stopLossTarget != null) {
      targets.add('SL \$${Format.price(position.stopLossTarget!)}');
    }
    final body = targets.isEmpty
        ? 'Review $label ($avg).'
        : 'Review $label ($avg; ${targets.join(', ')}).';

    await _plugin.zonedSchedule(
      id: id,
      title: 'Position review: $label',
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'positions',
          'Position reminders',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(String positionId) async {
    await init();
    await _plugin.cancel(id: _notificationId(positionId));
  }
}
