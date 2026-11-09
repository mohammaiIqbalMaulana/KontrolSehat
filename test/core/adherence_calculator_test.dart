import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/core/utils/formatters.dart';

void main() {
  test('kepatuhan due 0 ditampilkan strip', () {
    expect(Fmt.adherenceLabel(taken: 0, due: 0), '–');
  });

  test('kepatuhan dibulatkan ke bilangan bulat terdekat', () {
    expect(Fmt.adherencePercent(taken: 2, due: 3), 67);
    expect(Fmt.adherencePercent(taken: 1, due: 3), 33);
  });
}
