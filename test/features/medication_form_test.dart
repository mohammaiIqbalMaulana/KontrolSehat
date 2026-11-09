import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kontrol_sehat/features/medication/presentation/medication_form_page.dart';

void main() {
  testWidgets('MedicationFormPage renders without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MedicationFormPage()));
    expect(find.text('Tambah obat'), findsOneWidget);
    expect(find.text('Nama obat'), findsOneWidget);
    expect(find.text('Dosis'), findsOneWidget);
    expect(find.text('Jam minum'), findsOneWidget);
    expect(find.text('Simpan obat'), findsOneWidget);
  });
}
