import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/soft_card.dart';
import '../../auth/presentation/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String prefKey = 'has_seen_onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_SlideData> _slides = const <_SlideData>[
    _SlideData(
      icon: Icons.notifications_active_outlined,
      title: 'Pengingat Obat Tepat Waktu',
      description: 'Dapatkan pengingat pada jam minum obat Anda agar kepatuhan pengobatan hipertensi tetap terjaga.',
    ),
    _SlideData(
      icon: Icons.favorite_outline,
      title: 'Catat & Pantau Tekanan Darah',
      description: 'Catat hasil tensi dengan mudah dan lihat label edukatif serta grafik tren perkembangan tekanan darah Anda.',
    ),
    _SlideData(
      icon: Icons.calendar_month_outlined,
      title: 'Jadwal Kontrol & Kepatuhan',
      description:
          'Ingat jadwal kontrol ke fasilitas kesehatan dengan hitung mundur dan pantau kepatuhan mingguan Anda.\n\n'
          'Pernyataan Edukatif (SEC-07):\n'
          'KontrolSehat membantu mencatat dan mengingatkan. Aplikasi ini tidak memberikan diagnosis atau saran pengobatan. '
          'Ikuti anjuran dokter atau tenaga kesehatan Anda. Seluruh data pada versi ini adalah data simulasi.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingPage.prefKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppBackground(
      child: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Lewati'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: SoftCard(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              slide.icon,
                              size: 72,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _slides.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.primary
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: LoadingButton(
                  label: _currentPage == _slides.length - 1
                      ? 'Mulai Sekarang'
                      : 'Lanjut',
                  loading: false,
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
