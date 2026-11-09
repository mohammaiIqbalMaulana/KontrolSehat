import 'package:flutter/material.dart';

import 'soft_card.dart';

/// Kerangka pemuat untuk Beranda (FR-206): kartu abu-abu berdenyut
/// selama data pertama dimuat.
class SkeletonList extends StatefulWidget {
  const SkeletonList({this.count = 4, super.key});

  final int count;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: 'Memuat data',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: <Widget>[
          for (var i = 0; i < widget.count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final alpha = 0.06 + 0.06 * _controller.value;
                  Widget bar(double width, double height) => Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: base.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                  return SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        bar(110, 12),
                        const SizedBox(height: 12),
                        bar(double.infinity, 18),
                        const SizedBox(height: 8),
                        bar(160, 14),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
