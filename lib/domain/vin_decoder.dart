/// Çevrimdışı VIN (şasi numarası) çözümleyici.
///
/// Yalnızca ISO 3779 standardına dayanan, güvenilir bilgileri çıkarır:
/// - Biçim doğrulaması (17 karakter, I/O/Q harfleri yok)
/// - Üretici (WMI — ilk 3 karakter), yerleşik ve sınırlı bir tablodan
/// - Bölge (ilk karakter)
/// - Model yılı ve kontrol hanesi: YALNIZCA Kuzey Amerika VIN'leri için.
///   Avrupa ve diğer bölgelerde 10. hane model yılını güvenilir biçimde
///   göstermediğinden bu bilgi bilerek üretilmez.
///
/// İnternet bağlantısı kullanılmaz.
class VinInfo {
  const VinInfo({
    required this.vin,
    required this.isValidFormat,
    this.formatError,
    this.manufacturer,
    this.region,
    this.modelYear,
    this.checkDigitValid,
  });

  final String vin;
  final bool isValidFormat;
  final String? formatError;
  final String? manufacturer;
  final String? region;
  final int? modelYear;

  /// Kuzey Amerika VIN'lerinde 9. hane doğrulaması; diğerlerinde null.
  final bool? checkDigitValid;

  bool get hasAnyInfo => manufacturer != null || region != null || modelYear != null;
}

abstract final class VinDecoder {
  static final RegExp _vinPattern = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
  static final RegExp _chassisPattern = RegExp(r'^[A-Z0-9]{5,17}$');

  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  /// Form alanı doğrulaması. Eski araç/motosiklet/traktör şasi numaraları
  /// 17 haneden kısa olabileceği için 5–17 karakter kabul edilir.
  static String? validateField(String? input) {
    final v = normalize(input ?? '');
    if (v.isEmpty) return null;
    if (!_chassisPattern.hasMatch(v)) {
      return 'Şasi numarası 5–17 harf/rakamdan oluşmalı.';
    }
    if (v.length == 17 && !_vinPattern.hasMatch(v)) {
      return '17 haneli VIN, I, O ve Q harflerini içeremez.';
    }
    return null;
  }

  static VinInfo decode(String input) {
    final vin = normalize(input);
    if (vin.length != 17) {
      return VinInfo(
        vin: vin,
        isValidFormat: false,
        formatError: 'Çözümleme için VIN tam 17 karakter olmalı.',
      );
    }
    if (!_vinPattern.hasMatch(vin)) {
      return VinInfo(
        vin: vin,
        isValidFormat: false,
        formatError: 'VIN yalnızca harf ve rakam içerir; I, O ve Q harfleri kullanılmaz.',
      );
    }

    final wmi = vin.substring(0, 3);
    final manufacturer = _wmi[wmi];
    final region = _region(vin[0]);
    final northAmerica = '12345'.contains(vin[0]);

    int? year;
    bool? checkOk;
    if (northAmerica) {
      checkOk = _checkDigit(vin) == vin[8];
      year = _northAmericaModelYear(vin);
    }

    return VinInfo(
      vin: vin,
      isValidFormat: true,
      manufacturer: manufacturer,
      region: region,
      modelYear: year,
      checkDigitValid: checkOk,
    );
  }

  static String? _region(String c) {
    if ('ABCDEFGH'.contains(c)) return 'Afrika';
    if ('JKLMNPR'.contains(c)) return 'Asya';
    if ('STUVWXYZ'.contains(c)) return 'Avrupa';
    if ('12345'.contains(c)) return 'Kuzey Amerika';
    if ('67'.contains(c)) return 'Okyanusya';
    if ('890'.contains(c)) return 'Güney Amerika';
    return null;
  }

  static const String _yearCodes = 'ABCDEFGHJKLMNPRSTVWXY123456789';

  /// NHTSA kuralı: 7. hane harf ise 2010–2039, rakam ise 1980–2009 döngüsü.
  static int? _northAmericaModelYear(String vin) {
    final index = _yearCodes.indexOf(vin[9]);
    if (index < 0) return null;
    final laterCycle = RegExp(r'[A-Z]').hasMatch(vin[6]);
    return (laterCycle ? 2010 : 1980) + index;
  }

  static const Map<String, int> _translit = {
    'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
    'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9,
    'S': 2, 'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9,
  };
  static const List<int> _weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];

  static String _checkDigit(String vin) {
    var sum = 0;
    for (var i = 0; i < 17; i++) {
      final ch = vin[i];
      final value = int.tryParse(ch) ?? _translit[ch] ?? 0;
      sum += value * _weights[i];
    }
    final r = sum % 11;
    return r == 10 ? 'X' : '$r';
  }

  /// Yaygın üretici kodları (World Manufacturer Identifier). Liste bilerek
  /// sınırlı tutulmuştur; bulunamayan kodlar için üretici gösterilmez.
  static const Map<String, String> _wmi = {
    // Almanya
    'WVW': 'Volkswagen', 'WV1': 'Volkswagen Ticari', 'WV2': 'Volkswagen Ticari',
    'WAU': 'Audi', 'WBA': 'BMW', 'WBS': 'BMW M', 'WBY': 'BMW i', 'WB1': 'BMW Motorrad',
    'WMW': 'MINI', 'WDB': 'Mercedes-Benz', 'WDD': 'Mercedes-Benz', 'WDC': 'Mercedes-Benz',
    'W1K': 'Mercedes-Benz', 'W1N': 'Mercedes-Benz', 'WDF': 'Mercedes-Benz Ticari',
    'W1V': 'Mercedes-Benz Ticari', 'W0L': 'Opel', 'W0V': 'Opel', 'WF0': 'Ford',
    'WP0': 'Porsche', 'WP1': 'Porsche', 'WMA': 'MAN', 'WKK': 'Setra',
    // Fransa / İspanya / Romanya
    'VF1': 'Renault', 'VF3': 'Peugeot', 'VR3': 'Peugeot', 'VF7': 'Citroën',
    'VR7': 'Citroën', 'VR1': 'DS Automobiles', 'VF6': 'Renault Trucks', 'VNK': 'Toyota',
    'VSS': 'SEAT', 'UU1': 'Dacia', 'VBK': 'KTM',
    // İtalya
    'ZFA': 'Fiat', 'ZAR': 'Alfa Romeo', 'ZFF': 'Ferrari', 'ZHW': 'Lamborghini',
    'ZAM': 'Maserati', 'ZLA': 'Lancia', 'ZCF': 'Iveco', 'ZDM': 'Ducati', 'ZD4': 'Aprilia',
    'ZAP': 'Piaggio', 'ZGU': 'Moto Guzzi', 'ZAC': 'Jeep',
    // Çekya / Macaristan / İsveç / Hollanda
    'TMB': 'Škoda', 'TMA': 'Hyundai', 'TRU': 'Audi', 'TSM': 'Suzuki',
    'YV1': 'Volvo', 'YS2': 'Scania', 'YS3': 'Saab', 'XLR': 'DAF', 'XP7': 'Tesla',
    // Birleşik Krallık
    'SAL': 'Land Rover', 'SAJ': 'Jaguar', 'SCC': 'Lotus', 'SCF': 'Aston Martin',
    'SHH': 'Honda', 'SJN': 'Nissan', 'SB1': 'Toyota', 'SMT': 'Triumph',
    // Türkiye
    'NM0': 'Ford Otosan', 'NMT': 'Toyota', 'NLH': 'Hyundai',
    // Japonya
    'JHM': 'Honda', 'JH2': 'Honda Motosiklet', 'JN1': 'Nissan', 'JTD': 'Toyota',
    'JTE': 'Toyota', 'JTN': 'Toyota', 'JTM': 'Toyota', 'JTH': 'Lexus', 'JTJ': 'Lexus',
    'JMZ': 'Mazda', 'JM1': 'Mazda', 'JF1': 'Subaru', 'JF2': 'Subaru', 'JS1': 'Suzuki Motosiklet',
    'JS2': 'Suzuki', 'JS3': 'Suzuki', 'JSA': 'Suzuki', 'JMB': 'Mitsubishi',
    'JYA': 'Yamaha Motosiklet', 'JKA': 'Kawasaki',
    // Kore / Hindistan / Çin
    'KMH': 'Hyundai', 'KNA': 'Kia', 'KND': 'Kia', 'KPT': 'SsangYong',
    'MA3': 'Suzuki', 'MAL': 'Hyundai', 'ME4': 'Honda Motosiklet', 'MD2': 'Bajaj',
    'MLH': 'Honda Motosiklet', 'MH1': 'Honda Motosiklet',
    'LSV': 'Volkswagen', 'LFV': 'Volkswagen', 'LBV': 'BMW', 'LGX': 'BYD', 'L6T': 'Geely',
    'LVV': 'Chery', 'LRW': 'Tesla',
    // Kuzey Amerika
    '1FA': 'Ford', '1FT': 'Ford', '1FM': 'Ford', '1G1': 'Chevrolet', '1GC': 'Chevrolet',
    '1HG': 'Honda', '2HG': 'Honda', '4T1': 'Toyota', '5UX': 'BMW', '3VW': 'Volkswagen',
    '1C4': 'Chrysler / Jeep', '5YJ': 'Tesla', '7SA': 'Tesla', '1HD': 'Harley-Davidson',
    'JA3': 'Mitsubishi', 'JA4': 'Mitsubishi',
  };
}
