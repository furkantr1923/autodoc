import 'fuel_record.dart';
import 'service_record.dart';

/// Yakıt ve bakım/servis kayıtlarını tek bir zaman çizelgesinde göstermek için.
class RecordEntry {
  const RecordEntry.fuel(FuelRecord record)
      : fuel = record,
        service = null;

  const RecordEntry.service(ServiceRecord record)
      : fuel = null,
        service = record;

  final FuelRecord? fuel;
  final ServiceRecord? service;

  bool get isFuel => fuel != null;
  DateTime get date => fuel?.date ?? service!.date;
  int get mileage => fuel?.mileage ?? service!.mileage;
  int get vehicleId => fuel?.vehicleId ?? service!.vehicleId;
  DateTime get createdAt => fuel?.createdAt ?? service!.createdAt;

  /// Yeniden eskiye sıralama.
  static int compareDesc(RecordEntry a, RecordEntry b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    final byKm = b.mileage.compareTo(a.mileage);
    if (byKm != 0) return byKm;
    return b.createdAt.compareTo(a.createdAt);
  }
}
