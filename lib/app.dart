import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_info.dart';
import 'core/theme/app_theme.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'ui/shell/home_shell.dart';

class AutodocApp extends StatelessWidget {
  const AutodocApp({super.key, required this.state, this.portable = false});

  final AppState state;
  final bool portable;

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();
    return AppScope(
      state: state,
      child: MaterialApp(
        title: AppInfo.name,
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HomeShell(portable: portable),
      ),
    );
  }
}

/// Veritabanı açılamazsa gösterilen, Türkçe hata ekranı.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'AUTODOC başlatılamadı',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Yerel veritabanı açılırken bir sorun oluştu. Uygulamayı yeniden başlatmayı deneyin. '
                    'Sorun devam ederse cihazda yeterli boş alan olduğundan emin olun.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
