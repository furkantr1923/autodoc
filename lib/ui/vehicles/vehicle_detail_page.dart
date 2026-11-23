import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/enums.dart';
import '../../data/models/vehicle.dart';
import '../../domain/mileage.dart';
import '../../state/app_scope.dart';
import '../navigation.dart';
import '../records/record_tiles.dart';
import '../widgets/common.dart';
import '../widgets/legal_widgets.dart';
import '../widgets/vehicle_visuals.dart';

class VehicleDetailPage extends StatelessWidget {
  const VehicleDetailPage({super.key, required this.vehicleId, this.initialTab = 0});

  final int vehicleId;
  final int initialTab;

  Future<void> _delete(BuildContext context, Vehicle vehicle) async {
    final recordCount = AppScope.read(context).recordsFor(vehicle.id!).length;
    final ok = await showConfirmDialog(
      context,
      title: 'Aracı sil',
      message: '${vehicle.displayName} ve ona ait $recordCount yakıt/bakım/servis kaydı kalıcı olarak '
          'silinecek. Bu işlem geri alınamaz.',
      confirmLabel: 'Aracı sil',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final app = AppScope.read(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await app.deleteVehicle(vehicle.id!);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('${vehicle.displayName} silindi.')));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final vehicle = app.vehicleById(vehicleId);
    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Araç bulunamadı',
          message: 'Bu araç silinmiş olabilir.',
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      initialIndex: initialTab < 0 ? 0 : (initialTab > 3 ? 3 : initialTab),
      child: Scaffold(
        appBar: AppBar(
          title: Text(vehicle.displayName),
          actions: [
            IconButton(
              key: const Key('vehicle_edit'),
              tooltip: 'Düzenle',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => openVehicleForm(context, vehicle: vehicle),
            ),
            PopupMenuButton<String>(
              key: const Key('vehicle_menu'),
              tooltip: 'Diğer işlemler',
              color: AppColors.surfaceHigh,
              onSelected: (value) {
                if (value == 'delete') _delete(context, vehicle);
                if (value == 'select') app.selectVehicle(vehicle.id!);
              },
              itemBuilder: (context) => [
                if (app.selectedVehicle?.id != vehicle.id)
                  const PopupMenuItem(
                    value: 'select',
                    child: ListTile(
                      leading: Icon(Icons.push_pin_outlined),
                      title: Text('Panelde göster'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  key: Key('vehicle_delete'),
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    title: Text('Aracı sil', style: TextStyle(color: AppColors.danger)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.orange,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: AppColors.outlineSoft,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Genel'),
              Tab(text: 'Yakıt'),
              Tab(text: 'Bakım & Servis'),
              Tab(text: 'Kilometre'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('detail_add_record'),
          heroTag: 'detail_add_record',
          onPressed: () => showAddRecordSheet(context, vehicle),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Kayıt Ekle'),
        ),
        body: TabBarView(
          children: [
            _GeneralTab(vehicle: vehicle),
            _FuelTab(vehicle: vehicle),
            _ServiceTab(vehicle: vehicle),
            _MileageTab(vehicle: vehicle),
          ],
        ),
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final km = app.lastMileage(vehicle.id!);
    final width = MediaQuery.sizeOf(context).width;
    final insurance = app.legalStatus(vehicle, LegalKind.insurance);
    final inspection = app.legalStatus(vehicle, LegalKind.inspection);
    final edit = () => openVehicleForm(context, vehicle: vehicle);

    return ListView(
      padding: pagePadding(width, maxWidth: 980, top: 16, bottom: 100),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Stack(
            children: [
              VehicleHeroArt(vehicle: vehicle, height: 170),
              Positioned(
                left: 20,
                right: 20,
                top: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.fullTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    if (vehicle.plate != null) PlatePill(plate: vehicle.plate!),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Son kilometre', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      km == null ? '—' : Fmt.km(km),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.orange),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Yasal tarihler', icon: Icons.event_available_rounded),
        _ResponsivePair(
          first: LegalCard(kind: LegalKind.insurance, status: insurance, onTap: edit),
          second: LegalCard(kind: LegalKind.inspection, status: inspection, onTap: edit),
        ),
        const SectionHeader(title: 'Araç bilgileri', icon: Icons.info_outline_rounded),
        AppCard(
          child: Column(
            children: [
              InfoRow(label: 'Kategori', value: vehicle.category.label, icon: vehicle.category.icon),
              InfoRow(label: 'Marka', value: vehicle.make, icon: Icons.local_offer_outlined),
              InfoRow(label: 'Model', value: vehicle.model, icon: Icons.badge_outlined),
              InfoRow(
                label: 'Model yılı',
                value: vehicle.modelYear?.toString() ?? '—',
                icon: Icons.calendar_today_rounded,
              ),
              InfoRow(label: 'Plaka', value: vehicle.plate ?? '—', icon: Icons.pin_outlined),
              InfoRow(label: 'Yakıt türü', value: vehicle.fuelType.label, icon: vehicle.fuelType.icon),
              InfoRow(
                label: 'Motor',
                value: vehicle.engine ?? '—',
                icon: Icons.precision_manufacturing_outlined,
              ),
              InfoRow(label: 'VIN / şasi no', value: vehicle.vin ?? '—', icon: Icons.qr_code_2_rounded),
              if (vehicle.nickname != null)
                InfoRow(label: 'Takma ad', value: vehicle.nickname!, icon: Icons.label_outline_rounded),
              InfoRow(label: 'Renk', value: vehicle.color ?? '—', icon: Icons.palette_outlined),
              InfoRow(
                label: 'Başlangıç km',
                value: vehicle.initialMileage == null ? '—' : Fmt.km(vehicle.initialMileage!),
                icon: Icons.flag_outlined,
              ),
              InfoRow(
                label: 'Kayıt tarihi',
                value: Fmt.date(vehicle.createdAt),
                icon: Icons.history_rounded,
              ),
            ],
          ),
        ),
        if (vehicle.notes != null) ...[
          const SectionHeader(title: 'Notlar', icon: Icons.notes_rounded),
          AppCard(child: SelectableText(vehicle.notes!, style: const TextStyle(height: 1.5))),
        ],
      ],
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(children: [first, const SizedBox(height: 12), second]);
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          ),
        );
      },
    );
  }
}

class _FuelTab extends StatelessWidget {
  const _FuelTab({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final records = app.fuelFor(vehicle.id!);
    if (records.isEmpty) {
      return EmptyState(
        icon: Icons.local_gas_station_outlined,
        title: 'Yakıt kaydı yok',
        message: 'Yakıt aldığında miktarı, tutarı ve kilometreyi kaydet; geçmişin burada listelenir.',
        actionLabel: 'Yakıt kaydı ekle',
        onAction: () => openFuelForm(context, vehicleId: vehicle.id!),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    return ListView(
      padding: pagePadding(width, maxWidth: 900, top: 16, bottom: 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${records.length} yakıt kaydı · yeniden eskiye',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        for (final r in records) FuelTile(record: r),
      ],
    );
  }
}

class _ServiceTab extends StatefulWidget {
  const _ServiceTab({required this.vehicle});

  final Vehicle vehicle;

  @override
  State<_ServiceTab> createState() => _ServiceTabState();
}

class _ServiceTabState extends State<_ServiceTab> {
  ServiceKind? _filter;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final id = widget.vehicle.id!;
    final all = app.servicesFor(id);
    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.build_circle_outlined,
        title: 'Bakım veya servis kaydı yok',
        message: 'Yapılan her işlemi tarihi ve kilometresiyle kaydet; aracın servis geçmişi oluşsun.',
        actionLabel: 'Bakım kaydı ekle',
        onAction: () => openServiceForm(context, vehicleId: id),
      );
    }
    final records = _filter == null ? all : app.servicesFor(id, kind: _filter);
    final width = MediaQuery.sizeOf(context).width;
    return ListView(
      padding: pagePadding(width, maxWidth: 900, top: 16, bottom: 100),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'all', label: Text('Tümü')),
              ButtonSegment(value: 'maintenance', label: Text('Bakım')),
              ButtonSegment(value: 'service', label: Text('Servis')),
            ],
            selected: {_filter?.name ?? 'all'},
            onSelectionChanged: (s) => setState(() {
              final v = s.first;
              _filter = v == 'all' ? null : ServiceKind.fromDb(v);
            }),
          ),
        ),
        const SizedBox(height: 16),
        if (records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Bu türde kayıt yok.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        for (final r in records) ServiceTile(record: r),
      ],
    );
  }
}

class _MileageTab extends StatelessWidget {
  const _MileageTab({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final history = app.mileageHistory(vehicle.id!);
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.speed_rounded,
        title: 'Kilometre geçmişi yok',
        message: 'Kilometre değerleri yakıt, bakım ve servis kayıtlarından oluşur. '
            'İlk kaydı eklediğinde geçmiş burada görünür.',
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    // Görünüm yeniden eskiye; farklar kronolojik sıraya göre hesaplanır.
    final rows = <_MileageRowData>[];
    for (var i = 0; i < history.length; i++) {
      final diff = i == 0 ? null : history[i].mileage - history[i - 1].mileage;
      rows.add(_MileageRowData(history[i], diff));
    }
    final decreases = rows.where((r) => (r.diff ?? 0) < 0).length;

    return ListView(
      padding: pagePadding(width, maxWidth: 900, top: 16, bottom: 100),
      children: [
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  decreases == 0
                      ? 'Kilometre değerleri yalnızca senin girdiğin kayıtlardan oluşur; otomatik tahmin yapılmaz.'
                      : '$decreases kayıtta bir önceki kayda göre kilometre düşüşü var. Değerleri kontrol etmen önerilir.',
                  style: TextStyle(
                    color: decreases == 0 ? AppColors.textSecondary : AppColors.warning,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final row in rows.reversed) _MileageRow(data: row),
      ],
    );
  }
}

class _MileageRowData {
  const _MileageRowData(this.entry, this.diff);

  final MileageEntry entry;
  final int? diff;
}

class _MileageRow extends StatelessWidget {
  const _MileageRow({required this.data});

  final _MileageRowData data;

  @override
  Widget build(BuildContext context) {
    final e = data.entry;
    final diff = data.diff;
    final decreased = diff != null && diff < 0;
    final icon = switch (e.origin) {
      MileageOrigin.registration => Icons.flag_rounded,
      MileageOrigin.fuel => Icons.local_gas_station_rounded,
      MileageOrigin.maintenance => ServiceKind.maintenance.icon,
      MileageOrigin.service => ServiceKind.service.icon,
    };
    final isToday = Dates.isSameDay(e.date, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: decreased ? const Color(0x99FFB020) : AppColors.outlineSoft),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: decreased ? AppColors.warning : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fmt.km(e.mileage), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    '${isToday ? 'Bugün' : Fmt.date(e.date)} · ${e.origin.label} · ${e.source.label}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            if (diff != null)
              Text(
                decreased ? '${Fmt.signedKm(diff)} düşüş' : Fmt.signedKm(diff),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: decreased ? AppColors.warning : AppColors.success,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
