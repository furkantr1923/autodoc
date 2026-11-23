import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/enums.dart';
import '../../domain/legal_status.dart';
import 'common.dart';

/// Sigorta / muayene için büyük durum kartı.
class LegalCard extends StatelessWidget {
  const LegalCard({super.key, required this.kind, required this.status, this.onTap});

  final LegalKind kind;
  final LegalStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = legalColor(status.state);
    final date = status.date;
    return AppCard(
      onTap: onTap,
      borderColor: status.needsAttention ? color.withAlpha(140) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(kind.icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(kind.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              StatusPill(label: status.shortLabel, color: color),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            date == null ? 'Tarih girilmedi' : Fmt.date(date),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            date == null ? 'Araç düzenleme ekranından ekleyebilirsin.' : status.detailLabel,
            style: TextStyle(color: date == null ? AppColors.textMuted : color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Panel listesindeki tek satırlık yasal tarih görünümü.
class LegalRow extends StatelessWidget {
  const LegalRow({
    super.key,
    required this.title,
    required this.kind,
    required this.status,
    this.onTap,
  });

  final String title;
  final LegalKind kind;
  final LegalStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = legalColor(status.state);
    final date = status.date;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(kind.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${kind.label} · $title',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date == null ? 'Tarih girilmedi' : '${Fmt.date(date)} · ${status.detailLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(label: status.shortLabel, color: color),
          ],
        ),
      ),
    );
  }
}
