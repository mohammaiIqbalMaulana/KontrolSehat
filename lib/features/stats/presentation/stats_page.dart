import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
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
      await Services.profiles.ensureZone();
      await Services.doses.ensureDoses();
      final now = AppTime.now();
      final days = _tabIndex == 0 ? 0 : (_tabIndex == 1 ? 6 : 27);
      // Tanggal kalender di zona profil (NFR-10).
      final from = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: days));
      final fromInstant = AppTime.wall(from.year, from.month, from.day);

      final results = await Future.wait<Object>(<Future<Object>>[
        Services.stats.fetchAdherence(from: from, to: now),
        Services.bp.fetchHistory(since: fromInstant),
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

      blocks.add(
        _MonthlyBlock(
          label: 'M${i + 1}',
          percent: pct,
          due: blockDue,
          taken: blockTaken,
          start: chunk.first.day,
          end: chunk.last.day,
        ),
      );
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
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
        child: EmptyState(
          icon: Icons.medication_outlined,
          message: 'Belum ada jadwal obat hari ini.',
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
                  '${Fmt.time(AppTime.toZone(dose.scheduledAt))} · $statusLabel',
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static const List<String> _monthNames = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _shortDate(DateTime d) => '${d.day} ${_monthNames[d.month - 1]}';

  Widget _buildBarChartCard() {
    if (_adherence.isEmpty) {
      return const SoftCard(
        child: EmptyState(
          icon: Icons.bar_chart_outlined,
          message: 'Belum ada data kepatuhan.',
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final isMonthly = _tabIndex == 2;
    final monthlyBlocks = isMonthly
        ? _calculateMonthlyBlocks()
        : <_MonthlyBlock>[];
    final itemCount = isMonthly ? monthlyBlocks.length : _adherence.length;
    final tooltipText = scheme.onInverseSurface;

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
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    // Latar & teks tooltip mengikuti tema agar selalu terbaca.
                    getTooltipColor: (_) => scheme.inverseSurface,
                    tooltipBorderRadius: BorderRadius.circular(10),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tooltipMargin: 6,
                    maxContentWidth: 170,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final String title;
                      final int due;
                      final int taken;
                      if (isMonthly) {
                        final b = monthlyBlocks[groupIndex];
                        title =
                            '${_shortDate(b.start)} – ${_shortDate(b.end)}';
                        due = b.due;
                        taken = b.taken;
                      } else {
                        final a = _adherence[groupIndex];
                        title =
                            '${_dayNames[a.day.weekday - 1]}, '
                            '${_shortDate(a.day)}';
                        due = a.due;
                        taken = a.taken;
                      }
                      final valueLabel = due == 0
                          ? '–'
                          : Fmt.adherenceLabel(taken: taken, due: due);
                      final detail = due == 0
                          ? 'Tidak ada dosis jatuh tempo'
                          : '$taken dari $due dosis';
                      return BarTooltipItem(
                        '$title\n',
                        TextStyle(
                          color: tooltipText.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: valueLabel,
                            style: TextStyle(
                              color: tooltipText,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '\n$detail',
                            style: TextStyle(
                              color: tooltipText.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
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
                      reservedSize: 36,
                      interval: 50,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
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
                        // Bulanan: label = tanggal awal blok 7 hari, bukan
                        // "M1..M4" yang terbaca seperti minggu ke-N bulan ini.
                        final label = isMonthly
                            ? _shortDate(monthlyBlocks[idx].start)
                            : _dayNames[_adherence[idx].day.weekday - 1];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
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
                        // scheme.primary: ungu terang di tema gelap.
                        color: scheme.primary,
                        width: isMonthly ? 28 : 16,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: scheme.onSurface.withValues(alpha: 0.07),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          if (isMonthly) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Tiap batang = 7 hari berurutan, dimulai dari tanggal di '
              'bawahnya. Batang paling kanan = 7 hari terakhir.',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  List<_DailyBpPoint> _groupBpByDay(List<BpRecord> records) {
    final grouped = <String, List<BpRecord>>{};
    for (final record in records) {
      final local = AppTime.toZone(record.measuredAt);
      final key = '${local.year}-${local.month}-${local.day}';
      grouped.putIfAbsent(key, () => <BpRecord>[]).add(record);
    }
    return grouped.values.map((dayRecords) {
      final local = AppTime.toZone(dayRecords.first.measuredAt);
      // Tanggal kalender murni (UTC) agar selisih hari tidak terpengaruh DST.
      final day = DateTime.utc(local.year, local.month, local.day);
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
        child: EmptyState(
          icon: Icons.favorite_outline,
          message: 'Belum ada catatan tekanan darah.',
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Merah tua hampir tak terlihat di latar gelap: pakai warna error tema.
    final sysColor = isDark ? scheme.error : AppColors.danger;
    const diaColor = AppColors.accent;
    final tooltipText = scheme.onInverseSurface;

    // Urutkan kronologis untuk grafik garis
    final sorted = List<BpRecord>.from(_bpRecords)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final daily = _groupBpByDay(sorted);

    // Sumbu X berbasis tanggal (bukan urutan data) supaya jarak antar titik
    // sesuai selisih hari, dan label dijarangkan agar tidak bertumpuk.
    final firstDay = daily.first.day;
    final spanDays = daily.last.day.difference(firstDay).inDays;
    final maxX = spanDays < 1 ? 1.0 : spanDays.toDouble();
    final step = (maxX / 4).ceil();
    final xStep = step < 1 ? 1 : step;
    final xInterval = xStep.toDouble();

    final sysSpots = <FlSpot>[];
    final diaSpots = <FlSpot>[];
    final byOffset = <int, _DailyBpPoint>{};
    for (final p in daily) {
      final x = p.day.difference(firstDay).inDays;
      byOffset[x] = p;
      sysSpots.add(FlSpot(x.toDouble(), p.systolic));
      diaSpots.add(FlSpot(x.toDouble(), p.diastolic));
    }

    // Rentang Y menyesuaikan data, minimal 40–200, kelipatan 40 agar label
    // sumbu rapi (40, 80, 120, ...).
    var minY = 40.0;
    var maxY = 200.0;
    for (final p in daily) {
      final lo = ((p.diastolic - 10) / 40).floorToDouble() * 40;
      final hi = ((p.systolic + 10) / 40).ceilToDouble() * 40;
      if (lo < minY) minY = lo;
      if (hi > maxY) maxY = hi;
    }

    Widget legend(Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Rata-rata tekanan darah per hari',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              legend(sysColor, 'Sistolik'),
              legend(diaColor, 'Diastolik'),
              Text(
                '${daily.length} hari data',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 40,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outline.withValues(alpha: 0.25),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchSpotThreshold: 24,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      tooltipBorderRadius: BorderRadius.circular(10),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      maxContentWidth: 190,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) {
                        if (spots.isEmpty) return <LineTooltipItem?>[];
                        final point = byOffset[spots.first.x.round()];
                        // Satu tooltip gabungan; item lain dikosongkan.
                        return List<LineTooltipItem?>.generate(spots.length, (
                          i,
                        ) {
                          if (i != 0 || point == null) return null;
                          final d = point.day;
                          final dim = tooltipText.withValues(alpha: 0.85);
                          return LineTooltipItem(
                            '${_dayNames[d.weekday - 1]}, ${_shortDate(d)}',
                            TextStyle(
                              color: tooltipText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.left,
                            children: <TextSpan>[
                              TextSpan(
                                text: '\n● ',
                                style: TextStyle(
                                  color: sysColor,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'Sistolik ${point.systolic.round()} mmHg',
                                style: TextStyle(
                                  color: tooltipText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text: '\n● ',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'Diastolik ${point.diastolic.round()} mmHg',
                                style: TextStyle(
                                  color: tooltipText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: '\n${point.count} pengukuran',
                                style: TextStyle(color: dim, fontSize: 10),
                              ),
                            ],
                          );
                        });
                      },
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
                        reservedSize: 34,
                        interval: 40,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: xInterval,
                        getTitlesWidget: (val, meta) {
                          final offset = val.round();
                          if ((val - offset).abs() > 0.001 ||
                              offset < 0 ||
                              offset > spanDays) {
                            return const SizedBox.shrink();
                          }
                          // Titik terakhir tetap diberi label, kecuali terlalu
                          // dekat dengan label sebelumnya (hindari tumpang tindih).
                          final rest = offset % xStep;
                          if (rest != 0 && rest < xStep * 0.6) {
                            return const SizedBox.shrink();
                          }
                          final d = firstDay.add(Duration(days: offset));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _shortDate(d),
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurfaceVariant,
                              ),
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
                      preventCurveOverShooting: true,
                      color: sysColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: diaSpots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: diaColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
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
  const _MonthlyBlock({
    required this.label,
    required this.percent,
    required this.due,
    required this.taken,
    required this.start,
    required this.end,
  });
  final String label;
  final int percent;
  final int due;
  final int taken;
  final DateTime start;
  final DateTime end;
}
