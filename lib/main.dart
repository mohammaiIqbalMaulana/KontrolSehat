import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/di/services.dart';
import 'features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const ConfigErrorApp());
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_choice');
  if (savedTheme == 'light') {
    themeModeNotifier.value = ThemeMode.light;
  } else if (savedTheme == 'dark') {
    themeModeNotifier.value = ThemeMode.dark;
  } else {
    themeModeNotifier.value = ThemeMode.system;
  }

  await NotificationService.instance.init();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseKey,
  );
  Services.init(Supabase.instance.client);

  runApp(const KontrolSehatApp());
}
