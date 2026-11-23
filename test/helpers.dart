import 'dart:io';

import 'package:autodoc/bootstrap.dart';
import 'package:autodoc/data/models/enums.dart';
import 'package:autodoc/data/models/fuel_record.dart';
import 'package:autodoc/data/models/service_record.dart';
import 'package:autodoc/data/models/vehicle.dart';
import 'package:autodoc/state/app_state.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Testlerde sabit "bugün": 23 Kasım 2026.
final DateTime testToday = DateTime(2026, 11, 23, 10, 30);

bool _ffiReady = false;

void ensureFfi() {
  if (_ffiReady) return;
  sqfliteFfiInit();
  _ffiReady = true;
}

/// Geçici klasörde gerçek bir SQLite dosyasıyla uygulama durumu oluşturur.
Future<AppState> createTestState(Directory dir, {DateTime Function()? clock, String name = 'test.db'}) {
  ensureFfi();
  return createAppState(
    factory: databaseFactoryFfi,
    databasePath: p.join(dir.path, name),
    photosDir: p.join(dir.path, 'fotograflar'),
    clock: clock ?? () => testToday,
  );
}

Vehicle sampleVehicle({
  String make = 'Peugeot',
  String model = '2008',
  String? plate = '19 AB 2016',
  int? initialMileage = 100000,
  VehicleCategory category = VehicleCategory.car,
  FuelType fuelType = FuelType.diesel,
  DateTime? insurance,
  DateTime? inspection,
}) {
  return Vehicle(
    category: category,
    make: make,
    model: model,
    modelYear: 2016,
    plate: plate,
    fuelType: fuelType,
    engine: '1.6 HDi',
    initialMileage: initialMileage,
    insuranceExpiry: insurance,
    inspectionDate: inspection,
    createdAt: testToday,
    updatedAt: testToday,
  );
}

FuelRecord sampleFuel(int vehicleId, {required DateTime date, required int mileage, String? station}) {
  return FuelRecord(
    vehicleId: vehicleId,
    date: date,
    mileage: mileage,
    fuelType: FuelType.diesel,
    quantity: 40,
    unitPrice: 45.5,
    totalCost: 1820,
    station: station,
    createdAt: testToday,
    updatedAt: testToday,
  );
}

ServiceRecord sampleService(
  int vehicleId, {
  required DateTime date,
  required int mileage,
  String description = 'Motor yağı değişimi',
  ServiceKind kind = ServiceKind.maintenance,
}) {
  return ServiceRecord(
    vehicleId: vehicleId,
    kind: kind,
    date: date,
    mileage: mileage,
    description: description,
    createdAt: testToday,
    updatedAt: testToday,
  );
}
