import 'package:autodoc/domain/fuel_math.dart';
import 'package:autodoc/domain/legal_status.dart';
import 'package:autodoc/domain/vin_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegalStatus', () {
    final today = DateTime(2026, 11, 23, 15);

    test('tarih yoksa "girilmedi"', () {
      final s = LegalStatus.evaluate(null, today: today);
      expect(s.state, LegalState.notSet);
      expect(s.shortLabel, 'Girilmedi');
    });

    test('dün dolan tarih "süresi doldu"', () {
      final s = LegalStatus.evaluate(DateTime(2026, 11, 22), today: today);
      expect(s.state, LegalState.expired);
      expect(s.daysLeft, -1);
      expect(s.detailLabel, '1 gün önce doldu');
    });

    test('bugün bitiyorsa "yaklaşıyor" ve son gün', () {
      final s = LegalStatus.evaluate(DateTime(2026, 11, 23), today: today);
      expect(s.state, LegalState.dueSoon);
      expect(s.detailLabel, 'Bugün son gün');
    });

    test('uyarı süresi sınırı (30 gün dahil)', () {
      expect(LegalStatus.evaluate(DateTime(2026, 12, 23), today: today).state, LegalState.dueSoon);
      expect(LegalStatus.evaluate(DateTime(2026, 12, 24), today: today).state, LegalState.valid);
    });

    test('özel uyarı süresi uygulanır', () {
      final s = LegalStatus.evaluate(DateTime(2026, 12, 3), today: today, warnDays: 7);
      expect(s.state, LegalState.valid);
      expect(s.daysLeft, 10);
    });

    test('yıl ve şubat geçişlerinde gün farkı doğru', () {
      final s = LegalStatus.evaluate(DateTime(2028, 3, 1), today: DateTime(2028, 2, 28));
      expect(s.daysLeft, 2); // 2028 artık yıl
    });

    test('aciliyet sıralaması', () {
      final list = [
        LegalStatus.evaluate(null, today: today),
        LegalStatus.evaluate(DateTime(2027, 6, 1), today: today),
        LegalStatus.evaluate(DateTime(2026, 12, 1), today: today),
        LegalStatus.evaluate(DateTime(2026, 10, 1), today: today),
      ]..sort(LegalStatus.compareUrgency);
      expect(list.map((s) => s.state), [
        LegalState.expired,
        LegalState.dueSoon,
        LegalState.valid,
        LegalState.notSet,
      ]);
    });
  });

  group('VinDecoder', () {
    test('Kuzey Amerika VIN: üretici, model yılı ve kontrol hanesi', () {
      final info = VinDecoder.decode('1HGCM82633A004352');
      expect(info.isValidFormat, isTrue);
      expect(info.manufacturer, 'Honda');
      expect(info.region, 'Kuzey Amerika');
      expect(info.modelYear, 2003);
      expect(info.checkDigitValid, isTrue);
    });

    test('Avrupa VIN: üretici var, model yılı bilerek üretilmez', () {
      final info = VinDecoder.decode('wvw zzz1jzxw000001');
      expect(info.isValidFormat, isTrue);
      expect(info.vin, 'WVWZZZ1JZXW000001');
      expect(info.manufacturer, 'Volkswagen');
      expect(info.region, 'Avrupa');
      expect(info.modelYear, isNull);
      expect(info.checkDigitValid, isNull);
    });

    test('Türkiye üretimi WMI', () {
      expect(VinDecoder.decode('NM0GE9F20N1234567').manufacturer, 'Ford Otosan');
    });

    test('geçersiz VIN biçimleri', () {
      expect(VinDecoder.decode('ABC').isValidFormat, isFalse);
      expect(VinDecoder.decode('WVWZZZ1JZXW00000O').isValidFormat, isFalse);
      expect(VinDecoder.validateField('WVWZZZ1JZXW00000O'), isNotNull);
      expect(VinDecoder.validateField('AB12345'), isNull, reason: 'eski kısa şasi numarası kabul edilir');
      expect(VinDecoder.validateField(''), isNull);
      expect(VinDecoder.validateField('AB#1'), isNotNull);
    });

    test('bozuk kontrol hanesi tespit edilir', () {
      final info = VinDecoder.decode('1HGCM82643A004352');
      expect(info.checkDigitValid, isFalse);
    });
  });

  group('FuelMath', () {
    test('toplam = miktar × birim fiyat (kuruş yuvarlama)', () {
      expect(FuelMath.total(40, 45.5), 1820.0);
      expect(FuelMath.total(33.33, 41.237), 1374.43);
    });

    test('birim fiyat = toplam ÷ miktar', () {
      expect(FuelMath.unitPrice(1820, 40), 45.5);
      expect(FuelMath.unitPrice(100, 0), isNull);
    });
  });
}
