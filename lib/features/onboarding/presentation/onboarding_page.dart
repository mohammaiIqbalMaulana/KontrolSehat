import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../auth/presentation/auth_gate.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String prefKey = 'has_seen_onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_SlideData> _slides = <_SlideData>[
    _SlideData(
      title: 'Selamat datang di KontrolSehat',
      description:
          'Teman Anda untuk rutin minum obat, mencatat tekanan darah, '
          'dan tidak lupa jadwal kontrol.',
    ),
    _SlideData(
      icon: Icons.notifications_active_outlined,
      title: 'Pengingat Obat Tepat Waktu',
      description:
          'Dapatkan pengingat pada jam minum obat Anda agar kepatuhan '
          'pengobatan hipertensi tetap terjaga.',
    ),
    _SlideData(
      icon: Icons.favorite_outline,
      title: 'Catat dan Pantau Tekanan Darah',
      description:
          'Catat hasil tensi dengan mudah, lalu lihat label edukatif dan '
          'grafik tren tekanan darah Anda.',
    ),
    _SlideData(
      icon: Icons.calendar_month_outlined,
      title: 'Jadwal Kontrol dan Kepatuhan',
      description:
          'Ingat jadwal kontrol ke fasilitas kesehatan dengan hitung mundur '
          'dan pantau kepatuhan mingguan Anda.',
      note:
          'KontrolSehat membantu mencatat dan mengingatkan. Aplikasi ini '
          'tidak memberikan diagnosis atau saran pengobatan. Ikuti anjuran '
          'dokter atau tenaga kesehatan Anda. Seluruh data pada versi ini '
          'adalah data simulasi.',
    ),
  ];

  bool get _isLast => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingPage.prefKey, true);
    if (!mounted) return;
    // AuthGate tetap menjadi rute dasar, jadi login/logout berikutnya
    // dikendalikan olehnya lewat status sesi.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthGate(skipSplash: true)),
      (route) => false,
    );
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ResponsiveCenter(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _isLast
                        ? null
                        : TextButton(
                            onPressed: _finish,
                            child: const Text('Lewati'),
                          ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) =>
                        _SlideView(slide: _slides[index]),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: LoadingButton(
                    label: _isLast ? 'Mulai Sekarang' : 'Lanjut',
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _SlideData slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (slide.icon == null)
                    const AppLogo(height: 150)
                  else
                    Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(slide.icon, size: 64, color: scheme.primary),
                    ),
                  const SizedBox(height: 32),
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  if (slide.note != null) ...<Widget>[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              slide.note!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.description,
    this.icon,
    this.note,
  });

  /// Null berarti slide memakai logo aplikasi.
  final IconData? icon;
  final String title;
  final String description;
  final String? note;
}
