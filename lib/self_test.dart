import 'dart:io';

import 'package:path/path.dart' as p;

import 'bootstrap.dart';
import 'data/models/enums.dart';
import 'data/models/fuel_record.dart';
import 'data/models/service_record.dart';
import 'data/models/vehicle.dart';

/// Derlenmiş (release) uygulamanın gerçek ortamda kendini sınaması.
///
/// `autodoc.exe --self-test=<rapor-yolu>` ile çalıştırılır. Geçici bir klasörde
/// gerçek SQLite veritabanı açar; araç, yakıt ve bakım kaydı ekler, kilometre
/// doğrulamasını dener, veritabanını kapatıp yeniden açarak kalıcılığı ve
/// araç silindiğinde kayıtların birlikte silindiğini kontrol eder.
/// CI'da Windows sürümünün paketlenmiş sqlite3.dll ile çalıştığını kanıtlar.
Future<int> runSelfTest(String reportPath) async {
  final lines = <String>['AUTODOC kendi kendini sınama raporu', 'Platform: ${Platform.operatingSystem}', ''];
  var passed = true;

  void check(String name, bool condition) {
    lines.add('${condition ? '[GECTI]' : '[KALDI]'} $name');
    if (!condition) passed = false;
  }

  Directory? temp;
  try {
    temp = await Directory.systemTemp.createTemp('autodoc_selftest_');
    final dbPath = p.join(temp.path, 'selftest.db');
    final photos = p.join(temp.path, 'fotograflar');
    final factory = platformDatabaseFactory();

    var state = await createAppState(factory: factory, databasePath: dbPath, photosDir: photos);
    check('Veritabanı açıldı ve boş', state.vehicles.isEmpty);

    final now = DateTime.now();
    final vehicleId = await state.saveVehicle(Vehicle(
      category: VehicleCategory.car,
      make: 'Peugeot',
      model: '2008',
      modelYear: 2016,
      plate: '34 ABC 123',
      fuelType: FuelType.diesel,
      engine: '1.6 HDi',
      initialMileage: 120000,
      insuranceExpiry: DateTime(now.year, now.month, now.day + 10),
      createdAt: now,
      updatedAt: now,
    ));
    check('Araç eklendi', state.vehicles.length == 1);

    await state.saveFuel(FuelRecord(
      vehicleId: vehicleId,
      date: now,
      mileage: 120500,
      fuelType: FuelType.diesel,
      quantity: 42.5,
      unitPrice: 47.9,
      totalCost: 2035.75,
      fullTank: true,
      station: 'Çorum İstasyonu',
      createdAt: now,
      updatedAt: now,
    ));
    await state.saveService(ServiceRecord(
      vehicleId: vehicleId,
      kind: ServiceKind.maintenance,
      date: now,
      mileage: 120600,
      description: 'Motor yağı ve filtre değişimi',
      createdAt: now,
      updatedAt: now,
    ));
    check('Yakıt kaydı eklendi', state.fuelFor(vehicleId).length == 1);
    check('Bakım kaydı eklendi', state.servicesFor(vehicleId).length == 1);
    check('Son bilinen kilometre doğru', state.lastMileage(vehicleId) == 120600);

    final suspicious = state.validateMileage(vehicleId: vehicleId, date: now, mileage: 100000);
    check('Kilometre düşüşü uyarısı üretildi', suspicious.hasWarnings);
    final negative = state.validateMileage(vehicleId: vehicleId, date: now, mileage: -5);
    check('Negatif kilometre engellendi', !negative.isValid);

    final insurance = state.legalStatus(state.vehicles.first, LegalKind.insurance);
    check('Sigorta durumu "yaklaşıyor"', insurance.needsAttention && insurance.daysLeft == 10);

    final search = state.search('corum');
    check('Türkçe duyarsız arama çalışıyor', search.fuels.length == 1);

    await state.database.close();
    state = await createAppState(factory: factory, databasePath: dbPath, photosDir: photos);
    check('Yeniden açılışta veriler korundu',
        state.vehicles.length == 1 && state.recordsFor(vehicleId).length == 2);
    check('Türkçe metin kalıcı', state.fuelFor(vehicleId).first.station == 'Çorum İstasyonu');

    await state.deleteVehicle(vehicleId);
    check('Araç silinince kayıtları da silindi',
        state.vehicles.isEmpty && state.recordsFor(vehicleId).isEmpty);
    await state.database.close();
  } catch (e, st) {
    passed = false;
    lines.add('[HATA] $e');
    lines.add('$st');
  } finally {
    try {
      await temp?.delete(recursive: true);
    } catch (_) {}
  }

  lines.add('');
  lines.add(passed ? 'RESULT: PASS' : 'RESULT: FAIL');
  await File(reportPath).writeAsString(lines.join('\n'), flush: true);
  return passed ? 0 : 1;
}
