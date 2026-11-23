import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: ListView(
        padding: pagePadding(width, maxWidth: 640, top: 12, bottom: 32),
        children: [
          FadeIn(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55FF7A1A), blurRadius: 40, spreadRadius: 2),
                    ],
                  ),
                  child: const BrandMark(compact: true, size: 112),
                ),
                const SizedBox(height: 22),
                const Text(
                  AppInfo.name,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 4),
                ),
                const SizedBox(height: 4),
                const Text(
                  AppInfo.tagline,
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                const StatusPill(label: 'Sürüm ${AppInfo.version}', color: AppColors.orange),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const AppCard(
            child: Text(
              'AUTODOC; araçlarını, kilometre geçmişini, yakıt alımlarını, bakım ve servis kayıtlarını, '
              'sigorta ve muayene tarihlerini tek yerde düzenli tutman için tasarlanmış, tamamen '
              'çevrimdışı çalışan bir araç yönetim uygulamasıdır.',
              style: TextStyle(height: 1.55),
            ),
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: Column(
              children: [
                _Feature(icon: Icons.wifi_off_rounded, text: 'İnternet gerektirmez, hesap istemez'),
                _Feature(icon: Icons.lock_outline_rounded, text: 'Veriler yalnızca bu cihazda saklanır'),
                _Feature(icon: Icons.speed_rounded, text: 'Kilometre doğrulaması ve düşüş uyarısı'),
                _Feature(icon: Icons.event_available_rounded, text: 'Sigorta ve muayene takibi'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x33FF7A1A), Color(0x0DFF7A1A)],
            ),
            borderColor: const Color(0x66FF7A1A),
            child: const Row(
              children: [
                Icon(Icons.code_rounded, color: AppColors.orange),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Geliştirici', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                      SizedBox(height: 2),
                      Text(
                        AppInfo.developerLine,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      SizedBox(height: 2),
                      Text(AppInfo.github, style: TextStyle(color: AppColors.orange)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            AppInfo.copyright,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
