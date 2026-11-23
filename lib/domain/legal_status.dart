import '../core/utils/dates.dart';
import '../data/models/enums.dart';
import '../data/models/vehicle.dart';

enum LegalState { expired, dueSoon, valid, notSet }

/// Sigorta / muayene tarihinin uygulama içi durumu.
class LegalStatus {
  const LegalStatus._(this.state, this.date, this.daysLeft);

  final LegalState state;
  final DateTime? date;

  /// Bitişe kalan gün (geçmişse negatif). Tarih yoksa null.
  final int? daysLeft;

  static const int defaultWarnDays = 30;
  static const List<int> warnDayOptions = [7, 15, 30, 60];

  static LegalStatus evaluate(DateTime? date, {required DateTime today, int warnDays = defaultWarnDays}) {
    if (date == null) return const LegalStatus._(LegalState.notSet, null, null);
    final days = Dates.daysBetween(today, date);
    final LegalState state;
    if (days < 0) {
      state = LegalState.expired;
    } else if (days <= warnDays) {
      state = LegalState.dueSoon;
    } else {
      state = LegalState.valid;
    }
    return LegalStatus._(state, Dates.dateOnly(date), days);
  }

  String get shortLabel => switch (state) {
        LegalState.expired => 'Süresi doldu',
        LegalState.dueSoon => 'Yaklaşıyor',
        LegalState.valid => 'Geçerli',
        LegalState.notSet => 'Girilmedi',
      };

  String get detailLabel {
    final d = daysLeft;
    if (d == null) return 'Tarih girilmedi';
    if (d < 0) return '${-d} gün önce doldu';
    if (d == 0) return 'Bugün son gün';
    return '$d gün kaldı';
  }

  bool get needsAttention => state == LegalState.expired || state == LegalState.dueSoon;

  /// Aciliyet sırası: süresi dolanlar, yaklaşanlar, geçerliler, girilmeyenler.
  static int compareUrgency(LegalStatus a, LegalStatus b) {
    final byState = a.state.index.compareTo(b.state.index);
    if (byState != 0) return byState;
    return (a.daysLeft ?? 0).compareTo(b.daysLeft ?? 0);
  }
}

class LegalItem {
  const LegalItem({required this.vehicle, required this.kind, required this.status});

  final Vehicle vehicle;
  final LegalKind kind;
  final LegalStatus status;
}
