import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/dose_status.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/retry_view.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/medication_models.dart';
import 'medication_form_page.dart';

class MedicationPage extends StatefulWidget {
  const MedicationPage({super.key});

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  List<Medication> _medications = <Medication>[];
  List<MedicationLog> _doses = <MedicationLog>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Services.doses.ensureDoses();
      final results = await Future.wait<Object>(<Future<Object>>[
        Services.medications.fetchAll(),
        Services.doses.fetchToday(),
      ]);
      if (!mounted) return;
      setState(() {
        _medications = results[0] as List<Medication>;
        _doses = results[1] as List<MedicationLog>;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak ada koneksi. Coba lagi.';
        _loading = false;
      });
    }
  }

  Future<void> _updateDose(MedicationLog dose, String status) async {
    try {
      await Services.doses.updateStatus(id: dose.id, status: status);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan obat diperbarui')),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada koneksi. Coba lagi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Jadwal obat')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _showAddMedication,
      icon: const Icon(Icons.add),
      label: const Text('Tambah'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? RetryView(message: _error!, onRetry: () => unawaited(_load()))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: <Widget>[
                const Text(
                  'Dosis hari ini',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (_doses.isEmpty)
                  const SoftCard(child: Text('Belum ada jadwal obat hari ini.'))
                else
                  ..._doses.map(_doseCard),
                const SizedBox(height: 24),
                const Text(
                  'Obat aktif',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ..._medications.where((m) => m.isActive).map(_medicationCard),
                if (_medications
                    .where((m) => !m.isActive)
                    .isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Obat nonaktif'),
                    children: _medications
                        .where((m) => !m.isActive)
                        .map(_medicationCard)
                        .toList(),
                  ),
                ],
                if (_medications.isEmpty)
                  SoftCard(
                    child: Column(
                      children: <Widget>[
                        const Text(
                          'Belum ada obat. Tambahkan obat sesuai resep dokter.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _showAddMedication,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Obat Pertama'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
  );

  Widget _doseCard(MedicationLog dose) {
    final status = evaluateDoseStatus(
      rawStatus: dose.status,
      scheduledAt: dose.scheduledAt.toLocal(),
      now: DateTime.now(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${dose.medicationName} · ${dose.dosage}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${dose.scheduledAt.toLocal().hour.toString().padLeft(2, '0')}:${dose.scheduledAt.toLocal().minute.toString().padLeft(2, '0')} · ${status.label}',
            ),
            if (status.canAction) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: LoadingButton(
                      label: 'Sudah minum',
                      loading: false,
                      onPressed: () => _updateDose(dose, 'taken'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateDose(dose, 'skipped'),
                      child: const Text('Lewati'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _medicationCard(Medication medication) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SoftCard(
      child: Row(
        children: <Widget>[
          const Icon(Icons.medication_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _editMedication(medication),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    medication.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${medication.dosage} · ${medication.times.map((t) => t.timeOfDay.substring(0, 5)).join(', ')}',
                  ),
                ],
              ),
            ),
          ),
          Switch(
            value: medication.isActive,
            onChanged: (value) async {
              await Services.medications.toggleActive(medication.id, value);
              await _load();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'edit') {
                _editMedication(medication);
              } else if (val == 'delete') {
                _confirmDelete(medication);
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Ubah'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: <Widget>[
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _editMedication(Medication medication) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MedicationFormPage(medication: medication),
      ),
    );
    if (ok == true) await _load();
  }

  void _confirmDelete(Medication medication) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Hapus ${medication.name}?'),
        content: const Text(
          'Seluruh jam konsumsi dan riwayat dosis obat ini akan ikut terhapus secara permanen.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await Services.medications.delete(medication.id);
              await _load();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Obat telah dihapus')),
                );
              }
            },
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMedication() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const MedicationFormPage()),
    );
    if (ok == true) await _load();
  }
}
