import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/note_preview.dart';
import '../../../core/widgets/retry_view.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/appointment_model.dart';
import 'appointment_form_page.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  List<Appointment> _appointments = <Appointment>[];
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
      await Services.profiles.ensureZone();
      final list = await Services.appointments.fetchAll();
      if (!mounted) return;
      setState(() {
        _appointments = list;
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

  @override
  Widget build(BuildContext context) {
    final upcoming = _appointments
        .where((a) => a.status == 'upcoming' && !a.isPast)
        .toList();
    final history = _appointments
        .where((a) => a.status != 'upcoming' || a.isPast)
        .toList();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jadwal kontrol'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Akan datang'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? RetryView(message: _error!, onRetry: () => unawaited(_load()))
            : TabBarView(
                children: <Widget>[
                  _buildList(upcoming, isHistory: false),
                  _buildList(history, isHistory: true),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<Appointment> list, {required bool isHistory}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isHistory
                ? 'Belum ada riwayat kontrol.'
                : 'Belum ada jadwal kontrol yang akan datang.',
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final a = list[index];
        final formattedDate =
            '${Fmt.date(AppTime.toZone(a.scheduledAt))} · ${Fmt.time(AppTime.toZone(a.scheduledAt))}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        a.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (!isHistory)
                      Flexible(
                        child: Text(
                          Fmt.countdown(
                            AppTime.toZone(a.scheduledAt),
                            AppTime.now(),
                          ),
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      _buildHistoryBadge(a),
                  ],
                ),
                const SizedBox(height: 4),
                Text(a.facility),
                if (a.doctor != null && a.doctor!.isNotEmpty)
                  Text('Dokter: ${a.doctor!}'),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                NotePreview(text: a.notes),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    if (!isHistory) ...<Widget>[
                      TextButton(
                        onPressed: () async {
                          await Services.appointments.updateStatus(
                            a.id,
                            'done',
                          );
                          await Services.notifications.reschedule();
                          await _load();
                        },
                        child: const Text('Tandai selesai'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Services.appointments.updateStatus(
                            a.id,
                            'cancelled',
                          );
                          await Services.notifications.reschedule();
                          await _load();
                        },
                        child: const Text('Batalkan'),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editAppointment(a),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _confirmDelete(a),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editAppointment(Appointment appointment) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AppointmentFormPage(appointment: appointment),
      ),
    );
    if (ok == true) await _load();
  }

  Widget _buildHistoryBadge(Appointment a) {
    if (a.status == 'done') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDDF5EA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
            SizedBox(width: 4),
            Text(
              'Selesai',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    } else if (a.status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cancel_outlined, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              'Dibatalkan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    } else {
      // upcoming yang sudah lewat (PRD FR-501: Belum dikonfirmasi)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1CC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.access_time, size: 14, color: Colors.orange),
            SizedBox(width: 4),
            Text(
              'Belum dikonfirmasi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _confirmDelete(Appointment appointment) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus jadwal kontrol?'),
        content: Text(
          'Jadwal kontrol di ${appointment.facility} akan dihapus permanen.',
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
              await Services.appointments.delete(appointment.id);
              await Services.notifications.reschedule();
              await _load();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Jadwal kontrol dihapus')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AppointmentFormPage()),
    );
    if (ok == true) await _load();
  }
}
