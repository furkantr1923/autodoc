# Mimari

## Katmanlar

```
UI (ui/)  ──okur──▶  AppState (state/)  ──çağırır──▶  Repository'ler (data/repositories)
   │                     │                                  │
   │                     └── domain/ (saf iş kuralları) ◀───┘
   └── widgets/ (ortak bileşenler)                         SQLite (data/database)
```

- **Tek doğruluk kaynağı veritabanıdır.** Her değişiklik önce SQLite'a yazılır, ardından `AppState` listeleri yeniden okur ve arayüzü bilgilendirir. Kişisel araç verisi küçük olduğundan kayıtlar bellekte tutulur; panel ve arama anında çalışır.
- **`domain/` saf Dart'tır** (Flutter'a bağımlı değildir): kilometre doğrulama, yasal tarih durumu, VIN çözümleme ve yakıt hesabı bağımsız olarak test edilir.
- **Platforma özgü tek nokta `bootstrap.dart`'tır**: Android'de `sqflite`, Windows'ta `sqflite_common_ffi` + paketli `sqlite3.dll`; veri klasörü ve taşınabilir mod burada belirlenir.

## Veritabanı şeması (sürüm 1)

```sql
vehicles (
  id INTEGER PK, category TEXT, make TEXT, model TEXT, model_year INTEGER,
  plate TEXT, fuel_type TEXT, engine TEXT, vin TEXT, nickname TEXT, color TEXT,
  initial_mileage INTEGER CHECK (>= 0), insurance_expiry TEXT, inspection_date TEXT,
  photo_path TEXT, notes TEXT, created_at TEXT, updated_at TEXT
)
fuel_records (
  id INTEGER PK, vehicle_id → vehicles(id) ON DELETE CASCADE,
  date TEXT, mileage INTEGER CHECK (>= 0), fuel_type TEXT, quantity REAL CHECK (> 0),
  unit_price REAL, total_cost REAL, full_tank INTEGER, station TEXT, note TEXT,
  mileage_source TEXT DEFAULT 'manual', created_at TEXT, updated_at TEXT
)
service_records (
  id INTEGER PK, vehicle_id → vehicles(id) ON DELETE CASCADE,
  kind TEXT CHECK (IN ('maintenance','service')), date TEXT, mileage INTEGER CHECK (>= 0),
  description TEXT, workshop TEXT, cost REAL, note TEXT,
  mileage_source TEXT DEFAULT 'manual', created_at TEXT, updated_at TEXT
)
settings (key TEXT PK, value TEXT)
```

- Tarihler `yyyy-MM-dd` (saat dilimi kayması olmaz), zaman damgaları ISO 8601.
- `PRAGMA foreign_keys = ON` her bağlantıda açılır; araç silinince kayıtları da silinir.
- Şema değişiklikleri `onUpgrade` içinde sürüm sürüm göç adımlarıyla eklenir.

## Kilometre kuralları

| Durum | Davranış |
|---|---|
| Boş, harf, negatif, > 2.000.000 | Engellenir (form hatası) |
| Gelecek tarih | Engellenir |
| Aynı gün veya önceki kayıttan düşük | Uyarı + kullanıcı onayı |
| Sonraki tarihli kayıttan yüksek | Uyarı + kullanıcı onayı |

Geçmiş; araç kaydındaki başlangıç kilometresi, yakıt, bakım ve servis kayıtlarından türetilir. Değer üretilmez veya tahmin edilmez.

**OBD hazırlığı:** Her kilometre değeri `mileage_source` (`manual` / `obd`) ile saklanır. İleride bir OBD okuyucu, aynı doğrulama kurallarından geçerek kayıt oluşturabilir. Bu sürümde OBD bağlantısı **yoktur**.

## Yasal tarihler

`LegalStatus.evaluate(tarih, bugün, uyarıGünü)` → `expired` / `dueSoon` / `valid` / `notSet`. Gün farkı UTC tarihler üzerinden hesaplanır (yaz saati geçişlerinden etkilenmez). Uyarılar yalnızca uygulama içindedir.

## Platform kurulumu

`android/` ve `windows/` klasörleri `tool/setup.dart` ile, kullanılan Flutter sürümünün resmi şablonundan üretilir ve şu ayarlar uygulanır: uygulama adı, koyu açılış ekranı, pencere boyutu, Windows dosya bilgileri, simgeler. Böylece platform şablonları Flutter sürümüyle uyumlu kalır ve projeye özel ayarlar tek dosyada görülür.
