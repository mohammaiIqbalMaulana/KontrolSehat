import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/core/config/env.dart';

void main() {
  test('kunci secret dan service_role ditolak (SEC-03)', () {
    expect(Env.isForbiddenKey('sb_secret_abc'), isTrue);
    expect(Env.isForbiddenKey('eyJ...service_role...'), isTrue);
    expect(Env.isForbiddenKey('sb_publishable_abc'), isFalse);
  });
}
