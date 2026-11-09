import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/device_timezone.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/soft_card.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _birthYear = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final AuthController _controller = AuthController(Services.auth);

  @override
  void dispose() {
    _name.dispose();
    _birthYear.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final ok = await _controller.signUp(
      email: _email.text,
      password: _password.text,
      fullName: _name.text,
      birthYear: int.parse(_birthYear.text.trim()),
      timezone: DeviceTimezone.detect(),
    );
    if (ok) TextInput.finishAutofillContext();
    if (ok && mounted) {
      // AuthGate (rute dasar) beralih ke Beranda lewat status sesi.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String? _confirmValidator(String? value) =>
      (value ?? '') == _password.text ? null : 'Password tidak sama';

  @override
  Widget build(BuildContext context) => AuthScaffold(
    showBack: true,
    title: 'Buat akun baru',
    subtitle: 'Daftar untuk mulai mengatur pengingat obat dan jadwal kontrol.',
    child: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthYear,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Tahun lahir',
                    hintText: 'Contoh: 1965',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: Validators.birthYear,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: Validators.email,
                  onChanged: (_) => _controller.clearError(),
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  label: 'Password',
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  validator: Validators.passwordRegister,
                ),
                const SizedBox(height: 10),
                _PasswordRules(controller: _password),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'Ulangi password',
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  validator: _confirmValidator,
                  onSubmitted: (_) => _submit(),
                ),
                if (_controller.error != null) ...<Widget>[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: _controller.error!),
                ],
                const SizedBox(height: 20),
                LoadingButton(
                  label: 'Daftar',
                  loading: _controller.loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Daftar syarat password yang menyala saat terpenuhi.
class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final value = controller.text;
      return Wrap(
        spacing: 12,
        runSpacing: 4,
        children: <Widget>[
          _rule(context, 'Minimal 8 karakter', value.length >= 8),
          _rule(context, 'Ada huruf', RegExp('[A-Za-z]').hasMatch(value)),
          _rule(context, 'Ada angka', RegExp('[0-9]').hasMatch(value)),
        ],
      );
    },
  );

  Widget _rule(BuildContext context, String text, bool met) {
    final scheme = Theme.of(context).colorScheme;
    final color = met ? scheme.primary : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: met ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
