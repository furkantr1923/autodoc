/// Kullanıcının girdiği sayıları Türkçe alışkanlıklarını da kabul ederek çözer.
///
/// Örnekler: `1.234,56` → 1234.56, `1234,5` → 1234.5, `45.5` → 45.5,
/// kilometre için `85.400` → 85400.
abstract final class NumberParse {
  static final RegExp _plainDecimal = RegExp(r'^\d+(\.\d+)?$');
  static final RegExp _digits = RegExp(r'^\d+$');

  static double? decimal(String input) {
    var s = input.trim().replaceAll(' ', '');
    if (s.isEmpty) return null;
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      if (','.allMatches(s).length > 1) return null;
      s = s.replaceAll(',', '.');
    } else if ('.'.allMatches(s).length > 1) {
      s = s.replaceAll('.', '');
    }
    if (!_plainDecimal.hasMatch(s)) return null;
    final value = double.tryParse(s);
    if (value == null || !value.isFinite) return null;
    return value;
  }

  /// Tam sayı (kilometre, model yılı). Binlik ayırıcı olarak nokta ve boşluk kabul edilir.
  static int? integer(String input) {
    final s = input.trim().replaceAll(RegExp(r'[\s.]'), '');
    if (s.isEmpty || !_digits.hasMatch(s)) return null;
    return int.tryParse(s);
  }

  static bool looksNegative(String input) => input.trim().startsWith('-');
}
