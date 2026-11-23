/// Arama için Türkçe duyarlı metin sadeleştirme.
///
/// Büyük/küçük harf ve Türkçe karakter farklarını yok sayar:
/// "İSTANBUL Işık Çağrı" → "istanbul isik cagri".
String foldForSearch(String input) {
  final lowered = input.replaceAll('İ', 'i').replaceAll('I', 'i').toLowerCase();
  final buffer = StringBuffer();
  for (final ch in lowered.split('')) {
    buffer.write(_foldMap[ch] ?? ch);
  }
  return buffer.toString();
}

const Map<String, String> _foldMap = {
  'ı': 'i',
  'ç': 'c',
  'ğ': 'g',
  'ö': 'o',
  'ş': 's',
  'ü': 'u',
  'â': 'a',
  'î': 'i',
  'û': 'u',
  '̇': '',
};

/// Plakayı standart biçime getirir: büyük harf, tek boşluk.
String normalizePlate(String input) =>
    input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

/// Plaka karşılaştırması için boşluk ve tireleri kaldırır.
String plateKey(String input) =>
    normalizePlate(input).replaceAll(RegExp(r'[\s-]'), '');

/// Boş metni null'a çevirir.
String? emptyToNull(String? value) {
  if (value == null) return null;
  final t = value.trim();
  return t.isEmpty ? null : t;
}
