import 'package:intl/intl.dart';

/// Türkçe (tr_TR) biçimlendiriciler.
///
/// Not: Tarih biçimleri `initializeDateFormatting('tr_TR')` çağrısından sonra
/// kullanılmalıdır (bkz. `initializeAppLocale`).
abstract final class Fmt {
  static final DateFormat _date = DateFormat('d MMMM y', 'tr_TR');
  static final DateFormat _dateShort = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final DateFormat _weekday = DateFormat('EEEE', 'tr_TR');
  static final NumberFormat _int = NumberFormat.decimalPattern('tr_TR');
  static final NumberFormat _decimal = NumberFormat('#,##0.##', 'tr_TR');
  static final NumberFormat _money =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  static String date(DateTime d) => _date.format(d);
  static String dateShort(DateTime d) => _dateShort.format(d);
  static String weekday(DateTime d) => _weekday.format(d);
  static String integer(int v) => _int.format(v);
  static String km(int v) => '${_int.format(v)} km';
  static String decimal(double v) => _decimal.format(v);
  static String money(double v) => _money.format(v);

  /// Sayı alanlarını düzenleme sırasında doldurmak için (binlik ayırıcısız).
  static String editableDecimal(double v) {
    final rounded = double.parse(v.toStringAsFixed(3));
    var s = rounded.toString();
    if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
    return s.replaceAll('.', ',');
  }

  static String signedKm(int diff) {
    final sign = diff > 0 ? '+' : (diff < 0 ? '−' : '');
    return '$sign${_int.format(diff.abs())} km';
  }
}
