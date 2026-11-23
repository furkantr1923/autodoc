import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/number_parse.dart';
import '../../core/utils/text_normalize.dart';
import '../../data/models/enums.dart';
import '../../data/models/fuel_record.dart';
import '../../data/models/vehicle.dart';
import '../../domain/fuel_math.dart';
import '../../domain/mileage.dart';
import '../../state/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';

class FuelFormPage extends StatefulWidget {
  const FuelFormPage({super.key, required this.vehicleId, this.record});

  final int vehicleId;
  final FuelRecord? record;

  @override
  State<FuelFormPage> createState() => _FuelFormPageState();
}

class _FuelFormPageState extends State<FuelFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mileage;
  late final TextEditingController _quantity;
  late final TextEditingController _unitPrice;
  late final TextEditingController _total;
  late final TextEditingController _station;
  late final TextEditingController _note;
  DateTime? _date;
  FuelType? _fuelType;
  bool _fullTank = false;
  bool _dirty = false;
  bool _saving = false;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _mileage = TextEditingController(text: r == null ? '' : '${r.mileage}');
    _quantity = TextEditingController(text: r == null ? '' : Fmt.editableDecimal(r.quantity));
    _unitPrice = TextEditingController(
      text: r?.unitPrice == null ? '' : Fmt.editableDecimal(r!.unitPrice!),
    );
    _total = TextEditingController(
      text: r?.totalCost == null ? '' : Fmt.editableDecimal(r!.totalCost!),
    );
    _station = TextEditingController(text: r?.station ?? '');
    _note = TextEditingController(text: r?.note ?? '');
    _date = r?.date;
    _fuelType = r?.fuelType;
    _fullTank = r?.fullTank ?? false;
  }

  @override
  void dispose() {
    for (final c in [_mileage, _quantity, _unitPrice, _total, _station, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  // Miktar × birim fiyat = toplam. Kullanıcı hangisini girerse diğeri hesaplanır.
  void _onQuantityChanged(String _) {
    final q = NumberParse.decimal(_quantity.text);
    if (q == null || q <= 0) return;
    final price = NumberParse.decimal(_unitPrice.text);
    final total = NumberParse.decimal(_total.text);
    if (price != null) {
      _total.text = Fmt.editableDecimal(FuelMath.total(q, price));
    } else if (total != null) {
      final up = FuelMath.unitPrice(total, q);
      if (up != null) _unitPrice.text = Fmt.editableDecimal(up);
    }
  }

  void _onUnitPriceChanged(String _) {
    final q = NumberParse.decimal(_quantity.text);
    final price = NumberParse.decimal(_unitPrice.text);
    if (q == null || q <= 0 || price == null) return;
    _total.text = Fmt.editableDecimal(FuelMath.total(q, price));
  }

  void _onTotalChanged(String _) {
    final q = NumberParse.decimal(_quantity.text);
    final total = NumberParse.decimal(_total.text);
    if (q == null || q <= 0 || total == null) return;
    final up = FuelMath.unitPrice(total, q);
    if (up != null) _unitPrice.text = Fmt.editableDecimal(up);
  }

  String? _optionalAmount(String? v, {double max = 1000000}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    final parsed = NumberParse.decimal(t);
    if (parsed == null) return 'Geçerli bir sayı girin.';
    if (parsed < 0) return 'Negatif olamaz.';
    if (parsed > max) return 'Değer çok büyük.';
    return null;
  }

  Future<void> _save(Vehicle vehicle, FuelType fuelType) async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      showAppSnack(context, 'Lütfen işaretli alanları düzeltin.', error: true);
      return;
    }
    final app = AppScope.read(context);
    final km = NumberParse.integer(_mileage.text)!;
    final date = _date!;
    final check = app.validateMileage(
      vehicleId: vehicle.id!,
      date: date,
      mileage: km,
      excludeFuelId: widget.record?.id,
    );
    if (!check.isValid) {
      showAppSnack(context, check.error!, error: true);
      return;
    }
    if (check.hasWarnings) {
      final proceed = await showMileageWarningDialog(context, check.warnings);
      if (!proceed || !mounted) return;
    }

    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    try {
      final now = DateTime.now();
      await app.saveFuel(FuelRecord(
        id: widget.record?.id,
        vehicleId: vehicle.id!,
        date: date,
        mileage: km,
        fuelType: fuelType,
        quantity: NumberParse.decimal(_quantity.text)!,
        unitPrice: NumberParse.decimal(_unitPrice.text),
        totalCost: NumberParse.decimal(_total.text),
        fullTank: _fullTank,
        station: emptyToNull(_station.text),
        note: emptyToNull(_note.text),
        createdAt: widget.record?.createdAt ?? now,
        updatedAt: now,
      ));
      if (!mounted) return;
      showAppSnack(context, _isEdit ? 'Yakıt kaydı güncellendi.' : 'Yakıt kaydı eklendi.');
      _dirty = false;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, 'Kayıt kaydedilemedi: $e', error: true);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Yakıt kaydını sil',
      message: 'Bu kayıt kalıcı olarak silinecek. Bu işlem geri alınamaz.',
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final app = AppScope.read(context);
    final navigator = Navigator.of(context);
    await app.deleteFuel(widget.record!.id!);
    if (!mounted) return;
    showAppSnack(context, 'Yakıt kaydı silindi.');
    _dirty = false;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final vehicle = app.vehicleById(widget.vehicleId);
    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Araç bulunamadı',
          message: 'Bu kayda ait araç silinmiş olabilir.',
        ),
      );
    }

    final options = <FuelType>{
      ...vehicle.fuelType.refuelOptions,
      if (widget.record != null) widget.record!.fuelType,
    }.toList();
    final fuelType = (_fuelType != null && options.contains(_fuelType)) ? _fuelType! : options.first;
    _date ??= app.today; // varsayılan: bugün (uygulama saatine göre)
    final unit = fuelType.unit;
    final last = lastKnownMileage(app.mileageHistory(vehicle.id!, excludeFuelId: widget.record?.id));
    final width = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await confirmDiscardChanges(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Yakıt kaydını düzenle' : 'Yeni yakıt kaydı'),
          actions: [
            if (_isEdit)
              IconButton(
                tooltip: 'Kaydı sil',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _saving ? null : _delete,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: FilledButton(
                key: const Key('fuel_save'),
                onPressed: _saving ? null : () => _save(vehicle, fuelType),
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: _markDirty,
          child: SingleChildScrollView(
            padding: pagePadding(width, maxWidth: 760, top: 8, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecordVehicleHeader(vehicle: vehicle),
                FormSection(
                  title: 'Alım bilgileri',
                  icon: fuelType.icon,
                  children: [
                    FieldPair(
                      first: DatePickerField(
                        key: const Key('fuel_date'),
                        label: 'Tarih',
                        initialValue: _date,
                        firstDate: DateTime(1950),
                        lastDate: app.today,
                        isRequired: true,
                        allowClear: false,
                        onChanged: (d) => _date = d,
                      ),
                      second: TextFormField(
                        key: const Key('fuel_mileage'),
                        controller: _mileage,
                        keyboardType: TextInputType.number,
                        inputFormatters: mileageInputFormatters,
                        decoration: InputDecoration(
                          labelText: 'Kilometre',
                          prefixIcon: const Icon(Icons.speed_rounded),
                          suffixText: 'km',
                          helperText: last == null ? 'Göstergedeki değeri girin' : 'Son bilinen: ${Fmt.km(last)}',
                        ),
                        validator: (v) => MileageValidator.validateText(v, parsed: NumberParse.integer(v ?? '')),
                      ),
                    ),
                    if (options.length > 1)
                      DropdownButtonFormField<FuelType>(
                        value: fuelType,
                        decoration: InputDecoration(
                          labelText: 'Yakıt türü',
                          prefixIcon: Icon(fuelType.icon),
                        ),
                        items: [
                          for (final f in options) DropdownMenuItem(value: f, child: Text(f.label)),
                        ],
                        onChanged: (v) => setState(() => _fuelType = v),
                      ),
                    TextFormField(
                      key: const Key('fuel_quantity'),
                      controller: _quantity,
                      keyboardType: decimalKeyboard,
                      inputFormatters: decimalInputFormatters,
                      onChanged: _onQuantityChanged,
                      decoration: InputDecoration(
                        labelText: 'Miktar',
                        prefixIcon: const Icon(Icons.water_drop_outlined),
                        suffixText: unit,
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Miktar girin.';
                        final q = NumberParse.decimal(t);
                        if (q == null) return 'Geçerli bir sayı girin (örn. 42,5).';
                        if (q <= 0) return 'Miktar sıfırdan büyük olmalı.';
                        if (q > 5000) return 'Miktar gerçekçi değil.';
                        return null;
                      },
                    ),
                    FieldPair(
                      first: TextFormField(
                        key: const Key('fuel_unit_price'),
                        controller: _unitPrice,
                        keyboardType: decimalKeyboard,
                        inputFormatters: decimalInputFormatters,
                        onChanged: _onUnitPriceChanged,
                        decoration: InputDecoration(
                          labelText: 'Birim fiyat',
                          prefixIcon: const Icon(Icons.sell_outlined),
                          suffixText: '₺/$unit',
                        ),
                        validator: (v) => _optionalAmount(v, max: 100000),
                      ),
                      second: TextFormField(
                        key: const Key('fuel_total'),
                        controller: _total,
                        keyboardType: decimalKeyboard,
                        inputFormatters: decimalInputFormatters,
                        onChanged: _onTotalChanged,
                        decoration: const InputDecoration(
                          labelText: 'Toplam tutar',
                          prefixIcon: Icon(Icons.payments_outlined),
                          suffixText: '₺',
                        ),
                        validator: (v) => _optionalAmount(v),
                      ),
                    ),
                    SwitchListTile(
                      value: _fullTank,
                      tileColor: AppColors.surfaceHigh,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      onChanged: (v) => setState(() {
                        _fullTank = v;
                        _dirty = true;
                      }),
                      title: Text(fuelType == FuelType.electric ? 'Tam şarj edildi' : 'Depo dolduruldu'),
                      secondary: const Icon(Icons.battery_full_rounded),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Ek bilgiler',
                  icon: Icons.notes_rounded,
                  children: [
                    TextFormField(
                      controller: _station,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: fuelType == FuelType.electric ? 'Şarj istasyonu (isteğe bağlı)' : 'İstasyon (isteğe bağlı)',
                        prefixIcon: const Icon(Icons.place_outlined),
                      ),
                    ),
                    TextFormField(
                      controller: _note,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Not (isteğe bağlı)',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kayıt formlarının üstünde, kaydın ait olduğu aracı gösterir.
class RecordVehicleHeader extends StatelessWidget {
  const RecordVehicleHeader({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        children: [
          Icon(vehicle.category.icon, color: AppColors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vehicle.plate == null ? vehicle.displayName : '${vehicle.displayName}  ·  ${vehicle.plate}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
