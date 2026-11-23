import 'package:flutter/foundation.dart';

import '../core/utils/dates.dart';
import '../core/utils/text_normalize.dart';
import '../data/database/app_database.dart';
import '../data/models/enums.dart';
import '../data/models/fuel_record.dart';
import '../data/models/record_entry.dart';
import '../data/models/service_record.dart';
import '../data/models/vehicle.dart';
import '../data/photo_store.dart';
import '../data/repositories/repositories.dart';
import '../domain/legal_status.dart';
import '../domain/mileage.dart';

/// Uygulama durumu.
///
/// Veritabanı tek doğruluk kaynağıdır. Her değişiklik önce SQLite'a yazılır,
/// ardından liste yeniden okunur ve arayüz bilgilendirilir. Kişisel araç
/// verisi küçük olduğundan kayıtlar bellekte tutulur; bu sayede arama ve
/// panel anında çalışır.
class AppState extends ChangeNotifier {
  AppState({
    required this.database,
    required this.photoStore,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _vehicleRepo = VehicleRepository(database),
        _fuelRepo = FuelRepository(database),
        _serviceRepo = ServiceRepository(database),
        _settingsRepo = SettingsRepository(database);

  final AppDatabase database;
  final PhotoStore photoStore;
  final DateTime Function() _clock;
  final VehicleRepository _vehicleRepo;
  final FuelRepository _fuelRepo;
  final ServiceRepository _serviceRepo;
  final SettingsRepository _settingsRepo;

  static const String _kSelectedVehicle = 'selected_vehicle_id';
  static const String _kWarnDays = 'legal_warn_days';

  List<Vehicle> _vehicles = const [];
  Map<int, List<FuelRecord>> _fuel = const {};
  Map<int, List<ServiceRecord>> _service = const {};
  int? _selectedVehicleId;
  int _warnDays = LegalStatus.defaultWarnDays;

  DateTime get now => _clock();
  DateTime get today => Dates.dateOnly(_clock());
  int get warnDays => _warnDays;
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  Future<void> load() async {
    final selected = int.tryParse(await _settingsRepo.get(_kSelectedVehicle) ?? '');
    final warn = int.tryParse(await _settingsRepo.get(_kWarnDays) ?? '');
    _selectedVehicleId = selected;
    if (warn != null && LegalStatus.warnDayOptions.contains(warn)) _warnDays = warn;
    await _reload();
  }

  Future<void> _reload() async {
    final vehicles = await _vehicleRepo.getAll();
    final fuel = await _fuelRepo.getAll();
    final services = await _serviceRepo.getAll();

    final fuelMap = <int, List<FuelRecord>>{};
    for (final r in fuel) {
      fuelMap.putIfAbsent(r.vehicleId, () => []).add(r);
    }
    final serviceMap = <int, List<ServiceRecord>>{};
    for (final r in services) {
      serviceMap.putIfAbsent(r.vehicleId, () => []).add(r);
    }

    _vehicles = vehicles;
    _fuel = fuelMap;
    _service = serviceMap;

    if (_selectedVehicleId != null && vehicleById(_selectedVehicleId!) == null) {
      _selectedVehicleId = null;
    }
    if (_selectedVehicleId == null && _vehicles.isNotEmpty) {
      _selectedVehicleId = _vehicles.first.id;
      await _settingsRepo.set(_kSelectedVehicle, '$_selectedVehicleId');
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- Araçlar

  Vehicle? vehicleById(int id) {
    for (final v in _vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  Vehicle? get selectedVehicle {
    final id = _selectedVehicleId;
    if (id == null) return _vehicles.isEmpty ? null : _vehicles.first;
    return vehicleById(id) ?? (_vehicles.isEmpty ? null : _vehicles.first);
  }

  Future<void> selectVehicle(int id) async {
    if (vehicleById(id) == null) return;
    _selectedVehicleId = id;
    await _settingsRepo.set(_kSelectedVehicle, '$id');
    notifyListeners();
  }

  bool isPlateTaken(String plate, {int? excludeId}) {
    final key = plateKey(plate);
    if (key.isEmpty) return false;
    for (final v in _vehicles) {
      if (v.id == excludeId) continue;
      final p = v.plate;
      if (p != null && plateKey(p) == key) return true;
    }
    return false;
  }

  /// Aracı ekler veya günceller; kimliği döndürür.
  Future<int> saveVehicle(
    Vehicle vehicle, {
    String? newPhotoSourcePath,
    bool removePhoto = false,
  }) async {
    final timestamp = _clock();
    final int id;
    String? oldPhoto;
    if (vehicle.id == null) {
      id = await _vehicleRepo.insert(
        vehicle.copyWith(createdAt: timestamp, updatedAt: timestamp, photoPath: () => null),
      );
    } else {
      id = vehicle.id!;
      oldPhoto = vehicleById(id)?.photoPath;
      await _vehicleRepo.update(vehicle.copyWith(updatedAt: timestamp, photoPath: () => oldPhoto));
    }

    if (newPhotoSourcePath != null) {
      final name = await photoStore.importPhoto(newPhotoSourcePath, id);
      await _vehicleRepo.updatePhoto(id, name);
      await photoStore.delete(oldPhoto);
    } else if (removePhoto && oldPhoto != null) {
      await _vehicleRepo.updatePhoto(id, null);
      await photoStore.delete(oldPhoto);
    }

    if (_selectedVehicleId == null) {
      _selectedVehicleId = id;
      await _settingsRepo.set(_kSelectedVehicle, '$id');
    }
    await _reload();
    return id;
  }

  Future<void> deleteVehicle(int id) async {
    final photo = vehicleById(id)?.photoPath;
    await _vehicleRepo.delete(id);
    await photoStore.delete(photo);
    if (_selectedVehicleId == id) _selectedVehicleId = null;
    await _reload();
  }

  // ---------------------------------------------------------------- Kayıtlar

  List<FuelRecord> fuelFor(int vehicleId) => List.unmodifiable(_fuel[vehicleId] ?? const <FuelRecord>[]);

  List<ServiceRecord> servicesFor(int vehicleId, {ServiceKind? kind}) {
    final all = _service[vehicleId] ?? const <ServiceRecord>[];
    if (kind == null) return List.unmodifiable(all);
    return all.where((r) => r.kind == kind).toList(growable: false);
  }

  /// Aracın tüm kayıtları (yeniden eskiye).
  List<RecordEntry> recordsFor(int vehicleId) {
    final list = <RecordEntry>[
      for (final r in _fuel[vehicleId] ?? const <FuelRecord>[]) RecordEntry.fuel(r),
      for (final r in _service[vehicleId] ?? const <ServiceRecord>[]) RecordEntry.service(r),
    ];
    list.sort(RecordEntry.compareDesc);
    return list;
  }

  Future<int> saveFuel(FuelRecord record) async {
    final timestamp = _clock();
    final int id;
    if (record.id == null) {
      id = await _fuelRepo.insert(record.copyWith(createdAt: timestamp, updatedAt: timestamp));
    } else {
      id = record.id!;
      await _fuelRepo.update(record.copyWith(updatedAt: timestamp));
    }
    await _reload();
    return id;
  }

  Future<void> deleteFuel(int id) async {
    await _fuelRepo.delete(id);
    await _reload();
  }

  Future<int> saveService(ServiceRecord record) async {
    final timestamp = _clock();
    final int id;
    if (record.id == null) {
      id = await _serviceRepo.insert(record.copyWith(createdAt: timestamp, updatedAt: timestamp));
    } else {
      id = record.id!;
      await _serviceRepo.update(record.copyWith(updatedAt: timestamp));
    }
    await _reload();
    return id;
  }

  Future<void> deleteService(int id) async {
    await _serviceRepo.delete(id);
    await _reload();
  }

  // ---------------------------------------------------------------- Kilometre

  List<MileageEntry> mileageHistory(int vehicleId, {int? excludeFuelId, int? excludeServiceId}) {
    final v = vehicleById(vehicleId);
    if (v == null) return const [];
    return buildMileageHistory(
      vehicle: v,
      fuel: _fuel[vehicleId] ?? const [],
      services: _service[vehicleId] ?? const [],
      excludeFuelId: excludeFuelId,
      excludeServiceId: excludeServiceId,
    );
  }

  int? lastMileage(int vehicleId) => lastKnownMileage(mileageHistory(vehicleId));

  MileageValidationResult validateMileage({
    required int vehicleId,
    required DateTime date,
    required int mileage,
    int? excludeFuelId,
    int? excludeServiceId,
  }) {
    return MileageValidator.validate(
      mileage: mileage,
      date: date,
      today: today,
      history: mileageHistory(
        vehicleId,
        excludeFuelId: excludeFuelId,
        excludeServiceId: excludeServiceId,
      ),
    );
  }

  // ---------------------------------------------------------------- Yasal tarihler

  LegalStatus legalStatus(Vehicle v, LegalKind kind) => LegalStatus.evaluate(
        kind == LegalKind.insurance ? v.insuranceExpiry : v.inspectionDate,
        today: today,
        warnDays: _warnDays,
      );

  List<LegalItem> legalOverview() {
    final items = <LegalItem>[
      for (final v in _vehicles)
        for (final kind in LegalKind.values)
          LegalItem(vehicle: v, kind: kind, status: legalStatus(v, kind)),
    ];
    items.sort((a, b) => LegalStatus.compareUrgency(a.status, b.status));
    return items;
  }

  Future<void> setWarnDays(int days) async {
    if (!LegalStatus.warnDayOptions.contains(days)) return;
    _warnDays = days;
    await _settingsRepo.set(_kWarnDays, '$days');
    notifyListeners();
  }

  // ---------------------------------------------------------------- Arama

  SearchResults search(String query) {
    final tokens = foldForSearch(query)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) return const SearchResults.empty();

    bool matches(Iterable<String?> fields) {
      final haystack = foldForSearch(fields.whereType<String>().join(' '));
      return tokens.every(haystack.contains);
    }

    final vehicles = _vehicles
        .where((v) => matches([
              v.displayName,
              v.make,
              v.model,
              v.nickname,
              v.plate,
              v.plate?.replaceAll(' ', ''),
              v.category.label,
              v.fuelType.label,
              v.engine,
              v.color,
              v.vin,
              v.modelYear?.toString(),
              v.notes,
            ]))
        .toList();

    final services = <ServiceRecord>[];
    for (final list in _service.values) {
      for (final r in list) {
        final v = vehicleById(r.vehicleId);
        if (matches([r.description, r.workshop, r.note, r.kind.label, v?.displayName, v?.plate])) {
          services.add(r);
        }
      }
    }
    services.sort((a, b) => b.date.compareTo(a.date));

    final fuels = <FuelRecord>[];
    for (final list in _fuel.values) {
      for (final r in list) {
        final v = vehicleById(r.vehicleId);
        if (matches([r.station, r.note, r.fuelType.label, 'yakıt', v?.displayName, v?.plate])) {
          fuels.add(r);
        }
      }
    }
    fuels.sort((a, b) => b.date.compareTo(a.date));

    return SearchResults(vehicles: vehicles, services: services, fuels: fuels);
  }
}

class SearchResults {
  const SearchResults({required this.vehicles, required this.services, required this.fuels});

  const SearchResults.empty()
      : vehicles = const [],
        services = const [],
        fuels = const [];

  final List<Vehicle> vehicles;
  final List<ServiceRecord> services;
  final List<FuelRecord> fuels;

  bool get isEmpty => vehicles.isEmpty && services.isEmpty && fuels.isEmpty;
  int get total => vehicles.length + services.length + fuels.length;
}
