import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'self_test.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppLocale();

  // CI ve hata ayıklama için: autodoc.exe --self-test=rapor.txt
  for (final arg in args) {
    if (arg.startsWith('--self-test=')) {
      final code = await runSelfTest(arg.substring('--self-test='.length));
      exit(code);
    }
  }

  try {
    final paths = await resolveAppPaths();
    final state = await createAppState(
      factory: platformDatabaseFactory(),
      databasePath: paths.databasePath,
      photosDir: paths.photosDir,
    );
    runApp(AutodocApp(state: state, portable: paths.portable));
  } catch (error) {
    runApp(StartupErrorApp(message: '$error'));
  }
}
