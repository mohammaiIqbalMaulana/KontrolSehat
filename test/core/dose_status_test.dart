import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/core/utils/dose_status.dart';

void main() {
  group('DoseStatus evaluation (PRD 8.1)', () {
    final today10am = DateTime(2026, 11, 8, 10, 0);

    test('rawStatus taken menghasilkan DoseStatus.taken', () {
      final status = evaluateDoseStatus(
        rawStatus: 'taken',
        scheduledAt: today10am,
        now: today10am,
      );
      expect(status, DoseStatus.taken);
      expect(status.canAction, isFalse);
    });

    test('rawStatus skipped menghasilkan DoseStatus.skipped', () {
      final status = evaluateDoseStatus(
        rawStatus: 'skipped',
        scheduledAt: today10am,
        now: today10am,
      );
      expect(status, DoseStatus.skipped);
      expect(status.canAction, isFalse);
    });

    test('Tanggal kemarin menghasilkan DoseStatus.missed (Terlewat)', () {
      final yesterday = DateTime(2026, 11, 7, 10, 0);
      final status = evaluateDoseStatus(
        rawStatus: 'pending',
        scheduledAt: yesterday,
        now: today10am,
      );
      expect(status, DoseStatus.missed);
      expect(status.label, 'Terlewat');
      expect(status.canAction, isFalse);
    });

    test('Lebih awal dari 60 menit sebelum jadwal -> Belum waktunya', () {
      final now8am = DateTime(2026, 11, 8, 8, 59); // 61 menit sebelum 10:00
      final status = evaluateDoseStatus(
        rawStatus: 'pending',
        scheduledAt: today10am,
        now: now8am,
      );
      expect(status, DoseStatus.notYetTime);
      expect(status.label, 'Belum waktunya');
      expect(status.canAction, isFalse);
    });

    test('Tepat 60 menit sebelum jadwal -> Waktunya minum (aktif)', () {
      final now9am = DateTime(
        2026,
        11,
        8,
        9,
        0,
      ); // tepat 60 menit sebelum 10:00
      final status = evaluateDoseStatus(
        rawStatus: 'pending',
        scheduledAt: today10am,
        now: now9am,
      );
      expect(status, DoseStatus.timeToTake);
      expect(status.label, 'Waktunya minum');
      expect(status.canAction, isTrue);
    });

    test('Antara 60m sebelum dan 120m sesudah -> Waktunya minum (aktif)', () {
      final now11am = DateTime(2026, 11, 8, 11, 0); // 60 menit sesudah 10:00
      final status = evaluateDoseStatus(
        rawStatus: 'pending',
        scheduledAt: today10am,
        now: now11am,
      );
      expect(status, DoseStatus.timeToTake);
      expect(status.canAction, isTrue);
    });

    test('Lewat 120 menit pada hari yang sama -> Terlambat (aktif)', () {
      final now1pm = DateTime(2026, 11, 8, 13, 0); // 180 menit sesudah 10:00
      final status = evaluateDoseStatus(
        rawStatus: 'pending',
        scheduledAt: today10am,
        now: now1pm,
      );
      expect(status, DoseStatus.late);
      expect(status.label, 'Terlambat');
      expect(status.canAction, isTrue);
    });
  });
}
