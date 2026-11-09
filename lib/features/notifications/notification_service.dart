import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../appointment/data/appointment_model.dart';
import '../medication/data/medication_models.dart';

/// Log debug notifikasi. Muncul di terminal `flutter run` dengan awalan
/// `[NOTIF]`. Hanya aktif di mode debug (SEC-08: data kesehatan tidak boleh
/// ditulis ke log pada versi rilis).
void notifLog(String message) {
  if (kDebugMode) debugPrint('[NOTIF] $message');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// ID khusus uji coba; tidak ikut dibatalkan oleh penjadwalan ulang.
  static const int testNowId = 999001;
  static const int testScheduledId = 999002;
  static const Set<int> _testIds = <int>{testNowId, testScheduledId};

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _exactAlarmAllowed = false;
  bool _notificationsEnabled = false;

  /// id notifikasi -> keterangan & waktu, hanya untuk keperluan log/debug.
  final Map<int, String> _debugInfo = <int, String>{};

  bool get exactAlarmAllowed => _exactAlarmAllowed;
  bool get notificationsEnabled => _notificationsEnabled;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (response) =>
          notifLog('TAP notifikasi id=${response.id}'),
    );
    _initialized = true;
    notifLog('init selesai');
    await refreshPermissionState();
  }

  /// Membaca status izin saat ini dari sistem (tanpa menampilkan dialog).
  Future<void> refreshPermissionState() async {
    final android = _android;
    _notificationsEnabled = await android?.areNotificationsEnabled() ?? false;
    _exactAlarmAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    notifLog(
      'izin: notifikasi=${_notificationsEnabled ? "AKTIF" : "MATI"}, '
      'alarm tepat waktu=${_exactAlarmAllowed ? "AKTIF" : "MATI (inexact)"}',
    );
  }

  /// Meminta izin notifikasi (Android 13+) dan alarm tepat waktu. Dialog
  /// sistem hanya muncul bila izin belum diberikan. Halaman pengaturan alarm
  /// hanya dibuka satu kali agar pengguna tidak terus diganggu.
  Future<bool> requestPermissions() async {
    final android = _android;
    await refreshPermissionState();

    if (!_notificationsEnabled) {
      notifLog('meminta izin notifikasi...');
      await android?.requestNotificationsPermission();
    }

    final prefs = await SharedPreferences.getInstance();
    await refreshPermissionState();
    if (!_exactAlarmAllowed && !(prefs.getBool('exact_alarm_asked') ?? false)) {
      await prefs.setBool('exact_alarm_asked', true);
      notifLog('meminta izin alarm tepat waktu (membuka pengaturan sistem)...');
      await android?.requestExactAlarmsPermission();
    }

    await refreshPermissionState();
    return _notificationsEnabled && _exactAlarmAllowed;
  }

  Future<void> cancelAll() async {
    notifLog('cancelAll()');
    _debugInfo.clear();
    await _plugin.cancelAll();
  }

  /// Membatalkan semua notifikasi terjadwal kecuali notifikasi uji coba.
  Future<void> _cancelAllExceptTests() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (_testIds.contains(request.id)) continue;
      await _plugin.cancel(id: request.id);
      _debugInfo.remove(request.id);
    }
  }

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

  /// Menjadwalkan satu dosis. Mengembalikan `true` bila benar-benar
  /// didaftarkan ke sistem.
  Future<bool> scheduleDose({
    required String doseId,
    required String medicationName,
    required String dosage,
    required DateTime scheduledAt,
    required String timezoneName,
  }) async {
    final location = tz.getLocation(timezoneName);
    final scheduled = tz.TZDateTime.from(scheduledAt.toUtc(), location);
    final now = tz.TZDateTime.now(location);
    final id = doseNotificationId(doseId);
    if (!scheduled.isAfter(now)) {
      notifLog(
        'SKIP dosis "$medicationName" $scheduled: waktunya sudah lewat '
        '(sekarang $now)',
      );
      return false;
    }
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
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Waktunya minum obat',
        body: '$medicationName, $dosage',
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: _scheduleMode,
      );
      final minutes = scheduled.difference(now).inMinutes;
      _debugInfo[id] = 'dosis "$medicationName" @ $scheduled';
      notifLog(
        'TERJADWAL dosis "$medicationName" id=$id pada $scheduled '
        '(${minutes}m lagi) mode=${_scheduleMode.name}',
      );
      return true;
    } on Object catch (e, st) {
      notifLog('GAGAL menjadwalkan dosis "$medicationName" id=$id: $e\n$st');
      return false;
    }
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
    final now = tz.TZDateTime.now(location);
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
    Future<void> schedule(String kind, tz.TZDateTime at, String body) async {
      final id = appointmentNotificationId(appointment.id, kind);
      if (!at.isAfter(now)) {
        notifLog('SKIP kontrol $kind $at: waktunya sudah lewat');
        return;
      }
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: 'Pengingat kontrol',
          body: body,
          scheduledDate: at,
          notificationDetails: details,
          androidScheduleMode: _scheduleMode,
        );
        _debugInfo[id] = 'kontrol $kind @ $at';
        notifLog(
          'TERJADWAL kontrol $kind id=$id pada $at '
          '(${at.difference(now).inMinutes}m lagi) mode=${_scheduleMode.name}',
        );
      } on Object catch (e, st) {
        notifLog('GAGAL menjadwalkan kontrol $kind id=$id: $e\n$st');
      }
    }

    await schedule('h1', h1, 'Jadwal kontrol besok');
    await schedule('2h', twoHours, 'Jadwal kontrol dalam 2 jam');
  }

  Future<void> rescheduleAll({
    required List<MedicationLog> doses,
    required List<Appointment> appointments,
    required String timezoneName,
    bool medicationEnabled = true,
    bool appointmentEnabled = true,
  }) async {
    await refreshPermissionState();
    notifLog(
      'rescheduleAll: ${doses.length} dosis, ${appointments.length} kontrol, '
      'zona=$timezoneName, pengingatObat=$medicationEnabled, '
      'pengingatKontrol=$appointmentEnabled',
    );
    if (!_notificationsEnabled) {
      notifLog(
        'PERINGATAN: izin notifikasi MATI. Jadwal dibuat tetapi notifikasi '
        'TIDAK akan tampil sampai izin diaktifkan.',
      );
    }
    await _cancelAllExceptTests();

    var scheduledDoses = 0;
    if (medicationEnabled) {
      for (final dose in doses) {
        if (dose.status == 'pending') {
          final ok = await scheduleDose(
            doseId: dose.id,
            medicationName: dose.medicationName,
            dosage: dose.dosage,
            scheduledAt: dose.scheduledAt,
            timezoneName: timezoneName,
          );
          if (ok) scheduledDoses++;
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

    final pending = await _plugin.pendingNotificationRequests();
    notifLog(
      'SELESAI: $scheduledDoses dosis dijadwalkan, '
      '${pending.length} notifikasi pending di sistem',
    );
  }

  // ---------------------------------------------------------------------
  // Alat uji coba (dipakai halaman Profil > Uji notifikasi)
  // ---------------------------------------------------------------------

  static const NotificationDetails _testDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'medication_reminders',
      'Pengingat Obat',
      channelDescription: 'Notifikasi jadwal minum obat',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  /// Menampilkan notifikasi detik ini juga (menguji izin & channel).
  Future<String> showTestNow() async {
    await refreshPermissionState();
    await _plugin.show(
      id: testNowId,
      title: 'Tes notifikasi',
      body: 'Jika ini muncul, izin & channel notifikasi sudah benar.',
      notificationDetails: _testDetails,
    );
    notifLog('TES tampil sekarang dikirim (id=$testNowId)');
    return 'Notifikasi tes dikirim. Cek bilah notifikasi.';
  }

  /// Menjadwalkan notifikasi tes [after] dari sekarang (menguji alarm).
  Future<String> scheduleTest({
    Duration after = const Duration(minutes: 1),
  }) async {
    await refreshPermissionState();
    final at = tz.TZDateTime.now(tz.UTC).add(after);
    await _plugin.zonedSchedule(
      id: testScheduledId,
      title: 'Tes notifikasi terjadwal',
      body: 'Jika ini muncul tepat waktu, alarm terjadwal berfungsi.',
      scheduledDate: at,
      notificationDetails: _testDetails,
      androidScheduleMode: _scheduleMode,
    );
    _debugInfo[testScheduledId] = 'TES terjadwal @ $at';
    notifLog(
      'TES terjadwal id=$testScheduledId pada $at '
      '(${after.inSeconds}s lagi) mode=${_scheduleMode.name}',
    );
    return 'Tes dijadwalkan ${after.inSeconds} detik lagi '
        '(mode ${_scheduleMode.name}). Tutup/biarkan app, lalu tunggu.';
  }

  /// Mencetak dan mengembalikan ringkasan status: izin, daftar notifikasi
  /// yang menunggu waktunya, dan notifikasi yang sedang tampil.
  Future<String> debugDump() async {
    await refreshPermissionState();
    final pending = await _plugin.pendingNotificationRequests();
    final active = await _android?.getActiveNotifications() ??
        const <ActiveNotification>[];
    final buffer = StringBuffer()
      ..writeln('Izin notifikasi : ${_notificationsEnabled ? "AKTIF" : "MATI"}')
      ..writeln(
        'Alarm tepat waktu: ${_exactAlarmAllowed ? "AKTIF" : "MATI (inexact)"}',
      )
      ..writeln('Pending di sistem: ${pending.length}');
    for (final p in pending) {
      buffer.writeln('  • id=${p.id} ${_debugInfo[p.id] ?? p.title ?? ""}');
    }
    buffer.writeln('Sedang tampil   : ${active.length}');
    for (final a in active) {
      buffer.writeln('  • id=${a.id} ${a.title ?? ""}');
    }
    final report = buffer.toString().trimRight();
    notifLog('--- DUMP ---\n$report\n------------');
    return report;
  }
}
