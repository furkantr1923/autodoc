import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/number_parse.dart';
import '../../core/utils/text_normalize.dart';
import '../../data/models/enums.dart';
import '../../data/models/vehicle.dart';
import '../../domain/mileage.dart';
import '../../domain/vin_decoder.dart';
import '../../state/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/vehicle_visuals.dart';

/// Marka alanında otomatik tamamlama için yaygın markalar.
const List<String> kCommonMakes = [
  'Alfa Romeo', 'Audi', 'BMW', 'BYD', 'Chery', 'Chevrolet', 'Citroën', 'Cupra', 'Dacia',
  'DS Automobiles', 'Ducati', 'Fiat', 'Ford', 'Harley-Davidson', 'Honda', 'Hyundai', 'Isuzu',
  'Iveco', 'Jaguar', 'Jeep', 'Kawasaki', 'Kia', 'KTM', 'Land Rover', 'Lexus', 'MAN', 'Mazda',
  'Mercedes-Benz', 'MG', 'MINI', 'Mitsubishi', 'Nissan', 'Opel', 'Otokar', 'Peugeot', 'Porsche',
  'Renault', 'Scania', 'SEAT', 'Škoda', 'Subaru', 'Suzuki', 'Tesla', 'TOGG', 'Toyota', 'Volkswagen',
  'Volvo', 'Yamaha', 'Temsa', 'BMC', 'Türk Traktör', 'New Holland', 'Massey Ferguson', 'John Deere',
];

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key, this.vehicle});

  final Vehicle? vehicle;

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _makeFocus = FocusNode();
  late final TextEditingController _make;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _plate;
  late final TextEditingController _engine;
  late final TextEditingController _vin;
  late final TextEditingController _nickname;
  late final TextEditingController _color;
  late final TextEditingController _mileage;
  late final TextEditingController _notes;
  late VehicleCategory _category;
  late FuelType _fuelType;
  DateTime? _insurance;
  DateTime? _inspection;
  String? _newPhotoPath;
  bool _removePhoto = false;
  bool _dirty = false;
  bool _saving = false;

  bool get _isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _make = TextEditingController(text: v?.make ?? '');
    _model = TextEditingController(text: v?.model ?? '');
    _year = TextEditingController(text: v?.modelYear?.toString() ?? '');
    _plate = TextEditingController(text: v?.plate ?? '');
    _engine = TextEditingController(text: v?.engine ?? '');
    _vin = TextEditingController(text: v?.vin ?? '');
    _nickname = TextEditingController(text: v?.nickname ?? '');
    _color = TextEditingController(text: v?.color ?? '');
    _mileage = TextEditingController(text: v?.initialMileage?.toString() ?? '');
    _notes = TextEditingController(text: v?.notes ?? '');
    _category = v?.category ?? VehicleCategory.car;
    _fuelType = v?.fuelType ?? FuelType.gasoline;
    _insurance = v?.insuranceExpiry;
    _inspection = v?.inspectionDate;
  }

  @override
  void dispose() {
    for (final c in [_make, _model, _year, _plate, _engine, _vin, _nickname, _color, _mileage, _notes]) {
      c.dispose();
    }
    _makeFocus.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _newPhotoPath = file.path;
        _removePhoto = false;
        _dirty = true;
      });
    } catch (_) {
      if (mounted) showAppSnack(context, 'Fotoğraf seçilemedi.', error: true);
    }
  }

  void _clearPhoto() {
    setState(() {
      _newPhotoPath = null;
      _removePhoto = widget.vehicle?.photoPath != null;
      _dirty = true;
    });
  }

  Future<void> _decodeVin() async {
    final info = VinDecoder.decode(_vin.text);
    if (!info.isValidFormat) {
      showAppSnack(context, info.formatError ?? 'VIN çözümlenemedi.', error: true);
      return;
    }
    final apply = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.orange, size: 32),
        title: const Text('VIN çözümleme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.vin, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _DialogLine(label: 'Üretici', value: info.manufacturer ?? 'Tanımlanamadı'),
            _DialogLine(label: 'Bölge', value: info.region ?? 'Tanımlanamadı'),
            _DialogLine(
              label: 'Model yılı',
              value: info.modelYear?.toString() ?? 'Bu bölge için VIN\'den güvenilir şekilde okunamaz',
            ),
            if (info.checkDigitValid == false)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Kontrol hanesi tutmuyor; numarayı yeniden kontrol edin.',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Çözümleme internetsiz, yerleşik üretici tablosuyla yapılır. Bilgileri kontrol edin.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Kapat')),
          if (info.manufacturer != null || info.modelYear != null)
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Bilgileri uygula')),
        ],
      ),
    );
    if (apply != true || !mounted) return;
    setState(() {
      if (info.manufacturer != null && _make.text.trim().isEmpty) _make.text = info.manufacturer!;
      if (info.modelYear != null) _year.text = '${info.modelYear}';
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      showAppSnack(context, 'Lütfen işaretli alanları düzeltin.', error: true);
      return;
    }
    setState(() => _saving = true);
    final app = AppScope.read(context);
    final navigator = Navigator.of(context);
    final now = DateTime.now();
    final plate = emptyToNull(_plate.text);
    final vin = emptyToNull(_vin.text);
    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      category: _category,
      make: _make.text.trim(),
      model: _model.text.trim(),
      modelYear: NumberParse.integer(_year.text),
      plate: plate == null ? null : normalizePlate(plate),
      fuelType: _fuelType,
      engine: emptyToNull(_engine.text),
      vin: vin == null ? null : VinDecoder.normalize(vin),
      nickname: emptyToNull(_nickname.text),
      color: emptyToNull(_color.text),
      initialMileage: NumberParse.integer(_mileage.text),
      insuranceExpiry: _insurance,
      inspectionDate: _inspection,
      photoPath: widget.vehicle?.photoPath,
      notes: emptyToNull(_notes.text),
      createdAt: widget.vehicle?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await app.saveVehicle(vehicle, newPhotoSourcePath: _newPhotoPath, removePhoto: _removePhoto);
      if (!mounted) return;
      showAppSnack(context, _isEdit ? 'Araç bilgileri güncellendi.' : '${vehicle.displayName} eklendi.');
      _dirty = false;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, 'Araç kaydedilemedi: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final currentYear = app.today.year;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await confirmDiscardChanges(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Aracı düzenle' : 'Yeni araç'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                key: const Key('vehicle_save'),
                onPressed: _saving ? null : _save,
                child: const Text('Kaydet'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          onChanged: _markDirty,
          child: SingleChildScrollView(
            padding: pagePadding(width, maxWidth: 820, top: 8, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSection(
                  title: 'Araç türü',
                  icon: Icons.category_rounded,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in VehicleCategory.values)
                          ChoiceChip(
                            avatar: Icon(c.icon, size: 18, color: c == _category ? AppColors.orange : AppColors.textSecondary),
                            label: Text(c.label),
                            selected: c == _category,
                            showCheckmark: false,
                            onSelected: (_) => setState(() {
                              _category = c;
                              _dirty = true;
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
                FormSection(
                  title: 'Temel bilgiler',
                  icon: Icons.directions_car_rounded,
                  children: [
                    FieldPair(
                      first: _MakeField(
                        controller: _make,
                        focusNode: _makeFocus,
                      ),
                      second: TextFormField(
                        key: const Key('vehicle_model'),
                        controller: _model,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'Örn. 2008, Corolla, MT-07',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Model girin.' : null,
                      ),
                    ),
                    FieldPair(
                      first: TextFormField(
                        key: const Key('vehicle_year'),
                        controller: _year,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        decoration: const InputDecoration(
                          labelText: 'Model yılı',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null;
                          final y = int.tryParse(t);
                          if (y == null || y < 1900 || y > currentYear + 1) {
                            return '1900–${currentYear + 1} arasında olmalı.';
                          }
                          return null;
                        },
                      ),
                      second: TextFormField(
                        key: const Key('vehicle_plate'),
                        controller: _plate,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(15)],
                        decoration: const InputDecoration(
                          labelText: 'Plaka',
                          hintText: 'Örn. 34 ABC 123',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null;
                          final normalized = normalizePlate(t);
                          if (!RegExp(r'^[A-Z0-9ÇĞİÖŞÜ][A-Z0-9ÇĞİÖŞÜ \-]{1,14}$').hasMatch(normalized)) {
                            return 'Plaka harf, rakam, boşluk ve tire içerebilir.';
                          }
                          if (app.isPlateTaken(normalized, excludeId: widget.vehicle?.id)) {
                            return 'Bu plaka başka bir araçta kayıtlı.';
                          }
                          return null;
                        },
                      ),
                    ),
                    FieldPair(
                      first: DropdownButtonFormField<FuelType>(
                        key: const Key('vehicle_fuel'),
                        value: _fuelType,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Yakıt türü',
                          prefixIcon: Icon(_fuelType.icon),
                        ),
                        items: [
                          for (final f in FuelType.values) DropdownMenuItem(value: f, child: Text(f.label)),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _fuelType = v);
                        },
                      ),
                      second: TextFormField(
                        key: const Key('vehicle_mileage'),
                        controller: _mileage,
                        keyboardType: TextInputType.number,
                        inputFormatters: mileageInputFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Mevcut kilometre',
                          prefixIcon: Icon(Icons.speed_rounded),
                          suffixText: 'km',
                          helperText: 'İsteğe bağlı başlangıç değeri',
                        ),
                        validator: (v) => MileageValidator.validateText(
                          v,
                          parsed: NumberParse.integer(v ?? ''),
                          isRequired: false,
                        ),
                      ),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Teknik bilgiler',
                  icon: Icons.settings_suggest_rounded,
                  children: [
                    TextFormField(
                      controller: _engine,
                      decoration: const InputDecoration(
                        labelText: 'Motor bilgisi (isteğe bağlı)',
                        hintText: 'Örn. 1.6 HDi 120 HP, manuel',
                        prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                      ),
                    ),
                    TextFormField(
                      key: const Key('vehicle_vin'),
                      controller: _vin,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [LengthLimitingTextInputFormatter(20)],
                      decoration: InputDecoration(
                        labelText: 'VIN / şasi numarası (isteğe bağlı)',
                        prefixIcon: const Icon(Icons.qr_code_2_rounded),
                        suffixIcon: IconButton(
                          tooltip: 'VIN\'i çözümle',
                          icon: const Icon(Icons.manage_search_rounded),
                          onPressed: _decodeVin,
                        ),
                      ),
                      validator: VinDecoder.validateField,
                    ),
                    FieldPair(
                      first: TextFormField(
                        controller: _nickname,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Takma ad (isteğe bağlı)',
                          hintText: 'Örn. Aile aracı',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                      ),
                      second: TextFormField(
                        controller: _color,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Renk (isteğe bağlı)',
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Yasal tarihler',
                  icon: Icons.event_available_rounded,
                  children: [
                    FieldPair(
                      first: DatePickerField(
                        key: const Key('vehicle_insurance'),
                        label: 'Sigorta bitiş tarihi',
                        icon: LegalKind.insurance.icon,
                        initialValue: _insurance,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(currentYear + 15, 12, 31),
                        onChanged: (d) => _insurance = d,
                      ),
                      second: DatePickerField(
                        key: const Key('vehicle_inspection'),
                        label: 'Muayene bitiş tarihi',
                        icon: LegalKind.inspection.icon,
                        initialValue: _inspection,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(currentYear + 15, 12, 31),
                        onChanged: (d) => _inspection = d,
                      ),
                    ),
                    const Text(
                      'Tarih yaklaştığında veya geçtiğinde panelde uyarı gösterilir. Bildirim gönderilmez.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Fotoğraf ve notlar',
                  icon: Icons.photo_library_outlined,
                  children: [
                    _PhotoPicker(
                      vehicle: widget.vehicle,
                      category: _category,
                      newPhotoPath: _newPhotoPath,
                      removed: _removePhoto,
                      onPick: _pickPhoto,
                      onClear: _clearPhoto,
                    ),
                    TextFormField(
                      controller: _notes,
                      minLines: 2,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Notlar (isteğe bağlı)',
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

  class _MakeField extends StatelessWidget {
    const _MakeField({required this.controller, required this.focusNode});

    final TextEditingController controller;
    final FocusNode focusNode;

    @override
    Widget build(BuildContext context) {
      return RawAutocomplete<String>(
        textEditingController: controller,
        focusNode: focusNode,
        optionsBuilder: (value) {
          final q = foldForSearch(value.text.trim());
          if (q.isEmpty) return const Iterable<String>.empty();
          return kCommonMakes.where((m) => foldForSearch(m).startsWith(q) && m != value.text).take(8);
        },
        fieldViewBuilder: (context, textController, node, onFieldSubmitted) => TextFormField(
          key: const Key('vehicle_make'),
          controller: textController,
          focusNode: node,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Marka',
            hintText: 'Örn. Peugeot',
            prefixIcon: Icon(Icons.local_offer_outlined),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Marka girin.' : null,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surfaceHighest,
            elevation: 8,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 340),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    ListTile(
                      dense: true,
                      title: Text(option),
                      onTap: () => onSelected(option),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.vehicle,
    required this.category,
    required this.newPhotoPath,
    required this.removed,
    required this.onPick,
    required this.onClear,
  });

  final Vehicle? vehicle;
  final VehicleCategory category;
  final String? newPhotoPath;
  final bool removed;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final existing = removed ? null : vehicle?.photoPath;
    final hasPhoto = newPhotoPath != null || existing != null;
    Widget preview;
    if (newPhotoPath != null) {
      preview = Image.file(File(newPhotoPath!), width: 96, height: 96, fit: BoxFit.cover);
    } else if (existing != null) {
      preview = VehicleAvatar(vehicle: vehicle!, size: 96);
    } else {
      preview = Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outline),
        ),
        child: Icon(category.icon, color: AppColors.orange, size: 42),
      );
    }
    return Row(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(24), child: preview),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Araç fotoğrafı yalnızca bu cihazda saklanır. Fotoğraf eklenmezse araç türüne uygun simge gösterilir.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(hasPhoto ? 'Değiştir' : 'Fotoğraf seç'),
                  ),
                  if (hasPhoto)
                    TextButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Kaldır'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogLine extends StatelessWidget {
  const _DialogLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: AppColors.textSecondary)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
