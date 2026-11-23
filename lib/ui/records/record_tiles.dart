import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/fuel_record.dart';
import '../../data/models/record_entry.dart';
import '../../data/models/service_record.dart';
import '../navigation.dart';

class RecordTile extends StatelessWidget {
  const RecordTile({super.key, required this.entry, this.vehicleName});

  final RecordEntry entry;
  final String? vehicleName;

  @override
  Widget build(BuildContext context) {
    final fuel = entry.fuel;
    if (fuel != null) return FuelTile(record: fuel, vehicleName: vehicleName);
    return ServiceTile(record: entry.service!, vehicleName: vehicleName);
  }
}

class FuelTile extends StatelessWidget {
  const FuelTile({super.key, required this.record, this.vehicleName});

  final FuelRecord record;
  final String? vehicleName;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      Fmt.date(record.date),
      Fmt.km(record.mileage),
      if (record.station != null) record.station!,
    ];
    return _RecordTileFrame(
      icon: record.fuelType.icon,
      accent: AppColors.info,
      title: '${Fmt.decimal(record.quantity)} ${record.fuelType.unit} • ${record.fuelType.label}'
          '${record.fullTank ? ' • Depo dolu' : ''}',
      subtitle: parts.join('  ·  '),
      vehicleName: vehicleName,
      trailing: record.totalCost == null ? null : Fmt.money(record.totalCost!),
      onTap: () => openFuelForm(context, vehicleId: record.vehicleId, record: record),
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.record, this.vehicleName});

  final ServiceRecord record;
  final String? vehicleName;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      record.kind.label,
      Fmt.date(record.date),
      Fmt.km(record.mileage),
      if (record.workshop != null) record.workshop!,
    ];
    return _RecordTileFrame(
      icon: record.kind.icon,
      accent: AppColors.orange,
      title: record.description,
      subtitle: parts.join('  ·  '),
      vehicleName: vehicleName,
      trailing: record.cost == null ? null : Fmt.money(record.cost!),
      onTap: () => openServiceForm(
        context,
        vehicleId: record.vehicleId,
        kind: record.kind,
        record: record,
      ),
    );
  }
}

class _RecordTileFrame extends StatelessWidget {
  const _RecordTileFrame({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.vehicleName,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String? trailing;
  final String? vehicleName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineSoft),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(34),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vehicleName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            vehicleName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  Text(trailing!, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
