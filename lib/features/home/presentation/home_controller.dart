import 'package:flutter/foundation.dart';

import '../../../core/errors/error_mapper.dart';
import '../../appointment/data/appointment_model.dart';
import '../../appointment/data/appointment_repository.dart';
import '../../bp/data/bp_model.dart';
import '../../bp/data/bp_repository.dart';
import '../../medication/data/doses_repository.dart';
import '../../medication/data/medication_models.dart';
import '../data/profile_repository.dart';

enum HomeStatus { loading, ready, failed }

/// Memuat data Beranda. Urutan wajib: `ensure_doses` dulu, baru data
/// lain dibaca (FR-207).
class HomeController extends ChangeNotifier {
  HomeController({
    required this.profiles,
    required this.doses,
    required this.bp,
    required this.appointments,
    this.rescheduleNotifications,
  });

  final ProfileRepository profiles;
  final DosesRepository doses;
  final BpRepository bp;
  final AppointmentRepository appointments;
  final Future<void> Function()? rescheduleNotifications;

  HomeStatus _status = HomeStatus.loading;
  Profile? _profile;
  List<MedicationLog> _todayDoses = <MedicationLog>[];
  BpRecord? _latestBp;
  Appointment? _nearestAppointment;
  String? _error;

  HomeStatus get status => _status;
  Profile? get profile => _profile;
  List<MedicationLog> get todayDoses => _todayDoses;
  BpRecord? get latestBp => _latestBp;
  Appointment? get nearestAppointment => _nearestAppointment;
  String? get error => _error;

  /// Dosis berikutnya: dosis hari ini yang belum dicatat dengan jam paling awal (FR-202).
  MedicationLog? get nextDose {
    final pending = _todayDoses.where((d) => d.status == 'pending').toList();
    if (pending.isEmpty) return null;
    pending.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return pending.first;
  }

  /// Ring progres: dosis taken hari ini / seluruh dosis hari ini (PRD 8.2).
  int get takenCount => _todayDoses.where((d) => d.status == 'taken').length;
  int get totalTodayCount => _todayDoses.length;
  int get progressPercent =>
      totalTodayCount == 0 ? 0 : (takenCount * 100 / totalTodayCount).round();

  Future<void> load() async {
    _status = HomeStatus.loading;
    _error = null;
    notifyListeners();
    try {
      await doses.ensureDoses();
      final results = await Future.wait<Object?>([
        profiles.fetchMine(),
        doses.fetchToday(),
        bp.fetchLatest(),
        appointments.fetchNearest(),
      ]);
      _profile = results[0] as Profile?;
      _todayDoses = results[1] as List<MedicationLog>;
      _latestBp = results[2] as BpRecord?;
      _nearestAppointment = results[3] as Appointment?;
      await rescheduleNotifications?.call();
      _status = HomeStatus.ready;
    } on Object catch (e) {
      _error = ErrorMapper.message(e);
      _status = HomeStatus.failed;
    }
    notifyListeners();
  }

  Future<void> markDose(MedicationLog dose, String newStatus) async {
    try {
      await doses.updateStatus(id: dose.id, status: newStatus);
      await rescheduleNotifications?.call();
      await load();
    } on Object catch (e) {
      _error = ErrorMapper.message(e);
      notifyListeners();
    }
  }
}
