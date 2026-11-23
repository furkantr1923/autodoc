import '../core/utils/dates.dart';
import '../core/utils/formatters.dart';
import '../data/models/enums.dart';
import '../data/models/fuel_record.dart';
import '../data/models/service_record.dart';
import '../data/models/vehicle.dart';

/// Kilometre geçmişindeki bir değerin nereden geldiği.
enum MileageOrigin {
  registration('Araç kaydı'),
  fuel('Yakıt'),
  maintenance('Bakım'),
  service('Servis');

  const MileageOrigin(this.label);

  final String label;
}

/// Kilometre geçmişindeki tek bir nokta. Değerler YALNIZCA kullanıcının
/// girdiği kayıtlardan türetilir; tahmin veya otomatik değer üretilmez.
class MileageEntry {
  const MileageEntry({
    required this.date,
    required this.mileage,
    required this.origin,
    this.recordId,
    this.source = MileageSource.manual,
  });

  final DateTime date;
  final int mileage;
  final MileageOrigin origin;
  final int? recordId;
  final MileageSource source;
}

/// Bir aracın kayıtlarından kronolojik (eskiden yeniye) kilometre geçmişi üretir.
List<MileageEntry> buildMileageHistory({
  required Vehicle vehicle,
  required List<FuelRecord> fuel,
  required List<ServiceRecord> services,
  int? excludeFuelId,
  int? excludeServiceId,
}) {
  final entries = <MileageEntry>[
    if (vehicle.initialMileage != null)
      MileageEntry(
        date: Dates.dateOnly(vehicle.createdAt),
        mileage: vehicle.initialMileage!,
        origin: MileageOrigin.registration,
      ),
    for (final r in fuel)
      if (r.id == null || r.id != excludeFuelId)
        MileageEntry(
          date: r.date,
          mileage: r.mileage,
          origin: MileageOrigin.fuel,
          recordId: r.id,
          source: r.mileageSource,
        ),
    for (final r in services)
      if (r.id == null || r.id != excludeServiceId)
        MileageEntry(
          date: r.date,
          mileage: r.mileage,
          origin: r.kind == ServiceKind.maintenance
              ? MileageOrigin.maintenance
              : MileageOrigin.service,
          recordId: r.id,
          source: r.mileageSource,
        ),
  ];
  entries.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.mileage.compareTo(b.mileage);
  });
  return entries;
}

/// Bilinen en güncel kilometre: en son tarihli kayıt (aynı gün ise en yüksek değer).
int? lastKnownMileage(List<MileageEntry> history) {
  MileageEntry? best;
  for (final e in history) {
    if (best == null) {
      best = e;
      continue;
    }
    final byDate = e.date.compareTo(best.date);
    if (byDate > 0 || (byDate == 0 && e.mileage > best.mileage)) best = e;
  }
  return best?.mileage;
}

class MileageValidationResult {
  const MileageValidationResult({this.error, this.warnings = const []});

  /// Kaydı engelleyen hata (negatif, aşırı büyük, gelecek tarih...).
  final String? error;

  /// Kullanıcı onayıyla kaydedilebilecek şüpheli durumlar (kilometre düşüşü).
  final List<String> warnings;

  bool get isValid => error == null;
  bool get hasWarnings => warnings.isNotEmpty;
}

abstract final class MileageValidator {
  static const int maxMileage = 2000000;

  /// Alan düzeyinde doğrulama (form validator'ı).
  static String? validateText(String? text, {required int? parsed, bool isRequired = true}) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return isRequired ? 'Kilometre girin.' : null;
    if (t.startsWith('-')) return 'Kilometre negatif olamaz.';
    if (parsed == null) return 'Geçerli bir kilometre girin (yalnızca rakam).';
    return validateValue(parsed);
  }

  static String? validateValue(int value) {
    if (value < 0) return 'Kilometre negatif olamaz.';
    if (value > maxMileage) {
      return 'Kilometre değeri gerçekçi değil (en fazla ${Fmt.integer(maxMileage)} km).';
    }
    return null;
  }

  /// Yeni veya düzenlenen bir kaydın kilometresini aracın geçmişiyle karşılaştırır.
  ///
  /// [history], düzenlenen kaydın kendisini içermemelidir.
  static MileageValidationResult validate({
    required int mileage,
    required DateTime date,
    required DateTime today,
    required List<MileageEntry> history,
  }) {
    final valueError = validateValue(mileage);
    if (valueError != null) return MileageValidationResult(error: valueError);
    if (Dates.daysBetween(today, date) > 0) {
      return const MileageValidationResult(error: 'Gelecek tarihli kayıt girilemez.');
    }

    MileageEntry? highestBefore; // aynı gün dahil, bu tarihe kadar olan en yüksek değer
    MileageEntry? lowestAfter; // bu tarihten sonraki en düşük değer
    for (final e in history) {
      final diff = Dates.daysBetween(date, e.date);
      if (diff <= 0) {
        if (highestBefore == null || e.mileage > highestBefore.mileage) highestBefore = e;
      } else {
        if (lowestAfter == null || e.mileage < lowestAfter.mileage) lowestAfter = e;
      }
    }

    final warnings = <String>[];
    if (highestBefore != null && mileage < highestBefore.mileage) {
      warnings.add(
        '${Fmt.dateShort(highestBefore.date)} tarihli ${highestBefore.origin.label.toLowerCase()} '
        'kaydında ${Fmt.km(highestBefore.mileage)} girilmiş. Yeni değer bundan '
        '${Fmt.km(highestBefore.mileage - mileage)} düşük; kilometre düşüşü şüpheli.',
      );
    }
    if (lowestAfter != null && mileage > lowestAfter.mileage) {
      warnings.add(
        'Daha sonraki bir kayıtta (${Fmt.dateShort(lowestAfter.date)}) '
        '${Fmt.km(lowestAfter.mileage)} var. Bu değer kronolojik sırayla tutarsız.',
      );
    }
    return MileageValidationResult(warnings: warnings);
  }
}
