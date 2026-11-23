import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/enums.dart';
import '../../data/models/vehicle.dart';
import '../../state/app_scope.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/vehicle_visuals.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final vehicles = app.vehicles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Araçlarım'),
        actions: [
          if (vehicles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${vehicles.length} araç',
                  style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: vehicles.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const Key('fab_add_vehicle'),
              heroTag: 'fab_add_vehicle',
              onPressed: () => openVehicleForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Araç Ekle'),
            ),
      body: vehicles.isEmpty
          ? EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'Garajın boş',
              message: 'Otomobil, motosiklet, ticari araç veya traktör… Kaydını tutmak istediğin ilk aracı ekle.',
              actionLabel: 'Araç Ekle',
              actionKey: const Key('vehicles_empty_add'),
              onAction: () => openVehicleForm(context),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final padding = pagePadding(constraints.maxWidth, top: 8, bottom: 100);
                final available = constraints.maxWidth - padding.horizontal;
                final columns = math.max(1, (available / 380).floor());
                final cardWidth = (available - (columns - 1) * 16) / columns;
                final selectedId = app.selectedVehicle?.id;
                return ListView(
                  padding: padding,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (var i = 0; i < vehicles.length; i++)
                          SizedBox(
                            width: cardWidth,
                            child: FadeIn(
                              delay: Duration(milliseconds: math.min(i, 6) * 40),
                              child: VehicleCard(
                                vehicle: vehicles[i],
                                selected: vehicles[i].id == selectedId,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle, this.selected = false});

  final Vehicle vehicle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final km = app.lastMileage(vehicle.id!);
    final insurance = app.legalStatus(vehicle, LegalKind.insurance);
    final inspection = app.legalStatus(vehicle, LegalKind.inspection);
    final subtitle = vehicle.nickname == null ? vehicle.category.label : vehicle.fullTitle;

    return AppCard(
      onTap: () => openVehicleDetail(context, vehicle.id!),
      borderColor: selected ? const Color(0x80FF7A1A) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VehicleAvatar(vehicle: vehicle, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.nickname == null ? vehicle.fullTitle : vehicle.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (vehicle.plate != null || selected) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (vehicle.plate != null) PlatePill(plate: vehicle.plate!),
                          if (selected)
                            const StatusPill(
                              label: 'Panelde',
                              color: AppColors.orange,
                              icon: Icons.push_pin_rounded,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.speed_rounded,
                  label: 'Son kilometre',
                  value: km == null ? '—' : Fmt.km(km),
                ),
              ),
              Expanded(
                child: _Metric(
                  icon: vehicle.fuelType.icon,
                  label: 'Yakıt',
                  value: vehicle.fuelType.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: 'Sigorta: ${insurance.shortLabel}',
                color: legalColor(insurance.state),
              ),
              StatusPill(
                label: 'Muayene: ${inspection.shortLabel}',
                color: legalColor(inspection.state),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
