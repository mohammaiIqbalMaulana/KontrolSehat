import 'package:flutter/material.dart';

import '../../core/di/services.dart';
import 'notification_service.dart';

/// Dialog uji notifikasi: memeriksa izin, mengirim notifikasi tes, dan
/// menampilkan daftar notifikasi yang benar-benar terdaftar di sistem.
class NotificationTestDialog extends StatefulWidget {
  const NotificationTestDialog({super.key});

  @override
  State<NotificationTestDialog> createState() => _NotificationTestDialogState();
}

class _NotificationTestDialogState extends State<NotificationTestDialog> {
  String _report = 'Tekan "Cek status" untuk melihat kondisi notifikasi.';
  bool _busy = false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    String result;
    try {
      result = await action();
    } on Object catch (e) {
      result = 'Error: $e';
    }
    if (!mounted) return;
    setState(() {
      _report = result;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    return AlertDialog(
      title: const Text('Uji notifikasi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(service.debugDump),
                  child: const Text('Cek status'),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await service.requestPermissions();
                          return service.debugDump();
                        }),
                  child: const Text('Minta izin'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(service.showTestNow),
                  child: const Text('Tampil sekarang'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(service.scheduleTest),
                  child: const Text('Jadwal 1 menit'),
                ),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          await Services.notifications.reschedule();
                          return service.debugDump();
                        }),
                  child: const Text('Jadwalkan ulang dosis'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            SelectableText(
              _report,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
