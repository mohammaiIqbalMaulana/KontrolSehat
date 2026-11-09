import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/appointment/data/appointment_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/bp/data/bp_repository.dart';
import '../../features/home/data/profile_repository.dart';
import '../../features/medication/data/doses_repository.dart';
import '../../features/medication/data/medication_repository.dart';
import '../../features/notifications/notification_orchestrator.dart';
import '../../features/notifications/notification_service.dart';
import '../../features/stats/data/stats_repository.dart';

/// Penyedia repository tunggal. Diisi sekali di `main` setelah Supabase
/// siap. Halaman membaca dari sini; controller menerima repository lewat
/// konstruktor agar mudah diuji.
abstract final class Services {
  static late final AuthRepository auth;
  static late final ProfileRepository profiles;
  static late final DosesRepository doses;
  static late final MedicationRepository medications;
  static late final AppointmentRepository appointments;
  static late final BpRepository bp;
  static late final StatsRepository stats;
  static late final NotificationOrchestrator notifications;

  static void init(SupabaseClient client) {
    auth = AuthRepository(client);
    profiles = ProfileRepository(client);
    doses = DosesRepository(client);
    medications = MedicationRepository(client);
    appointments = AppointmentRepository(client);
    bp = BpRepository(client);
    stats = StatsRepository(client);
    notifications = NotificationOrchestrator(
      profileRepository: profiles,
      dosesRepository: doses,
      appointmentRepository: appointments,
      notificationService: NotificationService.instance,
    );
  }
}
