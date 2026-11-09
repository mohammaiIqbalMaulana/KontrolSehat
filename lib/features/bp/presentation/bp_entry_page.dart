import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bp_classifier.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/soft_card.dart';

class BpEntryPage extends StatefulWidget {
  const BpEntryPage({super.key});

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
      await Services.bp.create(
        systolic: sys,
        diastolic: dia,
        pulse: pulse,
        measuredAt: DateTime.now(),
        note: _noteController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tekanan darah dicatat')));
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
    appBar: AppBar(title: const Text('Catat tekanan darah')),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryBg(_category!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _category!.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _category!.advice,
                      style: const TextStyle(fontSize: 14),
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

  Color _categoryBg(BpCategory cat) => switch (cat) {
    BpCategory.normal => AppColors.bpNormal,
    BpCategory.elevated => AppColors.bpElevated,
    BpCategory.high => AppColors.bpHigh,
    BpCategory.veryHigh => AppColors.bpVeryHigh,
    BpCategory.low => AppColors.bpLow,
  };
}
