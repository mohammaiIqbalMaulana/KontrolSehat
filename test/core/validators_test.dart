import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/core/utils/validators.dart';

void main() {
  group('akun (PRD 10.1)', () {
    test('nama 2 sampai 50 karakter setelah trim', () {
      expect(Validators.fullName('A'), isNotNull);
      expect(Validators.fullName('  A  '), isNotNull);
      expect(Validators.fullName('Bu'), isNull);
      expect(Validators.fullName('a' * 50), isNull);
      expect(Validators.fullName('a' * 51), isNotNull);
    });

    test('tahun lahir 2026 berarti 1926 sampai 2008', () {
      expect(Validators.birthYear('1925', currentYear: 2026), isNotNull);
      expect(Validators.birthYear('1926', currentYear: 2026), isNull);
      expect(Validators.birthYear('2008', currentYear: 2026), isNull);
      expect(Validators.birthYear('2009', currentYear: 2026), isNotNull);
      expect(Validators.birthYear('abc', currentYear: 2026), isNotNull);
      expect(Validators.birthYear('', currentYear: 2026), isNotNull);
    });

    test('email', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('nama.pakai+tag@contoh.id'), isNull);
      expect(Validators.email('tanpa-at'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('${'a' * 250}@b.co'), isNotNull);
    });

    test('password registrasi: 8 karakter, huruf dan angka', () {
      expect(Validators.passwordRegister('Abcdef1'), isNotNull);
      expect(Validators.passwordRegister('abcdefgh'), isNotNull);
      expect(Validators.passwordRegister('12345678'), isNotNull);
      expect(Validators.passwordRegister('Abcdefg1'), isNull);
    });

    test('password login hanya wajib diisi', () {
      expect(Validators.passwordLogin(''), isNotNull);
      expect(Validators.passwordLogin('x'), isNull);
    });
  });

  group('tekanan darah (PRD 10.4)', () {
    test('sistolik 70 sampai 250', () {
      expect(Validators.systolic('69'), isNotNull);
      expect(Validators.systolic('70'), isNull);
      expect(Validators.systolic('250'), isNull);
      expect(Validators.systolic('251'), isNotNull);
      expect(Validators.systolic('1.5'), isNotNull);
    });

    test('diastolik 40 sampai 150', () {
      expect(Validators.diastolic('39'), isNotNull);
      expect(Validators.diastolic('40'), isNull);
      expect(Validators.diastolic('150'), isNull);
      expect(Validators.diastolic('151'), isNotNull);
    });

    test('nadi opsional, 30 sampai 200', () {
      expect(Validators.pulse(''), isNull);
      expect(Validators.pulse(null), isNull);
      expect(Validators.pulse('29'), isNotNull);
      expect(Validators.pulse('30'), isNull);
      expect(Validators.pulse('200'), isNull);
      expect(Validators.pulse('201'), isNotNull);
    });

    test('sistolik harus lebih besar dari diastolik', () {
      expect(Validators.systolicAboveDiastolic(120, 80), isNull);
      expect(Validators.systolicAboveDiastolic(80, 80), isNotNull);
      expect(Validators.systolicAboveDiastolic(70, 90), isNotNull);
    });

    test('waktu pengukuran maksimal 5 menit ke depan', () {
      final now = DateTime(2026, 11, 8, 10);
      expect(
        Validators.measuredAt(now.add(const Duration(minutes: 5)), now: now),
        isNull,
      );
      expect(
        Validators.measuredAt(now.add(const Duration(minutes: 6)), now: now),
        isNotNull,
      );
    });
  });

  group('obat dan kontrol (PRD 10.2 dan 10.3)', () {
    test('nama obat 2 sampai 60', () {
      expect(Validators.medicationName('A'), isNotNull);
      expect(Validators.medicationName('Amlodipine'), isNull);
      expect(Validators.medicationName('a' * 61), isNotNull);
    });
    test('dosis 1 sampai 30', () {
      expect(Validators.dosage(''), isNotNull);
      expect(Validators.dosage('5 mg'), isNull);
      expect(Validators.dosage('a' * 31), isNotNull);
    });
    test('catatan maksimal 200 dan boleh kosong', () {
      expect(Validators.notes(''), isNull);
      expect(Validators.notes('a' * 200), isNull);
      expect(Validators.notes('a' * 201), isNotNull);
    });
    test('fasilitas 2 sampai 80, dokter maksimal 60 dan boleh kosong', () {
      expect(Validators.facility('P'), isNotNull);
      expect(Validators.facility('Puskesmas'), isNull);
      expect(Validators.doctor(''), isNull);
      expect(Validators.doctor('a' * 61), isNotNull);
    });
  });
}
