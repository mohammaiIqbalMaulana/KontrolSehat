import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bp_classifier.dart';
import '../../../core/utils/dose_status.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/retry_view.dart';
import '../../../core/widgets/soft_card.dart';
import '../../appointment/presentation/appointment_form_page.dart';
import '../../bp/presentation/bp_entry_page.dart';
import '../../bp/presentation/bp_history_page.dart';
import '../../medication/presentation/medication_form_page.dart';
import '../../profile/presentation/profile_page.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller = HomeController(
    profiles: Services.profiles,
    doses: Services.doses,
    bp: Services.bp,
    appointments: Services.appointments,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            switch (_controller.status) {
              case HomeStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case HomeStatus.failed:
                return RetryView(
                  message: _controller.error ?? 'Terjadi kesalahan.',
                  onRetry: () => unawaited(_controller.load()),
                );
              case HomeStatus.ready:
                return RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    children: <Widget>[
                      ResponsiveCenter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Halo, ${_controller.profile?.firstName ?? ''}!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Mari jaga tekanan darah tetap stabil.',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () => Navigator.of(context)
                                      .push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const ProfilePage(),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildNextMedicationCard(),
                            const SizedBox(height: 16),
                            _buildProgressRingCard(),
                            const SizedBox(height: 16),
                            _buildLatestBpCard(),
                            const SizedBox(height: 16),
                            _buildNearestAppointmentCard(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
            }
          },
        ),
      ),
    ),
  );

  Widget _buildNextMedicationCard() {
    if (_controller.totalTodayCount == 0) {
      return SoftCard(
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.medication_outlined,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Belum ada obat terjadwal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => const MedicationFormPage(),
                  ),
                );
                if (ok == true) await _controller.load();
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      );
    }

    final dose = _controller.nextDose;
    if (dose == null) {
      return const SoftCard(
        child: Row(
          children: <Widget>[
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Semua obat hari ini sudah dicatat',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final status = evaluateDoseStatus(
      rawStatus: dose.status,
      scheduledAt: dose.scheduledAt.toLocal(),
      now: DateTime.now(),
    );

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Obat berikutnya',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gradientTop,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${dose.medicationName} · ${dose.dosage}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            'Jadwal: ${Fmt.time(dose.scheduledAt.toLocal())}',
            style: const TextStyle(fontSize: 14),
          ),
          if (status.canAction) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: LoadingButton(
                    label: 'Sudah minum',
                    loading: false,
                    onPressed: () => _controller.markDose(dose, 'taken'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.markDose(dose, 'skipped'),
                    child: const Text('Lewati'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressRingCard() {
    final total = _controller.totalTodayCount;
    final taken = _controller.takenCount;
    final pct = _controller.progressPercent;

    if (total == 0) {
      return const SoftCard(child: Text('Belum ada jadwal obat hari ini.'));
    }

    return SoftCard(
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  value: pct / 100,
                  strokeWidth: 6,
                  backgroundColor: AppColors.gradientBottom,
                  color: AppColors.primary,
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Progres hari ini',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$taken dari $total dosis diminum',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestBpCard() {
    final bp = _controller.latestBp;
    if (bp == null) {
      return SoftCard(
        child: Row(
          children: <Widget>[
            const Icon(Icons.favorite_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Belum ada catatan tensi.')),
            TextButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(builder: (_) => const BpEntryPage()),
              ),
              child: const Text('Catat'),
            ),
          ],
        ),
      );
    }

    return SoftCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const BpHistoryPage()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Tekanan darah terakhir',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
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
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${bp.systolic}/${bp.diastolic} mmHg',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _categoryBg(bp.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bp.category.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              Fmt.date(bp.measuredAt.toLocal()),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearestAppointmentCard() {
    final a = _controller.nearestAppointment;
    if (a == null) {
      return SoftCard(
        child: Row(
          children: <Widget>[
            const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(child: Text('Belum ada jadwal kontrol.')),
            TextButton(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => const AppointmentFormPage(),
                  ),
                );
                if (ok == true) await _controller.load();
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      );
    }

    final countdown = Fmt.countdown(a.scheduledAt.toLocal(), DateTime.now());
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Kontrol terdekat',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                countdown,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            a.facility,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (a.doctor != null && a.doctor!.isNotEmpty)
            Text('Dokter: ${a.doctor!}'),
          Text(
            '${Fmt.date(a.scheduledAt.toLocal())} · ${Fmt.time(a.scheduledAt.toLocal())}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryBg(BpCategory cat) => switch (cat) {
    BpCategory.normal => AppColors.bpNormal,
    BpCategory.elevated => AppColors.bpElevated,
    BpCategory.high => AppColors.bpHigh,
    BpCategory.veryHigh => AppColors.bpVeryHigh,
    BpCategory.low => AppColors.bpLow,
  };
}
