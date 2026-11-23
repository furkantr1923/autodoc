import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/legal_status.dart';
import '../../state/app_scope.dart';
import '../widgets/common.dart';
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: pagePadding(width, maxWidth: 760, top: 8, bottom: 24),
        children: [
          const SectionHeader(title: 'Hatırlatmalar', icon: Icons.notifications_active_outlined),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yasal tarih uyarı süresi', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'Sigorta ve muayene bitiş tarihi bu süre içine girdiğinde panelde ve araç kartlarında '
                  '"Yaklaşıyor" olarak gösterilir. Uyarılar yalnızca uygulama içindedir.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<int>(
                    key: const Key('warn_days'),
                    showSelectedIcon: false,
                    segments: [
                      for (final d in LegalStatus.warnDayOptions)
                        ButtonSegment(value: d, label: Text('$d gün')),
                    ],
                    selected: {app.warnDays},
                    onSelectionChanged: (s) => app.setWarnDays(s.first),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Veri ve gizlilik', icon: Icons.shield_outlined),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PrivacyLine(
                  icon: Icons.wifi_off_rounded,
                  title: 'Tamamen çevrimdışı',
                  text: 'İnternet bağlantısı gerekmez; hiçbir veri dışarı gönderilmez.',
                ),
                const _PrivacyLine(
                  icon: Icons.phonelink_lock_rounded,
                  title: 'Yalnızca bu cihazda',
                  text: 'Hesap, üyelik veya bulut yoktur. Windows ve Android verileri birbirinden bağımsızdır.',
                ),
                const _PrivacyLine(
                  icon: Icons.warning_amber_rounded,
                  title: 'Yedekleme yoktur',
                  text: 'Uygulama kaldırılırsa veya verileri silinirse kayıtlar geri getirilemez.',
                ),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Veritabanı konumu', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 4),
                SelectableText(app.database.path, style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
          const SectionHeader(title: 'Uygulama', icon: Icons.apps_rounded),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  key: const Key('open_about'),
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Hakkında'),
                  subtitle: const Text('${AppInfo.name} ${AppInfo.version}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AboutPage()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Açık kaynak lisansları'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppInfo.name,
                    applicationVersion: AppInfo.version,
                    applicationLegalese: AppInfo.copyright,
                  ),
                ),
              ],
            ),
          ),
          const DeveloperFooter(),
        ],
      ),
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
