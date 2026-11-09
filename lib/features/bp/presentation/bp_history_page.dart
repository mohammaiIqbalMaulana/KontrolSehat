import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/bp_classifier.dart';
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
  BpCategory? _categoryFilter; // null = semua kategori (FR-605)
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
      await Services.profiles.ensureZone();
      final since = _rangeDays == 0
          ? null
          : AppTime.now().subtract(Duration(days: _rangeDays));
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

  List<BpRecord> get _visibleRecords => _categoryFilter == null
      ? _records
      : _records.where((r) => r.category == _categoryFilter).toList();

  Future<void> _edit(BpRecord record) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => BpEntryPage(record: record)),
    );
    if (ok == true) await _load();
  }

  Widget _categoryChips() => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: const Text('Semua'),
            selected: _categoryFilter == null,
            onSelected: (_) => setState(() => _categoryFilter = null),
          ),
        ),
        for (final c in BpCategory.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(c.label),
              selected: _categoryFilter == c,
              onSelected: (_) => setState(() => _categoryFilter = c),
            ),
          ),
      ],
    ),
  );

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
        _categoryChips(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? RetryView(message: _error!, onRetry: () => unawaited(_load()))
              : _visibleRecords.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _records.isEmpty
                          ? 'Belum ada catatan tekanan darah.'
                          : 'Tidak ada catatan dengan kategori ini pada rentang waktu yang dipilih.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                    itemCount: _visibleRecords.length,
                    itemBuilder: (context, index) {
                      final r = _visibleRecords[index];
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
                                        'Nadi: ${r.pulse} bpm · ${Fmt.date(AppTime.toZone(r.measuredAt))}',
                                      ),
                                    if (r.pulse == null)
                                      Text(Fmt.date(AppTime.toZone(r.measuredAt))),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Ubah',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _edit(r),
                              ),
                              IconButton(
                                tooltip: 'Hapus',
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
