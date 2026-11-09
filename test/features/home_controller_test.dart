import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/features/appointment/data/appointment_model.dart';
import 'package:kontrol_sehat/features/appointment/data/appointment_repository.dart';
import 'package:kontrol_sehat/features/bp/data/bp_model.dart';
import 'package:kontrol_sehat/features/bp/data/bp_repository.dart';
import 'package:kontrol_sehat/features/home/data/profile_repository.dart';
import 'package:kontrol_sehat/features/home/presentation/home_controller.dart';
import 'package:kontrol_sehat/features/medication/data/doses_repository.dart';
import 'package:kontrol_sehat/features/medication/data/medication_models.dart';

class FakeProfileRepo implements ProfileRepository {
  @override
  Future<Profile?> fetchMine() async => const Profile(
    id: 'user-1',
    fullName: 'Iqbal Maulana',
    birthYear: 1995,
    timezone: 'Asia/Jakarta',
  );

  @override
  Future<void> updateMine({
    required String fullName,
    required int birthYear,
  }) async {}
}

class FakeDosesRepo implements DosesRepository {
  List<MedicationLog> list = <MedicationLog>[
    MedicationLog(
      id: 'log-1',
      medicationId: 'med-1',
      medicationName: 'Amlodipine',
      dosage: '5 mg',
      scheduledAt: DateTime(2026, 11, 8, 8, 0),
      status: 'taken',
    ),
    MedicationLog(
      id: 'log-2',
      medicationId: 'med-2',
      medicationName: 'Captopril',
      dosage: '25 mg',
      scheduledAt: DateTime(2026, 11, 8, 20, 0),
      status: 'pending',
    ),
  ];

  @override
  Future<void> ensureDoses({int daysAhead = 7}) async {}

  @override
  Future<List<MedicationLog>> fetchToday() async => list;

  @override
  Future<MedicationLog> updateStatus({
    required String id,
    required String status,
  }) async {
    final idx = list.indexWhere((l) => l.id == id);
    final updated = MedicationLog(
      id: list[idx].id,
      medicationId: list[idx].medicationId,
      medicationName: list[idx].medicationName,
      dosage: list[idx].dosage,
      scheduledAt: list[idx].scheduledAt,
      status: status,
    );
    list[idx] = updated;
    return updated;
  }
}

class FakeBpRepo implements BpRepository {
  @override
  Future<BpRecord?> fetchLatest() async => null;

  @override
  Future<List<BpRecord>> fetchHistory({DateTime? since}) async => <BpRecord>[];

  @override
  Future<void> delete(String id) async {}

  @override
  Future<BpRecord> create({
    required int systolic,
    required int diastolic,
    required int? pulse,
    required DateTime measuredAt,
    required String? note,
  }) {
    throw UnimplementedError();
  }
}

class FakeAppointmentRepo implements AppointmentRepository {
  @override
  Future<Appointment?> fetchNearest() async => null;

  @override
  Future<List<Appointment>> fetchAll() async => <Appointment>[];

  @override
  Future<Appointment> create({
    required String title,
    required String facility,
    required String? doctor,
    required DateTime scheduledAt,
    required String? notes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateStatus(String id, String status) async {}

  @override
  Future<void> delete(String id) async {}
}

void main() {
  group('HomeController test with handwritten fake repositories', () {
    test(
      'load() mengisi profile dan menghitung progres dosis dengan benar',
      () async {
        final controller = HomeController(
          profiles: FakeProfileRepo(),
          doses: FakeDosesRepo(),
          bp: FakeBpRepo(),
          appointments: FakeAppointmentRepo(),
        );

        expect(controller.status, HomeStatus.loading);
        await controller.load();
        expect(controller.status, HomeStatus.ready);
        expect(controller.profile?.firstName, 'Iqbal');
        expect(controller.totalTodayCount, 2);
        expect(controller.takenCount, 1);
        expect(controller.progressPercent, 50);
        expect(controller.nextDose?.medicationName, 'Captopril');
      },
    );
  });
}
