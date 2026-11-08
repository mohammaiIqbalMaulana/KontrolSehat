import 'package:flutter/material.dart';

/// Tombol utama pil yang menampilkan indikator saat memproses dan
/// nonaktif selama itu (mencegah kirim ganda).
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(label),
      );
}
