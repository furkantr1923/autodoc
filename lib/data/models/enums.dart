import 'package:flutter/material.dart';

/// Araç kategorileri. Veritabanında [name] değeri saklanır.
enum VehicleCategory {
  car('Otomobil', Icons.directions_car_filled_rounded),
  suv('SUV / Arazi Aracı', Icons.time_to_leave_rounded),
  motorcycle('Motosiklet', Icons.two_wheeler_rounded),
  lightCommercial('Hafif Ticari', Icons.airport_shuttle_rounded),
  truck('Kamyon / Kamyonet', Icons.local_shipping_rounded),
  bus('Otobüs / Minibüs', Icons.directions_bus_filled_rounded),
  caravan('Karavan', Icons.rv_hookup_rounded),
  tractor('Traktör / İş Makinesi', Icons.agriculture_rounded),
  other('Diğer', Icons.commute_rounded);

  const VehicleCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static VehicleCategory fromDb(Object? value) {
    for (final c in VehicleCategory.values) {
      if (c.name == value) return c;
    }
    return VehicleCategory.other;
  }
}

/// Aracın yakıt / enerji türü.
enum FuelType {
  gasoline('Benzin'),
  diesel('Dizel'),
  lpg('LPG'),
  gasolineLpg('Benzin + LPG'),
  hybrid('Hibrit'),
  plugInHybrid('Şarj Edilebilir Hibrit'),
  electric('Elektrik'),
  cng('CNG (Doğalgaz)'),
  other('Diğer');

  const FuelType(this.label);

  final String label;

  /// Yakıt kaydındaki miktar birimi.
  String get unit => switch (this) {
        FuelType.electric => 'kWh',
        FuelType.cng => 'kg',
        _ => 'L',
      };

  IconData get icon => this == FuelType.electric
      ? Icons.ev_station_rounded
      : Icons.local_gas_station_rounded;

  /// Bu türdeki bir araca yakıt kaydı girilirken seçilebilecek enerji türleri.
  List<FuelType> get refuelOptions => switch (this) {
        FuelType.gasolineLpg => const [FuelType.gasoline, FuelType.lpg],
        FuelType.hybrid => const [FuelType.gasoline],
        FuelType.plugInHybrid => const [FuelType.gasoline, FuelType.electric],
        FuelType.other => const [
            FuelType.gasoline,
            FuelType.diesel,
            FuelType.lpg,
            FuelType.electric,
            FuelType.cng,
            FuelType.other,
          ],
        _ => [this],
      };

  static FuelType fromDb(Object? value) {
    for (final f in FuelType.values) {
      if (f.name == value) return f;
    }
    return FuelType.other;
  }
}

/// Bakım (periyodik/koruyucu) ve servis (onarım/arıza) kayıt türleri.
enum ServiceKind {
  maintenance('Bakım', Icons.build_circle_rounded),
  service('Servis', Icons.home_repair_service_rounded);

  const ServiceKind(this.label, this.icon);

  final String label;
  final IconData icon;

  static ServiceKind fromDb(Object? value) =>
      value == ServiceKind.service.name ? ServiceKind.service : ServiceKind.maintenance;
}

/// Kilometre değerinin kaynağı.
///
/// Bugün yalnızca [manual] kullanılır. [obd], ileride OBD-II adaptöründen
/// okunacak değerlerin aynı tabloya, kaynağı ayırt edilerek yazılabilmesi
/// için şemada yer alır; otomatik OBD takibi bu sürümde YOKTUR.
enum MileageSource {
  manual('Manuel'),
  obd('OBD');

  const MileageSource(this.label);

  final String label;

  static MileageSource fromDb(Object? value) =>
      value == MileageSource.obd.name ? MileageSource.obd : MileageSource.manual;
}

/// Takip edilen yasal tarih türleri.
enum LegalKind {
  insurance('Sigorta', Icons.verified_user_rounded),
  inspection('Muayene', Icons.fact_check_rounded);

  const LegalKind(this.label, this.icon);

  final String label;
  final IconData icon;
}
