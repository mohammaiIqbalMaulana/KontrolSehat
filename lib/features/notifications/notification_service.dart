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

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notifGranted =
        await androidImpl?.requestNotificationsPermission() ?? false;
    final exactAlarmGranted =
        await androidImpl?.requestExactAlarmsPermission() ?? false;
    return notifGranted && exactAlarmGranted;
  }

  /// Membatalkan seluruh notifikasi (FR-104 saat logout).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Membatalkan notifikasi untuk satu dosis tertentu (FR-904).
  Future<void> cancelDose(String doseId) async {
    await _plugin.cancel(id: doseId.hashCode);
  }

  /// Menjadwalkan pengingat minum obat 7 hari ke depan (FR-901, FR-903).
  Future<void> scheduleDose({
    required String doseId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledAt,
    required String timezoneName,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return;

    final location = tz.getLocation(timezoneName);
    final tzScheduled = tz.TZDateTime.from(scheduledAt, location);

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Pengingat Obat',
      channelDescription: 'Notifikasi jadwal minum obat harian',
      importance: Importance.max,
      priority: Priority.high,
      visibility:
          NotificationVisibility.private, // SEC-09: privat di lockscreen
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id: doseId.hashCode,
      title: 'Waktunya minum obat', // Judul publik / umum
      body: '$medicationName, $dosage', // Isi spesifik (terlihat saat unlock)
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Menjadwalkan pengingat kontrol (FR-902): H-1 jam 18:00 dan 2 jam sebelum jadwal.
  Future<void> scheduleAppointment({
    required Appointment appointment,
    required String timezoneName,
  }) async {
    final now = DateTime.now();
    final location = tz.getLocation(timezoneName);

    // 1. Notifikasi H-1 jam 18:00
    final hMinus1 = appointment.scheduledAt.subtract(const Duration(days: 1));
    final hMinus1Evening = DateTime(
      hMinus1.year,
      hMinus1.month,
      hMinus1.day,
      18,
      0,
    );

    if (hMinus1Evening.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: '${appointment.id}_h1'.hashCode,
        title: 'Pengingat Kontrol Besok',
        body: 'Jadwal kontrol di ${appointment.facility} besok',
        scheduledDate: tz.TZDateTime.from(hMinus1Evening, location),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Pengingat Kontrol',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    // 2. Notifikasi 2 jam sebelum jadwal kontrol
    final twoHoursBefore = appointment.scheduledAt.subtract(
      const Duration(hours: 2),
    );
    if (twoHoursBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: '${appointment.id}_2h'.hashCode,
        title: 'Pengingat Jadwal Kontrol',
        body: '2 jam lagi: kontrol di ${appointment.facility}',
        scheduledDate: tz.TZDateTime.from(twoHoursBefore, location),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Pengingat Kontrol',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  /// Menjadwalkan ulang seluruh dosis aktif dan jadwal kontrol (FR-903).
  Future<void> rescheduleAll({
    required List<MedicationLog> doses,
    required List<Appointment> appointments,
    required String timezoneName,
  }) async {
    await cancelAll();
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
    for (final appt in appointments) {
      if (appt.status == 'upcoming' && !appt.isPast) {
        await scheduleAppointment(
          appointment: appt,
          timezoneName: timezoneName,
        );
      }
    }
  }
}
