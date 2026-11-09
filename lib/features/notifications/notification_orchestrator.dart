import 'package:shared_preferences/shared_preferences.dart';

import '../../features/appointment/data/appointment_repository.dart';
import '../../features/home/data/profile_repository.dart';
import '../../features/medication/data/doses_repository.dart';
import 'notification_service.dart';

class NotificationOrchestrator {
  NotificationOrchestrator({
    required this.profileRepository,
    required this.dosesRepository,
    required this.appointmentRepository,
    required this.notificationService,
  });

  final ProfileRepository profileRepository;
  final DosesRepository dosesRepository;
  final AppointmentRepository appointmentRepository;
  final NotificationService notificationService;

  Future<void> _queue = Future<void>.value();

  /// Penjadwalan ulang diantrikan agar dua pemanggilan bersamaan (misalnya
  /// dari Beranda dan dari permintaan izin) tidak saling membatalkan.
  /// Kegagalan dicatat di log dan tidak mengganggu pemanggil.
  Future<void> reschedule() {
    final next = _queue.then((_) => _run());
    _queue = next;
    return next;
  }

  Future<void> _run() async {
    try {
      notifLog('reschedule() dimulai');
      final profile = await profileRepository.fetchMine();
      if (profile == null) {
        notifLog('reschedule dibatalkan: belum login / profil kosong');
        return;
      }

      await dosesRepository.ensureDoses();
      final doses = await dosesRepository.fetchPendingAhead();
      final appointments = await appointmentRepository.fetchUpcomingAhead();
      final prefs = await SharedPreferences.getInstance();

      await notificationService.rescheduleAll(
        doses: doses,
        appointments: appointments,
        timezoneName: profile.timezone,
        medicationEnabled: prefs.getBool('medication_reminder') ?? true,
        appointmentEnabled: prefs.getBool('appointment_reminder') ?? true,
      );
    } on Object catch (e, st) {
      notifLog('reschedule GAGAL: $e\n$st');
    }
  }
}
