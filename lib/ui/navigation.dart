import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../data/models/enums.dart';
import '../data/models/fuel_record.dart';
import '../data/models/service_record.dart';
import '../data/models/vehicle.dart';
import 'records/fuel_form_page.dart';
import 'records/service_form_page.dart';
import 'vehicles/vehicle_detail_page.dart';
import 'vehicles/vehicle_form_page.dart';

Future<void> openVehicleForm(BuildContext context, {Vehicle? vehicle}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => VehicleFormPage(vehicle: vehicle)),
  );
}

Future<void> openVehicleDetail(BuildContext context, int vehicleId, {int tab = 0}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => VehicleDetailPage(vehicleId: vehicleId, initialTab: tab)),
  );
}

Future<void> openFuelForm(BuildContext context, {required int vehicleId, FuelRecord? record}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => FuelFormPage(vehicleId: vehicleId, record: record)),
  );
}

Future<void> openServiceForm(
  BuildContext context, {
  required int vehicleId,
  ServiceKind kind = ServiceKind.maintenance,
  ServiceRecord? record,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ServiceFormPage(vehicleId: vehicleId, initialKind: kind, record: record),
    ),
  );
}

/// Hızlı kayıt ekleme menüsü.
Future<void> showAddRecordSheet(BuildContext context, Vehicle vehicle) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${vehicle.displayName} için yeni kayıt',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            _SheetOption(
              key: const Key('sheet_fuel'),
              icon: vehicle.fuelType.icon,
              title: 'Yakıt kaydı',
              subtitle: 'Alım miktarı, tutar ve kilometre',
              onTap: () => Navigator.of(ctx).pop('fuel'),
            ),
            _SheetOption(
              key: const Key('sheet_maintenance'),
              icon: ServiceKind.maintenance.icon,
              title: 'Bakım kaydı',
              subtitle: 'Periyodik bakım, yağ ve filtre işlemleri',
              onTap: () => Navigator.of(ctx).pop('maintenance'),
            ),
            _SheetOption(
              key: const Key('sheet_service'),
              icon: ServiceKind.service.icon,
              title: 'Servis kaydı',
              subtitle: 'Onarım, arıza ve parça değişimi',
              onTap: () => Navigator.of(ctx).pop('service'),
            ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  final id = vehicle.id!;
  switch (choice) {
    case 'fuel':
      await openFuelForm(context, vehicleId: id);
    case 'maintenance':
      await openServiceForm(context, vehicleId: id, kind: ServiceKind.maintenance);
    case 'service':
      await openServiceForm(context, vehicleId: id, kind: ServiceKind.service);
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.orangeSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.orange),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
