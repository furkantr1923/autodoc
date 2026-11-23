import 'dart:io';

import 'package:path/path.dart' as p;

/// Araç fotoğraflarını uygulamanın yerel veri klasörüne kopyalar.
/// Veritabanında yalnızca dosya adı saklanır.
class PhotoStore {
  PhotoStore(this.directoryPath);

  final String directoryPath;

  static const List<String> _allowed = ['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif'];

  String resolve(String fileName) => p.join(directoryPath, fileName);

  Future<String> importPhoto(String sourcePath, int vehicleId) async {
    await Directory(directoryPath).create(recursive: true);
    final ext = p.extension(sourcePath).toLowerCase();
    final safeExt = _allowed.contains(ext) ? ext : '.jpg';
    final name = 'arac_${vehicleId}_${DateTime.now().millisecondsSinceEpoch}$safeExt';
    await File(sourcePath).copy(p.join(directoryPath, name));
    return name;
  }

  Future<void> delete(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;
    final file = File(resolve(fileName));
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Dosya kilitli veya erişilemiyorsa sessizce geçilir; veri bütünlüğü etkilenmez.
    }
  }
}
