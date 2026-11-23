import 'dart:io';

import 'package:autodoc/app.dart';
import 'package:autodoc/core/app_info.dart';
import 'package:autodoc/data/models/enums.dart';
import 'package:autodoc/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers.dart';

/// Arayüz testleri. Veritabanı gerçek SQLite (FFI) ile `runAsync` içinde hazırlanır;
/// testler gezinme, doğrulama mesajları, geri tuşu ve taşma (overflow) kontrolü yapar.
void main() {
  setUpAll(() async {
    ensureFfi();
    await initializeDateFormatting('tr_TR');
  });

  Future<AppState> prepare(WidgetTester tester, {bool withData = false}) async {
    final state = await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('autodoc_widget_');
      final s = await createTestState(dir);
      if (withData) {
        final id = await s.saveVehicle(sampleVehicle(initialMileage: null, insurance: DateTime(2026, 12, 5)));
        await s.saveVehicle(sampleVehicle(
          make: 'Yamaha',
          model: 'MT-07',
          plate: '34 MT 07',
          category: VehicleCategory.motorcycle,
          fuelType: FuelType.gasoline,
        ));
        await s.saveFuel(sampleFuel(id, date: DateTime(2026, 11, 1), mileage: 100500, station: 'Çorum Merkez'));
        await s.saveService(sampleService(id, date: DateTime(2026, 11, 10), mileage: 100900, description: 'Motor yağı ve filtre değişimi'));
        await s.saveService(sampleService(id, date: DateTime(2026, 11, 15), mileage: 100700, kind: ServiceKind.service, description: 'Fren balatası'));
      }
      return s;
    });
    return state!;
  }

  Finder navItem(String label) {
    final rail = find.byKey(const Key('nav_rail'));
    final bar = find.byKey(const Key('nav_bar'));
    final container = rail.evaluate().isNotEmpty ? rail : bar;
    return find.descendant(of: container, matching: find.text(label)).first;
  }

  testWidgets('boş uygulama: karşılama ekranı ve Türkçe menüler', (tester) async {
    final state = await prepare(tester);
    await tester.pumpWidget(AutodocApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('AUTODOC\'a hoş geldin'), findsOneWidget);
    expect(find.byKey(const Key('add_vehicle_button')), findsOneWidget);
    for (final label in ['Panel', 'Araçlar', 'Ara', 'Ayarlar']) {
      expect(navItem(label), findsOneWidget);
    }
  });

  testWidgets('araç formu: zorunlu alanlar ve kaydedilmemiş değişiklik onayı', (tester) async {
    final state = await prepare(tester);
    await tester.pumpWidget(AutodocApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_vehicle_button')));
    await tester.pumpAndSettle();
    expect(find.text('Yeni araç'), findsOneWidget);

    await tester.tap(find.byKey(const Key('vehicle_save')));
    await tester.pumpAndSettle();
    expect(find.text('Marka girin.'), findsOneWidget);
    expect(find.text('Model girin.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('vehicle_year')), '1800');
    await tester.enterText(find.byKey(const Key('vehicle_mileage')), '3000000');
    await tester.tap(find.byKey(const Key('vehicle_save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('arasında olmalı'), findsOneWidget);
    expect(find.textContaining('gerçekçi değil'), findsOneWidget);

    // Geri: değişiklik olduğu için onay istenir.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Kaydedilmemiş değişiklikler'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_ok')));
    await tester.pumpAndSettle();
    expect(find.text('AUTODOC\'a hoş geldin'), findsOneWidget);
    expect(state.vehicles, isEmpty, reason: 'iptal edilen form veritabanına yazmaz');
  });

  testWidgets('verili uygulama: panel, araçlar, arama ve hakkında ekranı', (tester) async {
    final state = await prepare(tester, withData: true);
    await tester.pumpWidget(AutodocApp(state: state));
    await tester.pumpAndSettle();

    // Panel
    expect(find.text('Peugeot 2008'), findsWidgets);
    expect(find.byKey(const Key('legal_alert_banner')), findsOneWidget);
    expect(find.text('Son kayıtlar'), findsOneWidget);
    expect(find.textContaining('Fren balatası'), findsWidgets);

    // Araçlar
    await tester.tap(navItem('Araçlar'));
    await tester.pumpAndSettle();
    expect(find.text('Araçlarım'), findsOneWidget);
    expect(find.text('2 araç'), findsOneWidget);
    expect(find.text('34 MT 07'), findsOneWidget);

    // Arama (Türkçe karakter duyarsız)
    await tester.tap(navItem('Ara'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search_field')), 'yag degisimi');
    await tester.pumpAndSettle();
    expect(find.text('Bakım ve servis (1)'), findsOneWidget);
    expect(find.text('Araçlar (1)'), findsNothing);
    await tester.enterText(find.byKey(const Key('search_field')), 'motosiklet');
    await tester.pumpAndSettle();
    expect(find.text('Araçlar (1)'), findsOneWidget);

    // Ayarlar → Hakkında
    await tester.tap(navItem('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_about')));
    await tester.pumpAndSettle();
    expect(find.text(AppInfo.tagline), findsOneWidget);
    expect(find.text(AppInfo.developerLine), findsOneWidget);
  });

  testWidgets('telefon ekranı: alt menü, geri tuşu ve taşma olmadan detay sekmeleri', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = await prepare(tester, withData: true);
    await tester.pumpWidget(AutodocApp(state: state));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav_bar')), findsOneWidget);
    expect(find.byKey(const Key('nav_rail')), findsNothing);

    // Ayarlar sekmesine geç, Android geri tuşu Panel'e döndürmeli.
    await tester.tap(navItem('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('Veri ve gizlilik'), findsOneWidget);
    expect(selectedTab(tester), 3);
    // ignore: invalid_use_of_protected_member
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(selectedTab(tester), 0, reason: 'geri tuşu önce Panel sekmesine döner');

    // Araç detayı ve tüm sekmeler
    await tester.ensureVisible(find.byKey(const Key('open_vehicle_detail')));
    await tester.tap(find.byKey(const Key('open_vehicle_detail')));
    await tester.pumpAndSettle();
    expect(find.text('Araç bilgileri'), findsOneWidget);
    for (final tab in ['Yakıt', 'Bakım & Servis', 'Kilometre']) {
      final tabFinder = find.widgetWithText(Tab, tab);
      await tester.ensureVisible(tabFinder);
      await tester.pumpAndSettle();
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('düşüş'), findsWidgets, reason: '100.900 → 100.700 km düşüşü işaretlenmeli');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Araç bilgileri'), findsNothing);
    expect(selectedTab(tester), 0);
  });
}

int selectedTab(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byKey(const Key('nav_bar'))).selectedIndex;
