import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/enums.dart';
import '../../data/models/vehicle.dart';
import '../../domain/legal_status.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';
import '../navigation.dart';
import '../records/record_tiles.dart';
import '../widgets/common.dart';
import '../widgets/legal_widgets.dart';
import '../widgets/vehicle_visuals.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onNavigate});

  /// Ana sekmeler arasında geçiş (0: Panel, 1: Araçlar, 2: Ara, 3: Ayarlar).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final wide = isWide(context);
    final vehicles = app.vehicles;

    return Scaffold(
      appBar: AppBar(
        title: wide ? const Text('Panel') : const BrandMark(),
        actions: [
          IconButton(
            tooltip: 'Ara',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => onNavigate(2),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: vehicles.isEmpty
          ? EmptyState(
              icon: Icons.directions_car_filled_rounded,
              title: 'AUTODOC\'a hoş geldin',
              message: 'Araçlarını, yakıt alımlarını, bakım ve servis geçmişini, sigorta ve muayene '
                  'tarihlerini tek yerde tut. Tüm veriler yalnızca bu cihazda saklanır.',
              actionLabel: 'İlk aracını ekle',
              actionKey: const Key('add_vehicle_button'),
              onAction: () => openVehicleForm(context),
            )
          : LayoutBuilder(
              builder: (context, constraints) => _DashboardBody(
                app: app,
                width: constraints.maxWidth,
                onNavigate: onNavigate,
              ),
            ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.app, required this.width, required this.onNavigate});

  final AppState app;
  final double width;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final vehicles = app.vehicles;
    final selected = app.selectedVehicle ?? vehicles.first;
    final legal = app.legalOverview();
    final alerts = legal.where((i) => i.status.needsAttention).toList();
    final recent = app.recordsFor(selected.id!).take(5).toList();
    final twoColumns = width >= 1100;

    final hero = _SelectedVehicleCard(vehicle: selected);
    final recentSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Son kayıtlar',
          icon: Icons.history_rounded,
          actionLabel: recent.isEmpty ? null : 'Tümü',
          onAction: () => openVehicleDetail(context, selected.id!, tab: 1),
        ),
        if (recent.isEmpty)
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.inbox_outlined, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${selected.displayName} için henüz kayıt yok. Yakıt veya bakım kaydı ekleyerek başla.',
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          )
        else
          for (final e in recent) RecordTile(entry: e),
      ],
    );
    final legalSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Yasal tarihler', icon: Icons.event_available_rounded),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < legal.length && i < 8; i++) ...[
                if (i > 0) const Divider(),
                LegalRow(
                  title: legal[i].vehicle.displayName,
                  kind: legal[i].kind,
                  status: legal[i].status,
                  onTap: () => openVehicleDetail(context, legal[i].vehicle.id!),
                ),
              ],
            ],
          ),
        ),
        if (legal.length > 8)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+${legal.length - 8} tarih daha · Araç detaylarında görüntüle',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ),
      ],
    );

    return ListView(
      padding: pagePadding(width, top: 4, bottom: 32),
      children: [
        _Greeting(today: app.today, vehicleCount: vehicles.length),
        if (alerts.isNotEmpty) _AlertBanner(items: alerts),
        if (vehicles.length > 1) _VehicleSwitcher(vehicles: vehicles, selectedId: selected.id!),
        const SizedBox(height: 12),
        if (twoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [hero, recentSection]),
              ),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: legalSection),
            ],
          )
        else ...[
          hero,
          legalSection,
          recentSection,
        ],
        const DeveloperFooter(),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.today, required this.vehicleCount});

  final DateTime today;
  final int vehicleCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Fmt.weekday(today)}, ${Fmt.date(today)}',
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            vehicleCount == 1 ? 'Aracın hazır.' : '$vehicleCount araç takipte.',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.items});

  final List<LegalItem> items;

  @override
  Widget build(BuildContext context) {
    final expired = items.where((i) => i.status.state == LegalState.expired).length;
    final color = expired > 0 ? AppColors.danger : AppColors.warning;
    final first = items.first;
    final summary = expired > 0
        ? '$expired yasal tarihin süresi doldu'
        : '${items.length} yasal tarih yaklaşıyor';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        key: const Key('legal_alert_banner'),
        color: color.withAlpha(26),
        borderColor: color.withAlpha(120),
        onTap: () => openVehicleDetail(context, first.vehicle.id!),
        child: Row(
          children: [
            Icon(Icons.notification_important_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${first.kind.label} · ${first.vehicle.displayName} · ${first.status.detailLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _VehicleSwitcher extends StatelessWidget {
  const _VehicleSwitcher({required this.vehicles, required this.selectedId});

  final List<Vehicle> vehicles;
  final int selectedId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.read(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: vehicles.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final v = vehicles[i];
            final isSelected = v.id == selectedId;
            return ChoiceChip(
              avatar: Icon(v.category.icon, size: 18, color: isSelected ? AppColors.orange : AppColors.textSecondary),
              label: Text(v.displayName),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) => app.selectVehicle(v.id!),
            );
          },
        ),
      ),
    );
  }
}

class _SelectedVehicleCard extends StatelessWidget {
  const _SelectedVehicleCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final km = app.lastMileage(vehicle.id!);
    final id = vehicle.id!;
    return FadeIn(
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => openVehicleDetail(context, id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VehicleHeroArt(vehicle: vehicle, height: 150),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dar ekranda kilometre başlığın altına iner (taşma olmaz).
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (vehicle.nickname != null) vehicle.fullTitle else vehicle.modelYear?.toString(),
                              vehicle.fuelType.label,
                              vehicle.engine,
                            ].whereType<String>().join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          if (vehicle.plate != null) ...[
                            const SizedBox(height: 10),
                            PlatePill(plate: vehicle.plate!),
                          ],
                        ],
                      );
                      final narrow = constraints.maxWidth < 420;
                      final kmBlock = Column(
                        crossAxisAlignment: narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Son kilometre',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            km == null ? '—' : Fmt.km(km),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      );
                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [titleBlock, const SizedBox(height: 12), kmBlock],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleBlock),
                          const SizedBox(width: 12),
                          kmBlock,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        key: const Key('quick_fuel'),
                        onPressed: () => openFuelForm(context, vehicleId: id),
                        icon: Icon(vehicle.fuelType.icon, size: 20),
                        label: Text(vehicle.fuelType == FuelType.electric ? 'Şarj ekle' : 'Yakıt ekle'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('quick_maintenance'),
                        onPressed: () => openServiceForm(context, vehicleId: id, kind: ServiceKind.maintenance),
                        icon: Icon(ServiceKind.maintenance.icon, size: 20),
                        label: const Text('Bakım ekle'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('quick_service'),
                        onPressed: () => openServiceForm(context, vehicleId: id, kind: ServiceKind.service),
                        icon: Icon(ServiceKind.service.icon, size: 20),
                        label: const Text('Servis ekle'),
                      ),
                      TextButton.icon(
                        key: const Key('open_vehicle_detail'),
                        onPressed: () => openVehicleDetail(context, id),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: const Text('Detaylar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
