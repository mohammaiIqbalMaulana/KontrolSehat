import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/retry_view.dart';
import '../../../core/widgets/soft_card.dart';
import '../../bp/data/bp_model.dart';
import '../../bp/presentation/bp_history_page.dart';
import '../../medication/data/medication_models.dart';
import '../data/stats_models.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _tabIndex = 1; // 0: harian, 1: mingguan, 2: bulanan
  List<AdherenceDay> _adherence = <AdherenceDay>[];
  List<BpRecord> _bpRecords = <BpRecord>[];
  List<MedicationLog> _todayDoses = <MedicationLog>[];
  bool _loading = true;
  String? _error;

  static const List<String> _dayNames = <String>[
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

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
      final now = DateTime.now();
      final days = _tabIndex == 0 ? 0 : (_tabIndex == 1 ? 6 : 27);
      final from = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days));

      final results = await Future.wait<Object>(<Future<Object>>[
        Services.stats.fetchAdherence(from: from, to: now),
        Services.bp.fetchHistory(since: from),
        if (_tabIndex == 0) Services.doses.fetchToday(),
      ]);

      if (!mounted) return;
      setState(() {
        _adherence = results[0] as List<AdherenceDay>;
        _bpRecords = results[1] as List<BpRecord>;
        if (_tabIndex == 0 && results.length > 2) {
          _todayDoses = results[2] as List<MedicationLog>;
        }
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

  // Menghitung 4 blok mingguan untuk tab bulanan (PRD 8.5)
  List<_MonthlyBlock> _calculateMonthlyBlocks() {
    if (_adherence.isEmpty) return <_MonthlyBlock>[];
    final blocks = <_MonthlyBlock>[];
    for (var i = 0; i < 4; i++) {
      final start = i * 7;
      final end = (start + 7 > _adherence.length)
          ? _adherence.length
          : start + 7;
      if (start >= _adherence.length) break;

      final chunk = _adherence.sublist(start, end);
      final blockDue = chunk.fold<int>(0, (sum, d) => sum + d.due);
      final blockTaken = chunk.fold<int>(0, (sum, d) => sum + d.taken);
      final pct = blockDue == 0 ? 0 : (blockTaken * 100 / blockDue).round();

      blocks.add(_MonthlyBlock(label: 'M${i + 1}', percent: pct));
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    final totalDue = _adherence.fold<int>(0, (sum, a) => sum + a.due);
    final totalTaken = _adherence.fold<int>(0, (sum, a) => sum + a.taken);
    final adherenceLabel = Fmt.adherenceLabel(taken: totalTaken, due: totalDue);

    final avgSys = _bpRecords.isEmpty
        ? null
        : (_bpRecords.map((r) => r.systolic).reduce((a, b) => a + b) /
                  _bpRecords.length)
              .round();
    final avgDia = _bpRecords.isEmpty
        ? null
        : (_bpRecords.map((r) => r.diastolic).reduce((a, b) => a + b) /
                  _bpRecords.length)
              .round();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik & Grafik')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _PeriodSelector(
              selected: _tabIndex,
              onChanged: (int value) {
                setState(() => _tabIndex = value);
                unawaited(_load());
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? RetryView(message: _error!, onRetry: () => unawaited(_load()))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      children: <Widget>[
                        // Ringkasan 2 Kartu
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: SoftCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Kepatuhan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      adherenceLabel,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      '$totalTaken dari $totalDue jatuh tempo',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SoftCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Rata-rata tensi',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      avgSys != null ? '$avgSys/$avgDia' : '–',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    Text(
                                      '${_bpRecords.length} pengukuran',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Bagian Kepatuhan
                        const Text(
                          'Grafik kepatuhan minum obat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (_tabIndex == 0)
                          _buildDailyMedicationList()
                        else
                          _buildBarChartCard(),

                        const SizedBox(height: 24),

                        // Bagian Tekanan Darah
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              'Tren tekanan darah',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BpHistoryPage(),
                                ),
                              ),
                              child: const Text('Lihat riwayat'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildBpLineChartCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMedicationList() {
    if (_todayDoses.isEmpty) {
      return const SoftCard(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Belum ada jadwal obat hari ini.'),
        ),
      );
    }
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _todayDoses.map((dose) {
          final isTaken = dose.status == 'taken';
          final isSkipped = dose.status == 'skipped';
          final statusLabel = isTaken
              ? 'Sudah minum'
              : (isSkipped ? 'Dilewati' : 'Belum dicatat');
          final statusColor = isTaken
              ? Colors.green
              : (isSkipped ? Colors.orange : Colors.grey);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: <Widget>[
                Icon(
                  isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${dose.medicationName} · ${dose.dosage}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${Fmt.time(dose.scheduledAt.toLocal())} · $statusLabel',
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChartCard() {
    if (_adherence.isEmpty) {
      return const SoftCard(
        child: SizedBox(
          height: 160,
          child: Center(child: Text('Belum ada data kepatuhan.')),
        ),
      );
    }

    final isMonthly = _tabIndex == 2;
    final monthlyBlocks = isMonthly
        ? _calculateMonthlyBlocks()
        : <_MonthlyBlock>[];
    final itemCount = isMonthly ? monthlyBlocks.length : _adherence.length;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: 100,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 50,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= itemCount) {
                          return const SizedBox.shrink();
                        }
                        final label = isMonthly
                            ? monthlyBlocks[idx].label
                            : _dayNames[_adherence[idx].day.weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List<BarChartGroupData>.generate(itemCount, (i) {
                  final pct = isMonthly
                      ? monthlyBlocks[i].percent.toDouble()
                      : _adherence[i].percent.toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: pct,
                        color: AppColors.primary,
                        width: isMonthly ? 28 : 16,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DailyBpPoint> _groupBpByDay(List<BpRecord> records) {
    final grouped = <String, List<BpRecord>>{};
    for (final record in records) {
      final local = record.measuredAt.toLocal();
      final key = '${local.year}-${local.month}-${local.day}';
      grouped.putIfAbsent(key, () => <BpRecord>[]).add(record);
    }
    return grouped.values.map((dayRecords) {
      final day = dayRecords.first.measuredAt.toLocal();
      final systolic = dayRecords.fold<int>(0, (sum, r) => sum + r.systolic);
      final diastolic = dayRecords.fold<int>(0, (sum, r) => sum + r.diastolic);
      return _DailyBpPoint(
        day: day,
        systolic: systolic / dayRecords.length,
        diastolic: diastolic / dayRecords.length,
        count: dayRecords.length,
      );
    }).toList();
  }

  Widget _buildBpLineChartCard() {
    if (_bpRecords.isEmpty) {
      return const SoftCard(
        child: SizedBox(
          height: 160,
          child: Center(child: Text('Belum ada catatan tekanan darah.')),
        ),
      );
    }

    // Urutkan kronologis untuk grafik garis
    final sorted = List<BpRecord>.from(_bpRecords)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final daily = _groupBpByDay(sorted);

    final sysSpots = <FlSpot>[];
    final diaSpots = <FlSpot>[];

    for (var i = 0; i < daily.length; i++) {
      sysSpots.add(FlSpot(i.toDouble(), daily[i].systolic));
      diaSpots.add(FlSpot(i.toDouble(), daily[i].diastolic));
    }

    return SoftCard(
      child: Column(
        children: <Widget>[
          const Text(
            'Rata-rata tekanan darah per hari',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(width: 12, height: 4, color: AppColors.danger),
                  const SizedBox(width: 4),
                  const Text('Sistolik', style: TextStyle(fontSize: 11)),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(width: 12, height: 4, color: AppColors.accent),
                  const SizedBox(width: 4),
                  const Text('Diastolik', style: TextStyle(fontSize: 11)),
                ],
              ),
              Text(
                '${daily.length} hari data',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 40,
                maxY: 200,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots.map((spot) {
                      final point = daily[spot.x.toInt()];
                      final series = spot.barIndex == 0
                          ? 'Sistolik'
                          : 'Diastolik';
                      return LineTooltipItem(
                        '${point.day.day}/${point.day.month} · $series\\n${spot.y.toStringAsFixed(0)} mmHg',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 40,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= daily.length) {
                          return const SizedBox.shrink();
                        }
                        final point = daily[idx];
                        final label = '${point.day.day}/${point.day.month}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots: sysSpots,
                    isCurved: true,
                    color: AppColors.danger,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: diaSpots,
                    isCurved: true,
                    color: AppColors.accent,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyBpPoint {
  const _DailyBpPoint({
    required this.day,
    required this.systolic,
    required this.diastolic,
    required this.count,
  });

  final DateTime day;
  final double systolic;
  final double diastolic;
  final int count;
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const labels = <String>['Harian', 'Mingguan', 'Bulanan'];
    return Container(
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MonthlyBlock {
  const _MonthlyBlock({required this.label, required this.percent});
  final String label;
  final int percent;
}
