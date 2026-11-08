import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/retry_view.dart';
import '../../../core/widgets/soft_card.dart';
import 'home_controller.dart';

/// Kerangka Beranda. Kartu obat, ring progres, tekanan darah, dan kontrol
/// ditambahkan per fitur (lihat CLAUDE.md, urutan pengerjaan).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller = HomeController(
    profiles: Services.profiles,
    doses: Services.doses,
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

  Future<void> _logout() => Services.auth.signOut();

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
                        children: <Widget>[
                          ResponsiveCenter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Halo, ${_controller.profile?.firstName ?? ''}!',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  SoftCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        const Text(
                                          'Koneksi dan login berfungsi.',
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton(
                                          onPressed: () => unawaited(_logout()),
                                          child: const Text('Keluar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
}
