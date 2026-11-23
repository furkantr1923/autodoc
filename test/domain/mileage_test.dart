import 'package:autodoc/data/models/enums.dart';
import 'package:autodoc/domain/mileage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  final today = DateTime(2026, 11, 23);
  final history = [
    MileageEntry(date: DateTime(2026, 1, 10), mileage: 10000, origin: MileageOrigin.fuel),
    MileageEntry(date: DateTime(2026, 3, 1), mileage: 12000, origin: MileageOrigin.maintenance),
    MileageEntry(date: DateTime(2026, 6, 15), mileage: 15500, origin: MileageOrigin.service),
  ];

  group('MileageValidator.validate', () {
    test('kronolojik ve artan değer uyarı üretmez', () {
      final r = MileageValidator.validate(mileage: 16000, date: DateTime(2026, 7, 1), today: today, history: history);
      expect(r.isValid, isTrue);
      expect(r.hasWarnings, isFalse);
    });

    test('araya giren geçmiş tarihli tutarlı kayıt kabul edilir', () {
      final r = MileageValidator.validate(mileage: 11000, date: DateTime(2026, 2, 1), today: today, history: history);
      expect(r.isValid, isTrue);
      expect(r.hasWarnings, isFalse);
    });

    test('önceki kayıttan düşük kilometre şüpheli düşüş uyarısı verir', () {
      final r = MileageValidator.validate(mileage: 15000, date: DateTime(2026, 7, 1), today: today, history: history);
      expect(r.isValid, isTrue);
      expect(r.warnings, hasLength(1));
      expect(r.warnings.first, contains('düşüş'));
    });

    test('sonraki kayıttan yüksek kilometre tutarsızlık uyarısı verir', () {
      final r = MileageValidator.validate(mileage: 13000, date: DateTime(2026, 2, 1), today: today, history: history);
      expect(r.warnings, hasLength(1));
      expect(r.warnings.first, contains('tutarsız'));
    });

    test('negatif kilometre engellenir', () {
      final r = MileageValidator.validate(mileage: -1, date: today, today: today, history: history);
      expect(r.isValid, isFalse);
      expect(r.error, 'Kilometre negatif olamaz.');
    });

    test('gerçek dışı büyük kilometre engellenir', () {
      final r = MileageValidator.validate(mileage: 2000001, date: today, today: today, history: const []);
      expect(r.isValid, isFalse);
    });

    test('gelecek tarihli kayıt engellenir', () {
      final r = MileageValidator.validate(
        mileage: 20000,
        date: DateTime(2026, 11, 24),
        today: today,
        history: history,
      );
      expect(r.error, 'Gelecek tarihli kayıt girilemez.');
    });

    test('bugünün tarihi kabul edilir', () {
      final r = MileageValidator.validate(mileage: 20000, date: DateTime(2026, 11, 23, 23, 59), today: today, history: history);
      expect(r.isValid, isTrue);
    });
  });

  group('MileageValidator.validateText', () {
    test('boş, negatif ve harfli girişler', () {
      expect(MileageValidator.validateText('', parsed: null), 'Kilometre girin.');
      expect(MileageValidator.validateText('', parsed: null, isRequired: false), isNull);
      expect(MileageValidator.validateText('-50', parsed: null), 'Kilometre negatif olamaz.');
      expect(MileageValidator.validateText('12a', parsed: null), contains('Geçerli'));
      expect(MileageValidator.validateText('85.400', parsed: 85400), isNull);
    });
  });

  group('Kilometre geçmişi', () {
    test('araç kaydı ve kayıtlar tarihe göre eskiden yeniye sıralanır', () {
      final v = sampleVehicle(initialMileage: 100000).copyWith(id: 1);
      final entries = buildMileageHistory(
        vehicle: v,
        fuel: [sampleFuel(1, date: DateTime(2026, 12, 1), mileage: 101000).copyWith(id: 5)],
        services: [sampleService(1, date: DateTime(2025, 5, 1), mileage: 90000).copyWith(id: 7)],
      );
      expect(entries.map((e) => e.mileage), [90000, 100000, 101000]);
      expect(entries.first.origin, MileageOrigin.maintenance);
      expect(entries[1].origin, MileageOrigin.registration);
      expect(entries.every((e) => e.source == MileageSource.manual), isTrue);
    });

    test('düzenlenen kayıt geçmişten çıkarılır', () {
      final v = sampleVehicle(initialMileage: null).copyWith(id: 1);
      final entries = buildMileageHistory(
        vehicle: v,
        fuel: [
          sampleFuel(1, date: DateTime(2026, 1, 1), mileage: 1000).copyWith(id: 1),
          sampleFuel(1, date: DateTime(2026, 2, 1), mileage: 2000).copyWith(id: 2),
        ],
        services: const [],
        excludeFuelId: 2,
      );
      expect(entries, hasLength(1));
    });

    test('son bilinen kilometre en son tarihli değerdir', () {
      expect(lastKnownMileage(history), 15500);
      expect(lastKnownMileage(const []), isNull);
      final sameDay = [
        MileageEntry(date: DateTime(2026, 5, 1), mileage: 500, origin: MileageOrigin.fuel),
        MileageEntry(date: DateTime(2026, 5, 1), mileage: 700, origin: MileageOrigin.service),
      ];
      expect(lastKnownMileage(sameDay), 700);
    });
  });
}
