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

  Future<void> reschedule() async {
    final profile = await profileRepository.fetchMine();
    if (profile == null) return;

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
  }
}
