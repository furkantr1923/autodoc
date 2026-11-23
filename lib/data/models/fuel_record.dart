import '../../core/utils/dates.dart';
import 'enums.dart';

class FuelRecord {
  const FuelRecord({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.mileage,
    required this.fuelType,
    required this.quantity,
    this.unitPrice,
    this.totalCost,
    this.fullTank = false,
    this.station,
    this.note,
    this.mileageSource = MileageSource.manual,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int vehicleId;
  final DateTime date;
  final int mileage;
  final FuelType fuelType;

  /// Litre, kWh veya kg ([FuelType.unit]).
  final double quantity;
  final double? unitPrice;
  final double? totalCost;
  final bool fullTank;
  final String? station;
  final String? note;
  final MileageSource mileageSource;
  final DateTime createdAt;
  final DateTime updatedAt;

  FuelRecord copyWith({int? id, DateTime? createdAt, DateTime? updatedAt}) => FuelRecord(
        id: id ?? this.id,
        vehicleId: vehicleId,
        date: date,
        mileage: mileage,
        fuelType: fuelType,
        quantity: quantity,
        unitPrice: unitPrice,
        totalCost: totalCost,
        fullTank: fullTank,
        station: station,
        note: note,
        mileageSource: mileageSource,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'vehicle_id': vehicleId,
        'date': Dates.toDb(date),
        'mileage': mileage,
        'fuel_type': fuelType.name,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_cost': totalCost,
        'full_tank': fullTank ? 1 : 0,
        'station': station,
        'note': note,
        'mileage_source': mileageSource.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FuelRecord.fromMap(Map<String, Object?> m) => FuelRecord(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        date: Dates.fromDb(m['date'] as String),
        mileage: m['mileage'] as int,
        fuelType: FuelType.fromDb(m['fuel_type']),
        quantity: (m['quantity'] as num).toDouble(),
        unitPrice: (m['unit_price'] as num?)?.toDouble(),
        totalCost: (m['total_cost'] as num?)?.toDouble(),
        fullTank: (m['full_tank'] as int? ?? 0) == 1,
        station: m['station'] as String?,
        note: m['note'] as String?,
        mileageSource: MileageSource.fromDb(m['mileage_source']),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
