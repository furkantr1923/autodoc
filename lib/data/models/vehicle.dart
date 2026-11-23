import '../../core/utils/dates.dart';
import 'enums.dart';

class Vehicle {
  const Vehicle({
    this.id,
    required this.category,
    required this.make,
    required this.model,
    this.modelYear,
    this.plate,
    required this.fuelType,
    this.engine,
    this.vin,
    this.nickname,
    this.color,
    this.initialMileage,
    this.insuranceExpiry,
    this.inspectionDate,
    this.photoPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final VehicleCategory category;
  final String make;
  final String model;
  final int? modelYear;
  final String? plate;
  final FuelType fuelType;
  final String? engine;
  final String? vin;
  final String? nickname;
  final String? color;

  /// Araç kaydedilirken girilen mevcut kilometre (isteğe bağlı).
  final int? initialMileage;

  /// Sigorta bitiş tarihi.
  final DateTime? insuranceExpiry;

  /// Muayene geçerlilik (bir sonraki muayene) tarihi.
  final DateTime? inspectionDate;

  /// Fotoğraf dosyasının adı (uygulama veri klasöründe saklanır).
  final String? photoPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    final n = nickname?.trim();
    if (n != null && n.isNotEmpty) return n;
    return '$make $model';
  }

  /// "Peugeot 2008 · 2016" biçiminde başlık.
  String get fullTitle =>
      modelYear == null ? '$make $model' : '$make $model · $modelYear';

  Vehicle copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? Function()? photoPath,
  }) {
    return Vehicle(
      id: id ?? this.id,
      category: category,
      make: make,
      model: model,
      modelYear: modelYear,
      plate: plate,
      fuelType: fuelType,
      engine: engine,
      vin: vin,
      nickname: nickname,
      color: color,
      initialMileage: initialMileage,
      insuranceExpiry: insuranceExpiry,
      inspectionDate: inspectionDate,
      photoPath: photoPath != null ? photoPath() : this.photoPath,
      notes: notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'category': category.name,
        'make': make,
        'model': model,
        'model_year': modelYear,
        'plate': plate,
        'fuel_type': fuelType.name,
        'engine': engine,
        'vin': vin,
        'nickname': nickname,
        'color': color,
        'initial_mileage': initialMileage,
        'insurance_expiry': insuranceExpiry == null ? null : Dates.toDb(insuranceExpiry!),
        'inspection_date': inspectionDate == null ? null : Dates.toDb(inspectionDate!),
        'photo_path': photoPath,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Vehicle.fromMap(Map<String, Object?> m) => Vehicle(
        id: m['id'] as int?,
        category: VehicleCategory.fromDb(m['category']),
        make: (m['make'] as String?) ?? '',
        model: (m['model'] as String?) ?? '',
        modelYear: m['model_year'] as int?,
        plate: m['plate'] as String?,
        fuelType: FuelType.fromDb(m['fuel_type']),
        engine: m['engine'] as String?,
        vin: m['vin'] as String?,
        nickname: m['nickname'] as String?,
        color: m['color'] as String?,
        initialMileage: m['initial_mileage'] as int?,
        insuranceExpiry: Dates.fromDbNullable(m['insurance_expiry']),
        inspectionDate: Dates.fromDbNullable(m['inspection_date']),
        photoPath: m['photo_path'] as String?,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
}
