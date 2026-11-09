import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../core/di/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/soft_card.dart';
import '../../notifications/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  bool _medicationReminder = true;
  bool _appointmentReminder = true;
  String _themeChoice = 'system';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _medicationReminder = prefs.getBool('medication_reminder') ?? true;
      _appointmentReminder = prefs.getBool('appointment_reminder') ?? true;
      _themeChoice = prefs.getString('theme_choice') ?? 'system';
      _loading = false;
    });
  }

  Future<void> _setReminder(String key, bool value) async {
    if (!value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Matikan pengingat?'),
          content: Text(
            key == 'medication_reminder'
                ? 'Jadwal obat tetap tersimpan, tetapi notifikasi minum obat tidak akan muncul.'
                : 'Jadwal kontrol tetap tersimpan, tetapi notifikasi sebelum jadwal tidak akan muncul.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Matikan'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!value) await NotificationService.instance.cancelAll();
    if (!mounted) return;
    setState(() {
      if (key == 'medication_reminder') {
        _medicationReminder = value;
      } else {
        _appointmentReminder = value;
      }
    });
  }

  Future<void> _setTheme(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_choice', value);
    if (value == 'light') {
      themeModeNotifier.value = ThemeMode.light;
    } else if (value == 'dark') {
      themeModeNotifier.value = ThemeMode.dark;
    } else {
      themeModeNotifier.value = ThemeMode.system;
    }
    if (mounted) setState(() => _themeChoice = value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil & Pengaturan')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              FutureBuilder(
                future: Services.profiles.fetchMine(),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  return SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile?.fullName ?? 'Pengguna',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Tahun lahir: ${profile?.birthYear ?? '-'}'),
                        Text(
                          'Zona waktu: ${profile?.timezone ?? 'Asia/Jakarta'}',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: profile == null
                              ? null
                              : () => _showEditProfile(
                                  profile.fullName,
                                  profile.birthYear,
                                ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Ubah profil'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pengingat obat'),
                      subtitle: const Text('Ingatkan sesuai jadwal obat'),
                      value: _medicationReminder,
                      onChanged: (value) =>
                          _setReminder('medication_reminder', value),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pengingat kontrol'),
                      subtitle: const Text('Ingatkan sebelum jadwal kontrol'),
                      value: _appointmentReminder,
                      onChanged: (value) =>
                          _setReminder('appointment_reminder', value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Tampilan'),
                      subtitle: Text(switch (_themeChoice) {
                        'light' => 'Terang',
                        'dark' => 'Gelap',
                        _ => 'Ikuti sistem',
                      }),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showThemeDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.battery_saver_outlined),
                      title: const Text('Optimasi baterai & pengingat'),
                      subtitle: const Text(
                        'Agar pengingat tetap muncul tepat waktu',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showBatterySettingsInfo,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Tentang aplikasi'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showAboutDialog,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      title: const Text(
                        'Hapus akun',
                        style: TextStyle(color: AppColors.danger),
                      ),
                      onTap: _showDeleteDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _logout,
                child: const Text('Keluar dari akun'),
              ),
            ],
          ),
  );

  Future<void> _logout() async {
    await NotificationService.instance.cancelAll();
    await Services.auth.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showEditProfile(String currentName, int currentYear) {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: currentName);
    final birthYear = TextEditingController(text: '$currentYear');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah profil'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama lengkap'),
                validator: Validators.fullName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: birthYear,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tahun lahir'),
                validator: Validators.birthYear,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              await Services.profiles.updateMine(
                fullName: name.text,
                birthYear: int.parse(birthYear.text.trim()),
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) setState(() {});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(() {
      name.dispose();
      birthYear.dispose();
    });
  }

  void _showThemeDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tampilan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: const Text('Terang'),
              trailing: _themeChoice == 'light'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                _setTheme('light');
                Navigator.of(dialogCtx).pop();
              },
            ),
            ListTile(
              title: const Text('Gelap'),
              trailing: _themeChoice == 'dark'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                _setTheme('dark');
                Navigator.of(dialogCtx).pop();
              },
            ),
            ListTile(
              title: const Text('Ikuti sistem'),
              trailing: _themeChoice == 'system'
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                _setTheme('system');
                Navigator.of(dialogCtx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBatterySettingsInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Optimasi baterai & pengingat',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Beberapa perangkat membatasi aplikasi di latar belakang sehingga pengingat bisa terlambat. '
                'Di halaman berikutnya, pilih KontrolSehat lalu ubah penggunaan baterai menjadi '
                '“Tanpa batas” atau “Jangan optimalkan” jika pilihan itu tersedia.',
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _openBatterySettings();
                },
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Buka Pengaturan Baterai'),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Nanti'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBatterySettings() async {
    try {
      await const MethodChannel('kontrolsehat/settings')
          .invokeMethod<void>('openBatterySettings');
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengaturan otomatis tidak tersedia. Buka Setelan > Aplikasi > KontrolSehat > Baterai.',
          ),
        ),
      );
    }
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang KontrolSehat'),
        content: const Text(
          'KontrolSehat versi 1.0.0\n\n'
          'KontrolSehat membantu mencatat dan mengingatkan. Aplikasi ini tidak memberikan diagnosis atau saran pengobatan. Ikuti anjuran dokter atau tenaga kesehatan Anda. Seluruh data pada versi ini adalah data simulasi.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    final controller = TextEditingController();
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus akun'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Ketik "HAPUS" untuk menghapus seluruh akun dan data secara permanen.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Ketik HAPUS'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              if (controller.text.trim() != 'HAPUS') return;
              Navigator.of(dialogCtx).pop();
              await Services.auth.deleteAccount();
              await NotificationService.instance.cancelAll();
              await Services.auth.signOut();
              if (mounted) {
                navigator.popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Hapus permanen'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}
