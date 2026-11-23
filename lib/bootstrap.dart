import 'dart:io';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi, sqfliteFfiInit;

import 'data/database/app_database.dart';
import 'data/photo_store.dart';
import 'state/app_state.dart';

/// Türkçe tarih/sayı biçimlerini hazırlar.
Future<void> initializeAppLocale() async {
  Intl.defaultLocale = 'tr_TR';
  await initializeDateFormatting('tr_TR');
}

/// Platforma uygun SQLite fabrikası:
/// - Android: null → sqflite (sistemin SQLite'ı)
/// - Windows: sqflite_common_ffi + uygulamayla gelen sqlite3.dll
DatabaseFactory? platformDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return null;
}

class AppPaths {
  const AppPaths({required this.databasePath, required this.photosDir, this.portable = false});

  final String databasePath;
  final String photosDir;

  /// Taşınabilir (portable) sürümde veriler uygulama klasöründe tutulur.
  final bool portable;
}

/// Verilerin yalnızca bu cihazda saklanacağı konumları belirler.
Future<AppPaths> resolveAppPaths() async {
  if (Platform.isWindows) {
    final portableDir = _portableDataDir();
    if (portableDir != null) {
      return AppPaths(
        databasePath: p.join(portableDir, 'autodoc.db'),
        photosDir: p.join(portableDir, 'fotograflar'),
        portable: true,
      );
    }
    final support = await getApplicationSupportDirectory();
    return AppPaths(
      databasePath: p.join(support.path, 'autodoc.db'),
      photosDir: p.join(support.path, 'fotograflar'),
    );
  }
  final dbDir = await getDatabasesPath();
  final support = await getApplicationSupportDirectory();
  return AppPaths(
    databasePath: p.join(dbDir, 'autodoc.db'),
    photosDir: p.join(support.path, 'fotograflar'),
  );
}

/// `portable.txt` dosyası uygulamanın yanında varsa ve klasör yazılabilirse
/// veriler `AUTODOC-Veri` klasöründe saklanır.
String? _portableDataDir() {
  try {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    if (!File(p.join(exeDir, 'portable.txt')).existsSync()) return null;
    final dir = Directory(p.join(exeDir, 'AUTODOC-Veri'));
    dir.createSync(recursive: true);
    final probe = File(p.join(dir.path, '.yazma_testi'));
    probe.writeAsStringSync('ok', flush: true);
    probe.deleteSync();
    return dir.path;
  } catch (_) {
    return null;
  }
}

/// Veritabanını açar ve uygulama durumunu yükler.
Future<AppState> createAppState({
  required DatabaseFactory? factory,
  required String databasePath,
  required String photosDir,
  DateTime Function()? clock,
}) async {
  await Directory(p.dirname(databasePath)).create(recursive: true);
  final database = await AppDatabase.open(factory: factory, path: databasePath);
  final state = AppState(database: database, photoStore: PhotoStore(photosDir), clock: clock);
  await state.load();
  return state;
}
