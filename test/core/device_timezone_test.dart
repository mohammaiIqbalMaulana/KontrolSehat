import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/core/utils/device_timezone.dart';

void main() {
  test('offset Indonesia dipetakan ke zona IANA', () {
    expect(
      DeviceTimezone.detect(offset: const Duration(hours: 7)),
      'Asia/Jakarta',
    );
    expect(
      DeviceTimezone.detect(offset: const Duration(hours: 8)),
      'Asia/Makassar',
    );
    expect(
      DeviceTimezone.detect(offset: const Duration(hours: 9)),
      'Asia/Jayapura',
    );
  });

  test('di luar Indonesia memakai Asia/Jakarta', () {
    expect(
      DeviceTimezone.detect(offset: const Duration(hours: -5)),
      'Asia/Jakarta',
    );
  });
}
