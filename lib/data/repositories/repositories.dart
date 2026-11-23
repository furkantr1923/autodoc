import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/fuel_record.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';

class VehicleRepository {
  VehicleRepository(this._database);

  final AppDatabase _database;
  Database get _db => _database.db;

  Future<List<Vehicle>> getAll() async {
    final rows = await _db.query('vehicles', orderBy: 'id ASC');
    return rows.map(Vehicle.fromMap).toList();
  }

  Future<Vehicle?> getById(int id) async {
    final rows = await _db.query('vehicles', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Vehicle.fromMap(rows.first);
  }

  Future<int> insert(Vehicle vehicle) {
    final map = vehicle.toMap()..remove('id');
    return _db.insert('vehicles', map, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> update(Vehicle vehicle) async {
    final id = vehicle.id;
    if (id == null) throw ArgumentError('Güncellenecek aracın kimliği yok.');
    final map = vehicle.toMap()..remove('id');
    final count = await _db.update('vehicles', map, where: 'id = ?', whereArgs: [id]);
    if (count != 1) throw StateError('Araç bulunamadı (id: $id).');
  }

  Future<void> updatePhoto(int id, String? photoPath) async {
    await _db.update('vehicles', {'photo_path': photoPath}, where: 'id = ?', whereArgs: [id]);
  }

  /// Aracı siler; yakıt ve bakım/servis kayıtları yabancı anahtar ile birlikte silinir.
  Future<void> delete(int id) async {
    await _db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }
}

class FuelRepository {
  FuelRepository(this._database);

  final AppDatabase _database;
  Database get _db => _database.db;

  Future<List<FuelRecord>> getAll() async {
    final rows = await _db.query('fuel_records', orderBy: 'date DESC, mileage DESC, id DESC');
    return rows.map(FuelRecord.fromMap).toList();
  }

  Future<List<FuelRecord>> getForVehicle(int vehicleId) async {
    final rows = await _db.query(
      'fuel_records',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC, mileage DESC, id DESC',
    );
    return rows.map(FuelRecord.fromMap).toList();
  }

  Future<int> insert(FuelRecord record) {
    final map = record.toMap()..remove('id');
    return _db.insert('fuel_records', map, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> update(FuelRecord record) async {
    final id = record.id;
    if (id == null) throw ArgumentError('Güncellenecek kaydın kimliği yok.');
    final map = record.toMap()..remove('id');
    final count = await _db.update('fuel_records', map, where: 'id = ?', whereArgs: [id]);
    if (count != 1) throw StateError('Yakıt kaydı bulunamadı (id: $id).');
  }

  Future<void> delete(int id) async {
    await _db.delete('fuel_records', where: 'id = ?', whereArgs: [id]);
  }
}

class ServiceRepository {
  ServiceRepository(this._database);

  final AppDatabase _database;
  Database get _db => _database.db;

  Future<List<ServiceRecord>> getAll() async {
    final rows = await _db.query('service_records', orderBy: 'date DESC, mileage DESC, id DESC');
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<List<ServiceRecord>> getForVehicle(int vehicleId) async {
    final rows = await _db.query(
      'service_records',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC, mileage DESC, id DESC',
    );
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<int> insert(ServiceRecord record) {
    final map = record.toMap()..remove('id');
    return _db.insert('service_records', map, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> update(ServiceRecord record) async {
    final id = record.id;
    if (id == null) throw ArgumentError('Güncellenecek kaydın kimliği yok.');
    final map = record.toMap()..remove('id');
    final count = await _db.update('service_records', map, where: 'id = ?', whereArgs: [id]);
    if (count != 1) throw StateError('Bakım/servis kaydı bulunamadı (id: $id).');
  }

  Future<void> delete(int id) async {
    await _db.delete('service_records', where: 'id = ?', whereArgs: [id]);
  }
}

class SettingsRepository {
  SettingsRepository(this._database);

  final AppDatabase _database;
  Database get _db => _database.db;

  Future<String?> get(String key) async {
    final rows = await _db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String? value) async {
    await _db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
