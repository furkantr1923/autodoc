import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../state/app_scope.dart';
import '../records/record_tiles.dart';
import '../vehicles/vehicles_page.dart';
import '../widgets/common.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final padding = pagePadding(width, maxWidth: 900, top: 4, bottom: 32);
    final results = app.search(_query);
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Ara')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding.left, 4, padding.right, 8),
            child: TextField(
              key: const Key('search_field'),
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Araç, plaka, kategori veya açıklama ara',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: hasQuery
                    ? IconButton(
                        tooltip: 'Temizle',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: !hasQuery
                ? const EmptyState(
                    icon: Icons.manage_search_rounded,
                    title: 'Kayıtlarında ara',
                    message: 'Marka, model, plaka, araç kategorisi (örn. "motosiklet"), bakım açıklaması '
                        '(örn. "yağ değişimi") veya istasyon adıyla arayabilirsin. Türkçe karakter farkı gözetilmez.',
                    compact: true,
                  )
                : results.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Sonuç bulunamadı',
                        message: '"${_query.trim()}" ile eşleşen araç veya kayıt yok.',
                        compact: true,
                      )
                    : ListView(
                        padding: padding,
                        children: [
                          Text(
                            '${results.total} sonuç',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          if (results.vehicles.isNotEmpty) ...[
                            SectionHeader(
                              title: 'Araçlar (${results.vehicles.length})',
                              icon: Icons.directions_car_rounded,
                            ),
                            for (final v in results.vehicles)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: VehicleCard(vehicle: v),
                              ),
                          ],
                          if (results.services.isNotEmpty) ...[
                            SectionHeader(
                              title: 'Bakım ve servis (${results.services.length})',
                              icon: Icons.build_circle_rounded,
                            ),
                            for (final r in results.services)
                              ServiceTile(
                                record: r,
                                vehicleName: app.vehicleById(r.vehicleId)?.displayName,
                              ),
                          ],
                          if (results.fuels.isNotEmpty) ...[
                            SectionHeader(
                              title: 'Yakıt (${results.fuels.length})',
                              icon: Icons.local_gas_station_rounded,
                            ),
                            for (final r in results.fuels)
                              FuelTile(
                                record: r,
                                vehicleName: app.vehicleById(r.vehicleId)?.displayName,
                              ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
