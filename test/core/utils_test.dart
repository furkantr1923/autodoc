import 'package:autodoc/core/utils/dates.dart';
import 'package:autodoc/core/utils/formatters.dart';
import 'package:autodoc/core/utils/number_parse.dart';
import 'package:autodoc/core/utils/text_normalize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('NumberParse.decimal', () {
    test('Türkçe ve İngilizce biçimler', () {
      expect(NumberParse.decimal('1.234,56'), 1234.56);
      expect(NumberParse.decimal('1234,5'), 1234.5);
      expect(NumberParse.decimal('45.5'), 45.5);
      expect(NumberParse.decimal('1,234.56'), 1234.56);
      expect(NumberParse.decimal(' 42 '), 42);
    });

    test('geçersiz girişler null döner', () {
      expect(NumberParse.decimal(''), isNull);
      expect(NumberParse.decimal('abc'), isNull);
      expect(NumberParse.decimal('-5'), isNull);
      expect(NumberParse.decimal('1,2,3'), isNull);
      expect(NumberParse.decimal('NaN'), isNull);
    });
  });

  group('NumberParse.integer', () {
    test('binlik ayırıcılı kilometre', () {
      expect(NumberParse.integer('85.400'), 85400);
      expect(NumberParse.integer('120 000'), 120000);
      expect(NumberParse.integer('0'), 0);
    });

    test('geçersiz girişler', () {
      expect(NumberParse.integer('-5'), isNull);
      expect(NumberParse.integer('12,5'), isNull);
      expect(NumberParse.integer('99999999999999999999999'), isNull);
    });
  });

  group('Türkçe arama sadeleştirme', () {
    test('büyük/küçük harf ve Türkçe karakterler', () {
      expect(foldForSearch('İSTANBUL Işık Çağrı'), 'istanbul isik cagri');
      expect(foldForSearch('Şanzıman Yağı'), 'sanziman yagi');
      expect(foldForSearch('ÖZGÜR'), 'ozgur');
    });

    test('plaka normalleştirme', () {
      expect(normalizePlate('  34   abc 123 '), '34 ABC 123');
      expect(plateKey('34 ABC-123'), '34ABC123');
      expect(emptyToNull('   '), isNull);
      expect(emptyToNull(' a '), 'a');
    });
  });

  group('Tarih ve biçimlendirme', () {
    test('veritabanı tarih biçimi gidiş-dönüş', () {
      final d = DateTime(2026, 2, 9);
      expect(Dates.toDb(d), '2026-02-09');
      expect(Dates.fromDb('2026-02-09'), d);
    });

    test('Türkçe tarih ve sayı biçimleri', () {
      expect(Fmt.date(DateTime(2026, 11, 23)), '23 Kasım 2026');
      expect(Fmt.dateShort(DateTime(2026, 1, 5)), '05.01.2026');
      expect(Fmt.km(85400), '85.400 km');
      expect(Fmt.decimal(42.5), '42,5');
      expect(Fmt.money(1820), contains('1.820,00'));
      expect(Fmt.editableDecimal(45.5), '45,5');
      expect(Fmt.editableDecimal(40), '40');
    });
  });
}
