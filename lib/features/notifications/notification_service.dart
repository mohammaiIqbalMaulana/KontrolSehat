import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../appointment/data/appointment_model.dart';
import '../medication/data/medication_models.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _exactAlarmAllowed = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notification =
        await android?.requestNotificationsPermission() ?? false;
    _exactAlarmAllowed = await android?.requestExactAlarmsPermission() ?? false;
    return notification && _exactAlarmAllowed;
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancelDose(String doseId) =>
      _plugin.cancel(id: doseNotificationId(doseId));

  Future<void> cancelAppointment(String appointmentId) async {
    await _plugin.cancel(id: appointmentNotificationId(appointmentId, 'h1'));
    await _plugin.cancel(id: appointmentNotificationId(appointmentId, '2h'));
  }

  static int doseNotificationId(String id) => _stableId('dose:$id');

  static int appointmentNotificationId(String id, String kind) =>
      _stableId('appointment:$kind:$id');

  static int _stableId(String input) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  AndroidScheduleMode get _scheduleMode => _exactAlarmAllowed
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  Future<void> scheduleDose({
    required String doseId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledAt,
    required String timezoneName,
  }) async {
    final location = tz.getLocation(timezoneName);
    final scheduled = tz.TZDateTime.from(scheduledAt.toUtc(), location);
    if (!scheduled.isAfter(tz.TZDateTime.now(location))) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        'Pengingat Obat',
        channelDescription: 'Notifikasi jadwal minum obat',
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.private,
      ),
    );
    await _plugin.zonedSchedule(
      id: doseNotificationId(doseId),
      title: 'Waktunya minum obat',
      body: '$medicationName, $dosage',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: _scheduleMode,
    );
  }

  Future<void> scheduleAppointment({
    required Appointment appointment,
    required String timezoneName,
  }) async {
    final location = tz.getLocation(timezoneName);
    final scheduled = tz.TZDateTime.from(
      appointment.scheduledAt.toUtc(),
      location,
    );
    final h1 = tz.TZDateTime(
      location,
      scheduled.year,
      scheduled.month,
      scheduled.day - 1,
      18,
    );
    final twoHours = scheduled.subtract(const Duration(hours: 2));
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'appointment_reminders',
        'Pengingat Kontrol',
        channelDescription: 'Notifikasi jadwal kontrol',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.private,
      ),
    );
    if (h1.isAfter(tz.TZDateTime.now(location))) {
      await _plugin.zonedSchedule(
        id: appointmentNotificationId(appointment.id, 'h1'),
        title: 'Pengingat kontrol',
        body: 'Jadwal kontrol besok',
        scheduledDate: h1,
        notificationDetails: details,
        androidScheduleMode: _scheduleMode,
      );
    }
    if (twoHours.isAfter(tz.TZDateTime.now(location))) {
      await _plugin.zonedSchedule(
        id: appointmentNotificationId(appointment.id, '2h'),
        title: 'Pengingat kontrol',
        body: 'Jadwal kontrol dalam 2 jam',
        scheduledDate: twoHours,
        notificationDetails: details,
        androidScheduleMode: _scheduleMode,
      );
    }
  }

  Future<void> rescheduleAll({
    required List<MedicationLog> doses,
    required List<Appointment> appointments,
    required String timezoneName,
    bool medicationEnabled = true,
    bool appointmentEnabled = true,
  }) async {
    await cancelAll();
    if (medicationEnabled) {
      for (final dose in doses) {
        if (dose.status == 'pending') {
          await scheduleDose(
            doseId: dose.id,
            medicationName: dose.medicationName,
            dosage: dose.dosage,
            scheduledAt: dose.scheduledAt,
            timezoneName: timezoneName,
          );
        }
      }
    }
    if (appointmentEnabled) {
      for (final appointment in appointments) {
        if (appointment.status == 'upcoming' && !appointment.isPast) {
          await scheduleAppointment(
            appointment: appointment,
            timezoneName: timezoneName,
          );
        }
      }
    }
  }
}
