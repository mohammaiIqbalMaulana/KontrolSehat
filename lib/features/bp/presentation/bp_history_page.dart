import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bp_status_chip.dart';
import '../../../core/widgets/retry_view.dart';
import '../../../core/widgets/soft_card.dart';
import '../data/bp_model.dart';
import 'bp_entry_page.dart';

class BpHistoryPage extends StatefulWidget {
  const BpHistoryPage({super.key});

  @override
  State<BpHistoryPage> createState() => _BpHistoryPageState();
}

class _BpHistoryPageState extends State<BpHistoryPage> {
  int _rangeDays = 7;
  List<BpRecord> _records = <BpRecord>[];
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
      final since = _rangeDays == 0
          ? null
          : DateTime.now().subtract(Duration(days: _rangeDays));
      final list = await Services.bp.fetchHistory(since: since);
      if (!mounted) return;
      setState(() {
        _records = list;
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Riwayat tekanan darah')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(builder: (_) => const BpEntryPage()),
        );
        if (ok == true) await _load();
      },
      icon: const Icon(Icons.add),
      label: const Text('Catat'),
    ),
    body: Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 7, label: Text('7 hari')),
              ButtonSegment<int>(value: 30, label: Text('30 hari')),
              ButtonSegment<int>(value: 0, label: Text('Semua')),
            ],
            selected: <int>{_rangeDays},
            onSelectionChanged: (val) {
              setState(() => _rangeDays = val.first);
              unawaited(_load());
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? RetryView(message: _error!, onRetry: () => unawaited(_load()))
              : _records.isEmpty
              ? const Center(child: Text('Belum ada catatan tekanan darah.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final r = _records[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftCard(
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '${r.systolic}/${r.diastolic} mmHg',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (r.pulse != null)
                                      Text(
                                        'Nadi: ${r.pulse} bpm · ${Fmt.date(r.measuredAt.toLocal())}',
                                      ),
                                    if (r.pulse == null)
                                      Text(Fmt.date(r.measuredAt.toLocal())),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _confirmDelete(r),
                              ),
                              BpStatusChip(category: r.category),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );

  void _confirmDelete(BpRecord record) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan tekanan darah?'),
        content: const Text('Catatan ini akan dihapus secara permanen.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await Services.bp.delete(record.id);
              await _load();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
