/// Yakıt formundaki basit aritmetik. Tahmin veya tüketim analizi içermez.
abstract final class FuelMath {
  /// Toplam tutar = miktar × birim fiyat (kuruşa yuvarlanır).
  static double total(double quantity, double unitPrice) => _round(quantity * unitPrice, 2);

  /// Birim fiyat = toplam ÷ miktar (3 haneye yuvarlanır).
  static double? unitPrice(double total, double quantity) {
    if (quantity <= 0) return null;
    return _round(total / quantity, 3);
  }

  static double _round(double value, int digits) => double.parse(value.toStringAsFixed(digits));
}
