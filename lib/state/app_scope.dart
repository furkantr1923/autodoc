import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// [AppState]'i widget ağacına sağlar; durum değiştiğinde bağımlı widget'lar yeniden çizilir.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Durumu okur ve değişikliklere abone olur (build içinde kullanılır).
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı.');
    return scope!.notifier!;
  }

  /// Durumu abone olmadan okur (olay işleyicilerinde kullanılır).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı.');
    return scope!.notifier!;
  }
}
