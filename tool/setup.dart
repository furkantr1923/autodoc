// AUTODOC platform kurulumu.
//
// Android ve Windows platform klasörlerini, kullanılan Flutter sürümünün resmi
// şablonundan üretir ve AUTODOC'a özel ayarları tek bir yerde uygular:
//   - Uygulama adı: AUTODOC (Android etiketi, Windows pencere başlığı, dosya bilgileri)
//   - Koyu açılış ekranı (beyaz flaş olmadan)
//   - Pencere boyutu
//   - Uygulama simgeleri (flutter_launcher_icons)
//
// Kullanım (proje kökünde):
//   flutter pub get
//   dart run tool/setup.dart
//
// ignore_for_file: avoid_print

import 'dart:io';

const String _org = 'com.furkanbaykal';
const String _projectName = 'autodoc';
const String _navy = '#FF060A12';

Future<void> main(List<String> args) async {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln('Hata: Bu komutu proje kök klasöründe çalıştırın.');
    exit(64);
  }

  final needsCreate = !Directory('android').existsSync() || !Directory('windows').existsSync();
  if (needsCreate) {
    await _run('flutter', [
      'create',
      '--platforms=android,windows',
      '--org',
      _org,
      '--project-name',
      _projectName,
      '.',
    ]);
  } else {
    print('Platform klasörleri mevcut; yalnızca AUTODOC ayarları uygulanacak.');
  }

  _patchAndroid();
  _patchWindows();

  if (!args.contains('--no-icons')) {
    await _run('dart', ['run', 'flutter_launcher_icons']);
  }

  print('\nAUTODOC platform yapılandırması tamamlandı.');
}

Future<void> _run(String executable, List<String> arguments) async {
  print('\n> $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await process.exitCode;
  if (code != 0) {
    stderr.writeln('Komut başarısız oldu (çıkış kodu $code).');
    exit(code);
  }
}

void _patchAndroid() {
  _replace(
    'android/app/src/main/AndroidManifest.xml',
    {'android:label="$_projectName"': 'android:label="AUTODOC"'},
  );

  const launchBackground = '''<?xml version="1.0" encoding="utf-8"?>
<!-- AUTODOC açılış arka planı (koyu lacivert) -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <solid android:color="$_navy" />
        </shape>
    </item>
</layer-list>
''';
  for (final dir in ['drawable', 'drawable-v21']) {
    final file = File('android/app/src/main/res/$dir/launch_background.xml');
    if (file.parent.existsSync()) {
      file.writeAsStringSync(launchBackground);
      print('Güncellendi: ${file.path}');
    }
  }

  _replace(
    'android/app/src/main/res/values/styles.xml',
    {'@android:style/Theme.Light.NoTitleBar': '@android:style/Theme.Black.NoTitleBar'},
    mustExist: false,
  );
}

void _patchWindows() {
  _replace(
    'windows/runner/main.cpp',
    {
      'window.Create(L"$_projectName"': 'window.Create(L"AUTODOC"',
      'Win32Window::Size size(1280, 720);': 'Win32Window::Size size(1360, 860);',
    },
    mustExist: false,
  );
  _replaceRegex(
    'windows/runner/Runner.rc',
    {
      RegExp(r'VALUE "CompanyName", "[^"]*"'): 'VALUE "CompanyName", "Furkan Baykal"',
      RegExp(r'VALUE "FileDescription", "[^"]*"'): 'VALUE "FileDescription", "AUTODOC"',
      RegExp(r'VALUE "ProductName", "[^"]*"'): 'VALUE "ProductName", "AUTODOC"',
      RegExp(r'VALUE "LegalCopyright", "[^"]*"'): 'VALUE "LegalCopyright", "Copyright (C) 2026 Furkan Baykal"',
    },
  );
}

void _replace(String path, Map<String, String> rules, {bool mustExist = true}) {
  final file = File(path);
  if (!file.existsSync()) {
    if (mustExist) {
      stderr.writeln('Uyarı: $path bulunamadı.');
    }
    return;
  }
  try {
    var content = file.readAsStringSync();
    for (final entry in rules.entries) {
      if (!content.contains(entry.key) && !content.contains(entry.value)) {
        stderr.writeln('Uyarı: $path içinde "${entry.key}" bulunamadı.');
      }
      content = content.replaceAll(entry.key, entry.value);
    }
    file.writeAsStringSync(content);
    print('Güncellendi: $path');
  } on FileSystemException catch (e) {
    stderr.writeln('Uyarı: $path güncellenemedi: $e');
  } on FormatException catch (e) {
    stderr.writeln('Uyarı: $path okunamadı (kodlama): $e');
  }
}

void _replaceRegex(String path, Map<RegExp, String> rules) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Uyarı: $path bulunamadı.');
    return;
  }
  try {
    var content = file.readAsStringSync();
    for (final entry in rules.entries) {
      content = content.replaceAll(entry.key, entry.value);
    }
    file.writeAsStringSync(content);
    print('Güncellendi: $path');
  } on FileSystemException catch (e) {
    stderr.writeln('Uyarı: $path güncellenemedi: $e');
  } on FormatException catch (e) {
    stderr.writeln('Uyarı: $path okunamadı (kodlama): $e');
  }
}
