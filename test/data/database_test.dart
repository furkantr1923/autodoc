import 'dart:io';

import 'package:autodoc/data/models/enums.dart';
import 'package:autodoc/domain/legal_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers.dart';

/// Gerçek SQLite (FFI) ile veritabanı ve uygulama durumu testleri.
void main() {
  late Directory dir;

  setUpAll(() async {
    ensureFfi();
    await initializeDateFormatting('tr_TR');
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('autodoc_test_');
  });

  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  test('ilk açılışta veritabanı boş ve şema hazır', () async {
    final state = await createTestState(dir);
    expect(state.vehicles, isEmpty);
    final tables = await state.database.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
    );
    expect(tables.map((r) => r['name']), ['fuel_records', 'service_records', 'settings', 'vehicles']);
    final fk = await state.database.db.rawQuery('PRAGMA foreign_keys');
    expect(fk.first.values.first, 1);
    await state.database.close();
  });

  test('araç ekleme, düzenleme ve Türkçe karakterlerin korunması', () async {
    final state = await createTestState(dir);
    final id = await state.saveVehicle(sampleVehicle(make: 'Türk Traktör', model: 'Şahin 4x4', plate: '19 ÇŞ 001'));
    var v = state.vehicleById(id)!;
    expect(v.make, 'Türk Traktör');
    expect(v.model, 'Şahin 4x4');
    expect(state.selectedVehicle?.id, id, reason: 'ilk araç otomatik seçilir');

    await state.saveVehicle(sampleVehicle(make: 'Türk Traktör', model: 'Doğan', plate: '19 ÇŞ 001').copyWith(id: id));
    v = state.vehicleById(id)!;
    expect(v.model, 'Doğan');
    expect(state.vehicles, hasLength(1));
    await state.database.close();
  });

  test('yeniden açılışta tüm veriler kalıcıdır', () async {
    var state = await createTestState(dir);
    final id = await state.saveVehicle(sampleVehicle(initialMileage: null, insurance: DateTime(2026, 12, 1)));
    await state.saveFuel(sampleFuel(id, date: DateTime(2026, 11, 1), mileage: 100500, station: 'Çorum Merkez'));
    await state.saveService(sampleService(id, date: DateTime(2026, 11, 10), mileage: 100900));
    await state.setWarnDays(15);
    await state.database.close();

    state = await createTestState(dir);
    expect(state.vehicles, hasLength(1));
    expect(state.fuelFor(id).single.station, 'Çorum Merkez');
    expect(state.servicesFor(id).single.description, 'Motor yağı değişimi');
    expect(state.warnDays, 15);
    expect(state.vehicleById(id)!.insuranceExpiry, DateTime(2026, 12, 1));
    expect(state.lastMileage(id), 100900);
    await state.database.close();
  });

  test('kayıt düzenleme ve silme', () async {
    final state = await createTestState(dir);
    final id = await state.saveVehicle(sampleVehicle());
    final fuelId = await state.saveFuel(sampleFuel(id, date: DateTime(2026, 11, 1), mileage: 100500));
    final updated = sampleFuel(id, date: DateTime(2026, 11, 2), mileage: 100600).copyWith(id: fuelId);
    await state.saveFuel(updated);
    expect(state.fuelFor(id).single.mileage, 100600);
    expect(state.fuelFor(id).single.date, DateTime(2026, 11, 2));

    final serviceId = await state.saveService(sampleService(id, date: DateTime(2026, 11, 3), mileage: 100700));
    await state.deleteService(serviceId);
    await state.deleteFuel(fuelId);
    expect(state.recordsFor(id), isEmpty);
    await state.database.close();
  });

  test('araç silinince yakıt ve servis kayıtları da silinir (CASCADE)', () async {
    final state = await createTestState(dir);
    final a = await state.saveVehicle(sampleVehicle(plate: '34 A 1'));
    final b = await state.saveVehicle(sampleVehicle(make: 'Yamaha', model: 'MT-07', plate: '34 B 2', category: VehicleCategory.motorcycle));
    await state.saveFuel(sampleFuel(a, date: DateTime(2026, 11, 1), mileage: 100500));
    await state.saveService(sampleService(a, date: DateTime(2026, 11, 2), mileage: 100600));
    await state.saveFuel(sampleFuel(b, date: DateTime(2026, 11, 1), mileage: 100500));

    await state.deleteVehicle(a);
    expect(state.vehicles.map((v) => v.id), [b]);
    final orphanFuel = await state.database.db.query('fuel_records', where: 'vehicle_id = ?', whereArgs: [a]);
    final orphanService = await state.database.db.query('service_records', where: 'vehicle_id = ?', whereArgs: [a]);
    expect(orphanFuel, isEmpty);
    expect(orphanService, isEmpty);
    expect(state.fuelFor(b), hasLength(1));
    expect(state.selectedVehicle?.id, b, reason: 'silinen seçili aracın yerine kalan araç seçilir');
    await state.database.close();
  });

  test('veritabanı negatif kilometreyi kısıtlama ile reddeder', () async {
    final state = await createTestState(dir);
    final id = await state.saveVehicle(sampleVehicle());
    await expectLater(
      state.saveFuel(sampleFuel(id, date: DateTime(2026, 11, 1), mileage: -10)),
      throwsA(anything),
    );
    expect(state.fuelFor(id), isEmpty);
    await state.database.close();
  });

  test('plaka benzersizliği boşluk ve harf büyüklüğünden bağımsızdır', () async {
    final state = await createTestState(dir);
    final id = await state.saveVehicle(sampleVehicle(plate: '34 ABC 123'));
    expect(state.isPlateTaken('34abc123'), isTrue);
    expect(state.isPlateTaken('34 abc 123', excludeId: id), isFalse);
    expect(state.isPlateTaken('06 XYZ 1'), isFalse);
    await state.database.close();
  });

  test('kilometre doğrulaması aracın kayıt geçmişini kullanır', () async {
    final state = await createTestState(dir);
    final id = await state.saveVehicle(sampleVehicle(initialMileage: 100000));
    final fuelId = await state.saveFuel(sampleFuel(id, date: DateTime(2026, 11, 20), mileage: 101000));

    expect(state.validateMileage(vehicleId: id, date: DateTime(2026, 11, 23), mileage: 101500).hasWarnings, isFalse);
    expect(state.validateMileage(vehicleId: id, date: DateTime(2026, 11, 23), mileage: 99000).hasWarnings, isTrue);
    // Düzenlenen kaydın kendisiyle karşılaştırma yapılmaz.
    expect(
      state.validateMileage(vehicleId: id, date: DateTime(2026, 11, 20), mileage: 99500, excludeFuelId: fuelId).hasWarnings,
      isFalse,
    );
    expect(state.validateMileage(vehicleId: id, date: DateTime(2026, 11, 24), mileage: 102000).isValid, isFalse);
    await state.database.close();
  });

  test('yasal tarih özeti aciliyete göre sıralanır', () async {
    final state = await createTestState(dir);
    await state.saveVehicle(sampleVehicle(plate: '1', insurance: DateTime(2027, 6, 1), inspection: DateTime(2026, 11, 20)));
    await state.saveVehicle(sampleVehicle(plate: '2', insurance: DateTime(2026, 12, 5)));
    final items = state.legalOverview();
    expect(items, hasLength(4));
    expect(items.first.status.state, LegalState.expired);
    expect(items[1].status.state, LegalState.dueSoon);
    expect(items[1].kind, LegalKind.insurance);
    expect(items.last.status.state, LegalState.notSet);
    await state.database.close();
  });

  test('arama: araç, kategori, açıklama ve istasyon; Türkçe duyarsız', () async {
    final state = await createTestState(dir);
    final car = await state.saveVehicle(sampleVehicle(plate: '19 AB 2016'));
    await state.saveVehicle(sampleVehicle(make: 'Yamaha', model: 'MT-07', plate: '34 MT 07', category: VehicleCategory.motorcycle));
    await state.saveService(sampleService(car, date: DateTime(2026, 10, 1), mileage: 100200, description: 'Triger seti değişimi'));
    await state.saveFuel(sampleFuel(car, date: DateTime(2026, 10, 2), mileage: 100300, station: 'Şile Akaryakıt'));

    expect(state.search('peugeot').vehicles, hasLength(1));
    expect(state.search('MOTOSİKLET').vehicles.single.make, 'Yamaha');
    expect(state.search('19ab2016').vehicles, hasLength(1));
    expect(state.search('triger degisimi').services, hasLength(1));
    expect(state.search('sile').fuels, hasLength(1));
    expect(state.search('olmayan şey').isEmpty, isTrue);
    expect(state.search('   ').isEmpty, isTrue);
    await state.database.close();
  });

  test('kilometre kaynağı manuel olarak saklanır (OBD için hazır şema)', () async {
    final state = await createTestState(dir);
    final id = await state.saveVehicle(sampleVehicle());
    await state.saveFuel(sampleFuel(id, date: DateTime(2026, 11, 1), mileage: 100500));
    final rows = await state.database.db.query('fuel_records', columns: ['mileage_source']);
    expect(rows.single['mileage_source'], MileageSource.manual.name);
    await state.database.close();
  });
}
