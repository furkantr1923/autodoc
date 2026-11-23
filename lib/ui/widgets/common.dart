import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/legal_status.dart';

/// Geniş ekranlarda içeriği ortalayan, dar ekranlarda kenar boşluğu bırakan dolgu.
EdgeInsets pagePadding(double width, {double maxWidth = 1120, double top = 8, double bottom = 32}) {
  final horizontal = math.max(16.0, (width - maxWidth) / 2);
  return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
}

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 720;

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.borderColor,
    this.color,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      color: gradient == null ? (color ?? AppColors.surface) : Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          border: Border.all(color: borderColor ?? AppColors.outlineSoft),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction, this.icon});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.orange),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 72.0 : 104.0;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Color(0x55FF7A1A), Color(0x00FF7A1A)]),
          ),
          alignment: Alignment.center,
          child: Container(
            width: size * 0.64,
            height: size * 0.64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceHigh,
              border: Border.all(color: const Color(0x80FF7A1A)),
            ),
            child: Icon(icon, color: AppColors.orange, size: size * 0.3),
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: compact ? 15 : 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: compact ? 14 : 22),
          FilledButton.icon(
            key: actionKey,
            onPressed: onAction,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );
    return FadeIn(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 16 : 32),
          child: content,
        ),
      ),
    );
  }
}

/// Ölçülü giriş animasyonu (opaklık + hafif kayma).
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = const Duration(milliseconds: 320) + delay;
    final start = total.inMilliseconds == 0 ? 0.0 : delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: child,
    );
  }
}

Color legalColor(LegalState state) => switch (state) {
      LegalState.expired => AppColors.danger,
      LegalState.dueSoon => AppColors.warning,
      LegalState.valid => AppColors.success,
      LegalState.notSet => AppColors.textMuted,
    };

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 13, color: color)
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Türkiye plakası görünümünde etiket.
class PlatePill extends StatelessWidget {
  const PlatePill({super.key, required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF1B1F27), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            decoration: const BoxDecoration(
              color: Color(0xFF0033A0),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(3)),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 2),
            child: const Text(
              'TR',
              style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                plate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                color: Color(0xFF0D1117),
                fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.size = 34});

  final bool compact;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset('assets/images/logo.png', width: size, height: size, filterQuality: FilterQuality.medium),
    );
    if (compact) return logo;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: 10),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'AUTO'),
              TextSpan(text: 'DOC', style: TextStyle(color: AppColors.orange)),
            ],
          ),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2.2),
        ),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 12),
          ],
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Onayla',
  String cancelLabel = 'Vazgeç',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.45)),
      actions: [
        TextButton(
          key: const Key('confirm_cancel'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          key: const Key('confirm_ok'),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white)
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Kaydedilmemiş değişiklik varken geri tuşunu onaya bağlar.
Future<bool> confirmDiscardChanges(BuildContext context) => showConfirmDialog(
      context,
      title: 'Kaydedilmemiş değişiklikler',
      message: 'Yaptığın değişiklikler kaydedilmedi. Çıkarsan kaybolacak.',
      confirmLabel: 'Çık',
      cancelLabel: 'Düzenlemeye dön',
      destructive: true,
    );

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: error ? AppColors.danger : AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Sayfa içeriğini geniş ekranda ortalar.
class CenteredContent extends StatelessWidget {
  const CenteredContent({super.key, required this.child, this.maxWidth = 760});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Uygulama adı ve geliştirici satırı (alt bilgi).
class DeveloperFooter extends StatelessWidget {
  const DeveloperFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Text(
        '${AppInfo.name} ${AppInfo.version}  •  ${AppInfo.developerLine}',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    );
  }
}
