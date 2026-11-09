import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/soft_card.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthController _controller = AuthController(Services.auth);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final ok = await _controller.signIn(_email.text, _password.text);
    if (ok) TextInput.finishAutofillContext();
    if (ok && mounted) {
      // AuthGate (rute dasar) beralih ke Beranda lewat status sesi.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Selamat datang kembali',
    subtitle: 'Masuk untuk melihat pengingat obat dan jadwal kontrol Anda.',
    child: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
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
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.password],
                      validator: Validators.passwordLogin,
                      onChanged: (_) => _controller.clearError(),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_controller.error != null) ...<Widget>[
                      const SizedBox(height: 16),
                      AuthErrorBanner(message: _controller.error!),
                    ],
                    const SizedBox(height: 20),
                    LoadingButton(
                      label: 'Masuk',
                      loading: _controller.loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Belum punya akun?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton(
                    onPressed: _controller.loading
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                    child: const Text('Daftar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
