import 'package:autodoc/app.dart';
import 'package:autodoc/bootstrap.dart';
import 'package:autodoc/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Gerçek cihazda / emülatörde / Windows'ta uçtan uca test.
///
/// Çalıştırma:
///   flutter test integration_test/app_test.dart -d windows
///   flutter test integration_test/app_test.dart -d emulator-5554
/// Veritabanı işlemleri gerçek zamanlı ve asenkron olduğu için koşul sağlanana kadar bekler.
Future<void> waitUntil(WidgetTester tester, bool Function() condition,
    {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uçtan uca: araç → yakıt → kilometre uyarısı → kalıcılık → silme', (tester) async {
    await initializeAppLocale();
    final tmp = await getTemporaryDirectory();
    final dir = p.join(tmp.path, 'autodoc_it_${DateTime.now().millisecondsSinceEpoch}');
    final dbPath = p.join(dir, 'autodoc_it.db');
    final photos = p.join(dir, 'fotograflar');
    final factory = platformDatabaseFactory();

    Future<AppState> open() => createAppState(factory: factory, databasePath: dbPath, photosDir: photos);

    var state = await open();
    await tester.pumpWidget(AutodocApp(state: state));
    await tester.pumpAndSettle();

    // 1) İlk açılış: karşılama ekranı
    expect(find.byKey(const Key('add_vehicle_button')), findsOneWidget);

    // 2) Araç ekle
    await tester.tap(find.byKey(const Key('add_vehicle_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('vehicle_make')), 'Peugeot');
    await tester.enterText(find.byKey(const Key('vehicle_model')), '2008');
    await tester.enterText(find.byKey(const Key('vehicle_year')), '2016');
    await tester.enterText(find.byKey(const Key('vehicle_plate')), '19 ab 2016');
    await tester.enterText(find.byKey(const Key('vehicle_mileage')), '84.000');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vehicle_save')));
    await waitUntil(tester, () => state.vehicles.isNotEmpty);

    expect(state.vehicles, hasLength(1));
    expect(state.vehicles.single.plate, '19 AB 2016');
    expect(find.text('Peugeot 2008'), findsWidgets);

    // 3) Yakıt kaydı ekle (toplam tutar otomatik hesaplanır)
    await tester.ensureVisible(find.byKey(const Key('quick_fuel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick_fuel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('fuel_mileage')), '85000');
    await tester.enterText(find.byKey(const Key('fuel_quantity')), '40');
    await tester.enterText(find.byKey(const Key('fuel_unit_price')), '45,50');
    await tester.pumpAndSettle();
    final total = tester.widget<TextFormField>(find.byKey(const Key('fuel_total'))).controller!.text;
    expect(total, '1820');
    final vehicleId = state.vehicles.single.id!;
    await tester.tap(find.byKey(const Key('fuel_save')));
    await waitUntil(tester, () => state.fuelFor(vehicleId).isNotEmpty);

    expect(state.fuelFor(vehicleId), hasLength(1));
    expect(state.fuelFor(vehicleId).single.totalCost, 1820);
    expect(state.lastMileage(vehicleId), 85000);
    expect(find.textContaining('40 L'), findsWidgets);

    // 4) Şüpheli kilometre düşüşü uyarısı
    await tester.ensureVisible(find.byKey(const Key('quick_fuel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick_fuel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('fuel_mileage')), '80000');
    await tester.enterText(find.byKey(const Key('fuel_quantity')), '30');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fuel_save')));
    await tester.pumpAndSettle();
    expect(find.text('Kilometre uyarısı'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mileage_fix')));
    await tester.pumpAndSettle();
    expect(state.fuelFor(vehicleId), hasLength(1), reason: 'onay verilmeden kaydedilmemeli');

    // Kaydedilmemiş değişiklikle geri dön → onay → çık
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_ok')));
    await tester.pumpAndSettle();

    // 5) Veritabanını kapat ve yeniden aç: kalıcılık
    await state.database.close();
    state = await open();
    expect(state.vehicles, hasLength(1));
    expect(state.fuelFor(vehicleId), hasLength(1));
    expect(state.lastMileage(vehicleId), 85000);

    await tester.pumpWidget(AutodocApp(key: UniqueKey(), state: state));
    await tester.pumpAndSettle();
    expect(find.text('Peugeot 2008'), findsWidgets);

    // 6) Aracı sil: kayıtlar da silinir
    await tester.ensureVisible(find.byKey(const Key('open_vehicle_detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_vehicle_detail')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vehicle_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('vehicle_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_ok')));
    await waitUntil(tester, () => state.vehicles.isEmpty);

    expect(state.vehicles, isEmpty);
    expect(state.recordsFor(vehicleId), isEmpty);
    expect(find.byKey(const Key('add_vehicle_button')), findsOneWidget);

    await state.database.close();
  });
}
