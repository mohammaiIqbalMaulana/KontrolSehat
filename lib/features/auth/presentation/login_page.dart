import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/soft_card.dart';
import '../../shell/presentation/main_shell.dart';
import 'auth_controller.dart';
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
    final ok = await _controller.signIn(_email.text, _password.text);
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text('Masuk', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        const Text('Selamat datang kembali di KontrolSehat.'),
                        const SizedBox(height: 24),
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                validator: Validators.email,
                                onChanged: (_) => _controller.clearError(),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                validator: Validators.passwordLogin,
                                onChanged: (_) => _controller.clearError(),
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              if (_controller.error != null) ...<Widget>[
                                const SizedBox(height: 12),
                                Text(
                                  _controller.error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
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
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterPage(),
                            ),
                          ),
                          child: const Text('Belum punya akun? Daftar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
