import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/core/utils/formatters.dart';

void main() {
  final now = DateTime(2026, 11, 8, 10);

  group('countdown (PRD 8.6)', () {
    test('hari ini', () {
      expect(Fmt.countdown(DateTime(2026, 11, 8, 14, 30), now),
          'Hari ini, 14:30');
    });
    test('besok', () {
      expect(Fmt.countdown(DateTime(2026, 11, 9, 9), now), 'Besok, 09:00');
    });
    test('2 sampai 30 hari', () {
      expect(Fmt.countdown(DateTime(2026, 11, 10, 9), now), '2 hari lagi');
      expect(Fmt.countdown(DateTime(2026, 12, 8, 9), now), '30 hari lagi');
    });
    test('lebih dari 30 hari memakai tanggal lengkap', () {
      expect(Fmt.countdown(DateTime(2026, 12, 9, 9), now), '9 Des 2026');
    });
    test('selisih dihitung per tanggal kalender, bukan per 24 jam', () {
      final late = DateTime(2026, 11, 8, 23, 50);
      expect(Fmt.countdown(DateTime(2026, 11, 9, 0, 10), late),
          'Besok, 00:10');
    });
  });

  group('kepatuhan (PRD 8.2)', () {
    test('pembulatan ke bilangan bulat terdekat', () {
      expect(Fmt.adherencePercent(taken: 102, due: 115), 89);
      expect(Fmt.adherencePercent(taken: 1, due: 3), 33);
      expect(Fmt.adherencePercent(taken: 2, due: 3), 67);
    });
    test('tanpa dosis jatuh tempo ditampilkan strip, bukan 0 persen', () {
      expect(Fmt.adherencePercent(taken: 0, due: 0), isNull);
      expect(Fmt.adherenceLabel(taken: 0, due: 0), '–');
      expect(Fmt.adherenceLabel(taken: 102, due: 115), '89%');
    });
  });

  test('format tanggal dan jam (NFR-08)', () {
    expect(Fmt.date(DateTime(2026, 11, 8)), '8 Nov 2026');
    expect(Fmt.time(DateTime(2026, 11, 8, 7, 5)), '07:05');
  });
}
