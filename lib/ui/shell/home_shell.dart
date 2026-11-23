import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_page.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';
import '../vehicles/vehicles_page.dart';
import '../widgets/common.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const List<_Destination> _destinations = [
  _Destination('Panel', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  _Destination('Araçlar', Icons.directions_car_outlined, Icons.directions_car_rounded),
  _Destination('Ara', Icons.search_rounded, Icons.manage_search_rounded),
  _Destination('Ayarlar', Icons.settings_outlined, Icons.settings_rounded),
];

/// Ana iskelet: geniş ekranda (Windows) yan menü, dar ekranda (Android) alt menü.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.portable = false});

  final bool portable;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pages = <Widget>[
      DashboardPage(onNavigate: _go),
      const VehiclesPage(),
      const SearchPage(),
      const SettingsPage(),
    ];
    final body = IndexedStack(index: _index, children: pages);

    final Widget scaffold;
    if (width >= 720) {
      final extended = width >= 1100;
      scaffold = Scaffold(
        body: Row(
          children: [
            NavigationRail(
              key: const Key('nav_rail'),
              extended: extended,
              minExtendedWidth: 224,
              selectedIndex: _index,
              onDestinationSelected: _go,
              labelType: extended ? null : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 22),
                child: extended
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: BrandMark(),
                      )
                    : const BrandMark(compact: true),
              ),
              trailing: widget.portable
                  ? const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Tooltip(
                        message: 'Taşınabilir sürüm: veriler uygulama klasöründe',
                        child: Icon(Icons.usb_rounded, color: AppColors.textMuted),
                      ),
                    )
                  : null,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.outlineSoft),
            Expanded(child: body),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          key: const Key('nav_bar'),
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    // Android geri tuşu: önce Panel'e dön, Panel'deyken uygulamadan çık.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Title(
        title: AppInfo.name,
        color: AppColors.orange,
        child: scaffold,
      ),
    );
  }
}
