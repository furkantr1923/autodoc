import '../../core/utils/dates.dart';
import 'enums.dart';

/// Bakım veya servis kaydı: odak, işlemin tarihi ve yapılan işlemdir.
class ServiceRecord {
  const ServiceRecord({
    this.id,
    required this.vehicleId,
    required this.kind,
    required this.date,
    required this.mileage,
    required this.description,
    this.workshop,
    this.cost,
    this.note,
    this.mileageSource = MileageSource.manual,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int vehicleId;
  final ServiceKind kind;
  final DateTime date;
  final int mileage;

  /// Yapılan işlemin açıklaması.
  final String description;
  final String? workshop;
  final double? cost;
  final String? note;
  final MileageSource mileageSource;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRecord copyWith({int? id, DateTime? createdAt, DateTime? updatedAt}) => ServiceRecord(
        id: id ?? this.id,
        vehicleId: vehicleId,
        kind: kind,
        date: date,
        mileage: mileage,
        description: description,
        workshop: workshop,
        cost: cost,
        note: note,
        mileageSource: mileageSource,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'vehicle_id': vehicleId,
        'kind': kind.name,
        'date': Dates.toDb(date),
        'mileage': mileage,
        'description': description,
        'workshop': workshop,
        'cost': cost,
        'note': note,
        'mileage_source': mileageSource.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ServiceRecord.fromMap(Map<String, Object?> m) => ServiceRecord(
        id: m['id'] as int?,
        vehicleId: m['vehicle_id'] as int,
        kind: ServiceKind.fromDb(m['kind']),
        date: Dates.fromDb(m['date'] as String),
        mileage: m['mileage'] as int,
        description: (m['description'] as String?) ?? '',
        workshop: m['workshop'] as String?,
        cost: (m['cost'] as num?)?.toDouble(),
        note: m['note'] as String?,
        mileageSource: MileageSource.fromDb(m['mileage_source']),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
