import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/bp_classifier.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/bp_status_chip.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/bp_model.dart';

class BpEntryPage extends StatefulWidget {
  const BpEntryPage({this.record, super.key});

  /// Bila diisi, halaman berfungsi sebagai form ubah (FR-604).
  final BpRecord? record;

  @override
  State<BpEntryPage> createState() => _BpEntryPageState();
}

class _BpEntryPageState extends State<BpEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _pulseController = TextEditingController();
  final _noteController = TextEditingController();

  BpCategory? _category;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record != null) {
      _sysController.text = '${record.systolic}';
      _diaController.text = '${record.diastolic}';
      _pulseController.text = record.pulse == null ? '' : '${record.pulse}';
      _noteController.text = record.note ?? '';
      _category = classifyBp(record.systolic, record.diastolic);
    }
    _sysController.addListener(_updateCategory);
    _diaController.addListener(_updateCategory);
  }

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _pulseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _updateCategory() {
    final sys = int.tryParse(_sysController.text);
    final dia = int.tryParse(_diaController.text);
    if (sys != null &&
        dia != null &&
        sys > dia &&
        sys >= 70 &&
        sys <= 250 &&
        dia >= 40 &&
        dia <= 150) {
      setState(() => _category = classifyBp(sys, dia));
    } else {
      if (_category != null) setState(() => _category = null);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sys = int.parse(_sysController.text);
    final dia = int.parse(_diaController.text);
    final pulse = int.tryParse(_pulseController.text);

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final record = widget.record;
      if (record != null) {
        await Services.bp.update(
          id: record.id,
          systolic: sys,
          diastolic: dia,
          pulse: pulse,
          note: _noteController.text,
        );
      } else {
        await Services.bp.create(
          systolic: sys,
          diastolic: dia,
          pulse: pulse,
          measuredAt: DateTime.now(),
          note: _noteController.text,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              record == null
                  ? 'Tekanan darah dicatat'
                  : 'Catatan tekanan darah diperbarui',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Tidak ada koneksi. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.record == null ? 'Catat tekanan darah' : 'Ubah catatan tensi',
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _sysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sistolik (mmHg)',
                    ),
                    validator: Validators.systolic,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _diaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diastolik (mmHg)',
                    ),
                    validator: (value) {
                      final err = Validators.diastolic(value);
                      if (err != null) return err;
                      final sys = int.tryParse(_sysController.text);
                      final dia = int.tryParse(value ?? '');
                      if (sys == null || dia == null) return null;
                      return Validators.systolicAboveDiastolic(sys, dia);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pulseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Denyut nadi (bpm, opsional)',
              ),
              validator: Validators.pulse,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
              validator: Validators.notes,
            ),
            const SizedBox(height: 20),
            if (_category != null) ...<Widget>[
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    BpStatusChip(category: _category!),
                    const SizedBox(height: 8),
                    Text(
                      _category!.advice,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_error != null) ...<Widget>[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            LoadingButton(
              label: 'Simpan',
              loading: _saving,
              onPressed: _category == null ? null : _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
