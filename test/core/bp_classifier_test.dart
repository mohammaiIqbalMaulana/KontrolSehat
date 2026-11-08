import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/core/utils/bp_classifier.dart';

void main() {
  // G4: 23 kasus, termasuk semua nilai batas (PRD 8.4).
  const cases = <(int, int, BpCategory)>[
    (118, 78, BpCategory.normal),
    (119, 79, BpCategory.normal),
    (110, 75, BpCategory.normal),
    (90, 70, BpCategory.normal),
    (100, 60, BpCategory.normal),
    (120, 70, BpCategory.elevated),
    (119, 80, BpCategory.elevated),
    (125, 70, BpCategory.elevated),
    (139, 89, BpCategory.elevated),
    (119, 89, BpCategory.elevated),
    (140, 80, BpCategory.high),
    (130, 90, BpCategory.high),
    (138, 92, BpCategory.high),
    (179, 119, BpCategory.high),
    (142, 88, BpCategory.high),
    (85, 95, BpCategory.high), // tinggi didahulukan dari rendah
    (180, 80, BpCategory.veryHigh),
    (150, 120, BpCategory.veryHigh),
    (250, 150, BpCategory.veryHigh),
    (89, 70, BpCategory.low),
    (100, 59, BpCategory.low),
    (85, 80, BpCategory.low), // contoh di PRD
    (70, 40, BpCategory.low),
  ];

  for (final (sys, dia, expected) in cases) {
    test('$sys/$dia -> ${expected.label}', () {
      expect(classifyBp(sys, dia), expected);
    });
  }

  test('nilai database sesuai kolom category', () {
    expect(BpCategory.veryHigh.dbValue, 'very_high');
    expect(BpCategory.fromDb('elevated'), BpCategory.elevated);
  });

  test('setiap kategori punya anjuran', () {
    for (final c in BpCategory.values) {
      expect(c.advice, isNotEmpty);
    }
  });
}
