import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/number_parse.dart';
import '../../core/utils/text_normalize.dart';
import '../../data/models/enums.dart';
import '../../data/models/service_record.dart';
import '../../data/models/vehicle.dart';
import '../../domain/mileage.dart';
import '../../state/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import 'fuel_form_page.dart' show RecordVehicleHeader;

/// Açıklama alanına hızlı ekleme için sık kullanılan işlem adları.
/// Bunlar öneri değil, yazma kolaylığıdır; seçilen metin açıklamaya eklenir.
const Map<ServiceKind, List<String>> _quickOperations = {
  ServiceKind.maintenance: [
    'Periyodik bakım',
    'Motor yağı değişimi',
    'Yağ filtresi',
    'Hava filtresi',
    'Polen filtresi',
    'Yakıt filtresi',
    'Antifriz',
    'Fren hidroliği',
    'Buji',
  ],
  ServiceKind.service: [
    'Fren balatası',
    'Fren diski',
    'Lastik değişimi',
    'Rot balans',
    'Akü değişimi',
    'Triger seti',
    'Debriyaj',
    'Amortisör',
    'Klima gazı',
    'Elektrik arızası',
  ],
};

class ServiceFormPage extends StatefulWidget {
  const ServiceFormPage({
    super.key,
    required this.vehicleId,
    this.initialKind = ServiceKind.maintenance,
    this.record,
  });

  final int vehicleId;
  final ServiceKind initialKind;
  final ServiceRecord? record;

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _mileage;
  late final TextEditingController _description;
  late final TextEditingController _workshop;
  late final TextEditingController _cost;
  late final TextEditingController _note;
  late ServiceKind _kind;
  DateTime? _date;
  bool _dirty = false;
  bool _saving = false;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _kind = r?.kind ?? widget.initialKind;
    _mileage = TextEditingController(text: r == null ? '' : '${r.mileage}');
    _description = TextEditingController(text: r?.description ?? '');
    _workshop = TextEditingController(text: r?.workshop ?? '');
    _cost = TextEditingController(text: r?.cost == null ? '' : Fmt.editableDecimal(r!.cost!));
    _note = TextEditingController(text: r?.note ?? '');
    _date = r?.date;
  }

  @override
  void dispose() {
    for (final c in [_mileage, _description, _workshop, _cost, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _appendOperation(String op) {
    final current = _description.text.trim();
    final next = current.isEmpty ? op : '$current, ${op[0].toLowerCase()}${op.substring(1)}';
    _description.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _markDirty();
  }

  Future<void> _save(Vehicle vehicle) async {
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
      excludeServiceId: widget.record?.id,
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
      await app.saveService(ServiceRecord(
        id: widget.record?.id,
        vehicleId: vehicle.id!,
        kind: _kind,
        date: date,
        mileage: km,
        description: _description.text.trim(),
        workshop: emptyToNull(_workshop.text),
        cost: NumberParse.decimal(_cost.text),
        note: emptyToNull(_note.text),
        createdAt: widget.record?.createdAt ?? now,
        updatedAt: now,
      ));
      if (!mounted) return;
      showAppSnack(context, _isEdit ? '${_kind.label} kaydı güncellendi.' : '${_kind.label} kaydı eklendi.');
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
      title: '${_kind.label} kaydını sil',
      message: 'Bu kayıt kalıcı olarak silinecek. Bu işlem geri alınamaz.',
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final app = AppScope.read(context);
    final navigator = Navigator.of(context);
    await app.deleteService(widget.record!.id!);
    if (!mounted) return;
    showAppSnack(context, 'Kayıt silindi.');
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
    final last = lastKnownMileage(app.mileageHistory(vehicle.id!, excludeServiceId: widget.record?.id));
    _date ??= app.today; // varsayılan: bugün (uygulama saatine göre)
    final width = MediaQuery.sizeOf(context).width;
    final title = _isEdit ? '${_kind.label} kaydını düzenle' : 'Yeni ${_kind.label.toLowerCase()} kaydı';

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await confirmDiscardChanges(context);
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
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
                key: const Key('service_save'),
                onPressed: _saving ? null : () => _save(vehicle),
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
                SegmentedButton<ServiceKind>(
                  showSelectedIcon: false,
                  segments: [
                    for (final k in ServiceKind.values)
                      ButtonSegment(value: k, label: Text(k.label), icon: Icon(k.icon)),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() {
                    _kind = s.first;
                    _dirty = true;
                  }),
                ),
                const SizedBox(height: 16),
                FormSection(
                  title: 'İşlem bilgileri',
                  icon: _kind.icon,
                  children: [
                    FieldPair(
                      first: DatePickerField(
                        key: const Key('service_date'),
                        label: 'İşlem tarihi',
                        initialValue: _date,
                        firstDate: DateTime(1950),
                        lastDate: app.today,
                        isRequired: true,
                        allowClear: false,
                        onChanged: (d) => _date = d,
                      ),
                      second: TextFormField(
                        key: const Key('service_mileage'),
                        controller: _mileage,
                        keyboardType: TextInputType.number,
                        inputFormatters: mileageInputFormatters,
                        decoration: InputDecoration(
                          labelText: 'İşlem kilometresi',
                          prefixIcon: const Icon(Icons.speed_rounded),
                          suffixText: 'km',
                          helperText: last == null ? 'Göstergedeki değeri girin' : 'Son bilinen: ${Fmt.km(last)}',
                        ),
                        validator: (v) => MileageValidator.validateText(v, parsed: NumberParse.integer(v ?? '')),
                      ),
                    ),
                    TextFormField(
                      key: const Key('service_description'),
                      controller: _description,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Yapılan işlem',
                        hintText: 'Örn. Motor yağı ve yağ filtresi değişimi',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Yapılan işlemi yazın.';
                        if (t.length < 3) return 'Açıklama çok kısa.';
                        return null;
                      },
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final op in _quickOperations[_kind]!)
                          ActionChip(
                            label: Text(op),
                            avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.orange),
                            onPressed: () => _appendOperation(op),
                          ),
                      ],
                    ),
                  ],
                ),
                FormSection(
                  title: 'Ek bilgiler',
                  icon: Icons.notes_rounded,
                  children: [
                    FieldPair(
                      first: TextFormField(
                        controller: _workshop,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Servis / usta (isteğe bağlı)',
                          prefixIcon: Icon(Icons.store_mall_directory_outlined),
                        ),
                      ),
                      second: TextFormField(
                        controller: _cost,
                        keyboardType: decimalKeyboard,
                        inputFormatters: decimalInputFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Tutar (isteğe bağlı)',
                          prefixIcon: Icon(Icons.payments_outlined),
                          suffixText: '₺',
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null;
                          final parsed = NumberParse.decimal(t);
                          if (parsed == null) return 'Geçerli bir tutar girin.';
                          if (parsed > 10000000) return 'Tutar çok büyük.';
                          return null;
                        },
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
