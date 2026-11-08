import 'package:flutter/material.dart';

import '../../../core/di/services.dart';
import '../../../core/utils/device_timezone.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/soft_card.dart';
import 'auth_controller.dart';

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
  late final AuthController _controller = AuthController(Services.auth);

  @override
  void dispose() {
    _name.dispose();
    _birthYear.dispose();
    _email.dispose();
    _password.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _controller.signUp(
      email: _email.text,
      password: _password.text,
      fullName: _name.text,
      birthYear: int.parse(_birthYear.text.trim()),
      timezone: DeviceTimezone.detect(),
    );
    // Berhasil: sesi aktif dan AuthGate menampilkan Beranda. Tutup halaman
    // ini agar tumpukan navigasi bersih.
    if (ok && mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ResponsiveCenter(
              child: Padding(
                padding: const EdgeInsets.only(top: 56, bottom: 32),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text('Daftar', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 24),
                        SoftCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nama lengkap',
                                ),
                                validator: Validators.fullName,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _birthYear,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Tahun lahir',
                                ),
                                validator: Validators.birthYear,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration:
                                    const InputDecoration(labelText: 'Email'),
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
                                  helperText:
                                      'Minimal 8 karakter, memuat huruf dan angka',
                                ),
                                validator: Validators.passwordRegister,
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
                                label: 'Daftar',
                                loading: _controller.loading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
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
