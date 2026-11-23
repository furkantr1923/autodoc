/// Tarih yardımcıları.
///
/// Uygulamadaki işlem tarihleri (yakıt, bakım, sigorta, muayene) saat bilgisi
/// taşımaz; veritabanında `yyyy-MM-dd` biçiminde saklanır. Gün farkları,
/// yaz saati geçişlerinden etkilenmemesi için UTC üzerinden hesaplanır.
abstract final class Dates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String toDb(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime fromDb(String value) {
    final parts = value.split('-');
    if (parts.length < 3) {
      throw FormatException('Geçersiz tarih: $value');
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2].substring(0, 2)),
    );
  }

  static DateTime? fromDbNullable(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return fromDb(value);
  }

  /// [from] tarihinden [to] tarihine kaç gün olduğunu döndürür (negatif olabilir).
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
