# Test Raporu — AUTODOC 1.0.0

> **Durum notu (dürüstlük ilkesi):** Bu belge testlerin *kapsamını ve nerede çalıştığını* tanımlar.
> Kod, Flutter SDK'sı bulunmayan bir ortamda yazıldığı için testler henüz **hiç çalıştırılmadı**.
> Gerçek sonuçlar, depo GitHub'a gönderildiğinde CI tarafından üretilir ve aşağıdaki
> "Sonuç" sütunu o çıktılara göre doldurulmalıdır. Çalıştırılmamış hiçbir test "geçti" olarak işaretlenmemiştir.

## Otomatik test katmanları

| Katman | Dosya | Ortam | Kanıt (CI artifact) |
|---|---|---|---|
| Birim | `test/domain/*`, `test/core/*` | Ubuntu, `flutter test` | `test-sonuclari/test-output.txt` |
| Veritabanı (gerçek SQLite) | `test/data/database_test.dart` | Ubuntu, sqflite FFI | `test-sonuclari/test-output.txt` |
| Arayüz (widget) | `test/widget_test.dart` | Ubuntu, `flutter test` | `test-sonuclari/test-output.txt` |
| Release kendini sınama | `lib/self_test.dart` | Windows, derlenmiş `autodoc.exe` | `windows-test-sonuclari/windows-selftest.txt` |
| Uçtan uca | `integration_test/app_test.dart` | Windows masaüstü | `windows-test-sonuclari/windows-integration.txt` |
| Uçtan uca | `integration_test/app_test.dart` | Android 14 emülatör (x86_64) | `android-test-sonuclari/android-integration.txt` |
| Paket doğrulama | CI adımları | Windows / Ubuntu | Setup.exe + ZIP üretimi, `apk-verify.txt` |

## Gereksinim → test eşlemesi

### Windows

| Gereksinim | Nasıl test ediliyor | Tür | Sonuç |
|---|---|---|---|
| Kurulum | Setup.exe derlenir; kurulum sihirbazı elle denenmeli | Paket + **manuel** | ☐ |
| İlk açılış | Uçtan uca test: boş veritabanı → karşılama ekranı | Otomatik | ☐ |
| Araç ekleme | Uçtan uca test + veritabanı testi | Otomatik | ☐ |
| Araç düzenleme / silme | Veritabanı testi; uçtan uca silme akışı | Otomatik | ☐ |
| Yakıt kayıtları | Uçtan uca (toplam hesabı dahil) + veritabanı testi | Otomatik | ☐ |
| Bakım / servis kayıtları | Veritabanı testi; self-test | Otomatik | ☐ |
| Kilometre doğrulama | Birim testleri + uçtan uca uyarı diyaloğu | Otomatik | ☐ |
| Sigorta / muayene tarihleri | Birim (sınır günleri, artık yıl) + veritabanı testi | Otomatik | ☐ |
| Arama | Veritabanı + arayüz testi (Türkçe karakter duyarsız) | Otomatik | ☐ |
| Çevrimdışı çalışma | Uygulamada ağ kodu yok; Android manifestinde INTERNET izni yalnızca hata ayıklama derlemesinde | Kod incelemesi + **manuel** | ☐ |
| Yeniden başlatma ve kalıcılık | Uçtan uca: veritabanı kapat-aç; self-test | Otomatik | ☐ |
| Paketli sqlite3.dll | Release exe kendini sınama | Otomatik | ☐ |

### Android

| Gereksinim | Nasıl test ediliyor | Tür | Sonuç |
|---|---|---|---|
| APK kurulumu | APK üretimi + `apksigner verify`; cihaza kurulum elle | Paket + **manuel** | ☐ |
| İlk açılış | Emülatörde uçtan uca test | Otomatik | ☐ |
| Gezinme ve geri tuşu | Arayüz testi (alt menü, geri → Panel, form çıkış onayı) | Otomatik | ☐ |
| Araç yönetimi | Emülatörde uçtan uca test | Otomatik | ☐ |
| Kayıt oluşturma / düzenleme | Uçtan uca + veritabanı testi | Otomatik | ☐ |
| Veritabanı kalıcılığı | Emülatörde kapat-aç | Otomatik | ☐ |
| Ekran uyumu | Arayüz testi 360×780 dp; taşma (overflow) test hatası sayılır | Otomatik | ☐ |
| Çevrimdışı | Ağ kodu yok | Kod incelemesi + **manuel** | ☐ |
| Uygulamayı yeniden başlatma | Gerçek cihazda elle | **Manuel** | ☐ |

### Genel kontroller

| Kontrol | Yöntem | Sonuç |
|---|---|---|
| Çökme | Tüm otomatik testler + manuel deneme | ☐ |
| Bozuk gezinme | Arayüz ve uçtan uca testler | ☐ |
| Veritabanı hataları | Veritabanı testleri, CHECK kısıtları, CASCADE | ☐ |
| Yanlış hesaplama | `FuelMath` testleri, uçtan uca toplam kontrolü | ☐ |
| Arayüz taşması | Telefon boyutunda arayüz testi | ☐ |
| Türkçe karakterler | Veritabanı ve self-test (Ç, Ş, Ğ, İ, Ö, Ü kalıcılığı) | ☐ |
| Tarih işleme | Gün farkı (UTC), artık yıl, gelecek tarih engeli | ☐ |
| Normal kullanımda veri kaybı | Kapat-aç kalıcılık testleri | ☐ |

## Manuel test kontrol listesi (sürüm öncesi)

1. Windows 10 veya 11'de Setup.exe ile kur → başlat menüsünden aç → araç ekle → kapat → yeniden aç → veri duruyor mu?
2. Kaldır → yeniden kur → veri klasörünün davranışını not et.
3. Taşınabilir ZIP'i masaüstüne çıkar → aç → `AUTODOC-Veri` klasörü oluştu mu?
4. Android telefonda APK kur → uçak modunda tüm ekranları gez → araç, yakıt, bakım ekle → uygulamayı kapat (son uygulamalardan kaydır) → aç.
5. Telefonu yatay çevir, yazı boyutunu büyüt (Ayarlar → Ekran) → taşma var mı?

## Sonuç kaydı

| Tarih | CI çalıştırma bağlantısı | Özet |
|---|---|---|
| — | — | Henüz çalıştırılmadı |
