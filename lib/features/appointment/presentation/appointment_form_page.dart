import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_button.dart';
import '../data/appointment_model.dart';

class AppointmentFormPage extends StatefulWidget {
  const AppointmentFormPage({this.appointment, super.key});

  final Appointment? appointment;

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Kontrol rutin');
  final _facilityController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    if (appointment != null) {
      _titleController.text = appointment.title;
      _facilityController.text = appointment.facility;
      _doctorController.text = appointment.doctor ?? '';
      _notesController.text = appointment.notes ?? '';
      final local = appointment.scheduledAt.toLocal();
      _scheduledAt = DateTime(local.year, local.month, local.day);
      _scheduledTime = TimeOfDay(hour: local.hour, minute: local.minute);
    }
  }

  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 9, minute: 0);

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _facilityController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _scheduledAt = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null && mounted) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final fullScheduled = DateTime(
      _scheduledAt.year,
      _scheduledAt.month,
      _scheduledAt.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );

    if (widget.appointment == null && fullScheduled.isBefore(DateTime.now())) {
      setState(() => _error = 'Jadwal harus di masa depan');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (widget.appointment != null) {
        await Services.appointments.update(
          id: widget.appointment!.id,
          title: _titleController.text,
          facility: _facilityController.text,
          doctor: _doctorController.text,
          scheduledAt: fullScheduled,
          notes: _notesController.text,
        );
      } else {
        await Services.appointments.create(
          title: _titleController.text.trim(),
          facility: _facilityController.text.trim(),
          doctor: _doctorController.text.trim().isEmpty
              ? null
              : _doctorController.text.trim(),
          scheduledAt: fullScheduled,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      }
      await Services.notifications.reschedule();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.appointment == null
                  ? 'Jadwal kontrol ditambahkan'
                  : 'Jadwal kontrol diperbarui',
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
        widget.appointment == null
            ? 'Tambah Jadwal Kontrol'
            : 'Ubah Jadwal Kontrol',
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul kontrol',
                hintText: 'Contoh: Kontrol rutin puskesmas',
              ),
              validator: Validators.appointmentTitle,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facilityController,
              decoration: const InputDecoration(
                labelText: 'Fasilitas kesehatan',
                hintText: 'Nama puskesmas, klinik, atau RS',
              ),
              validator: Validators.facility,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _doctorController,
              decoration: const InputDecoration(
                labelText: 'Dokter / Petugas (opsional)',
                hintText: 'Nama dokter yang menangani',
              ),
              validator: Validators.doctor,
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Tanggal kontrol'),
              subtitle: Text(Fmt.date(_scheduledAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Jam kontrol'),
              subtitle: Text(
                '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickTime,
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: Bawa kartu BPJS dan buku tensi',
              ),
              validator: Validators.notes,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            LoadingButton(
              label: 'Simpan Jadwal',
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    ),
  );
}
