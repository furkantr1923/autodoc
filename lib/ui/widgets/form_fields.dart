import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

/// Takvimden tarih seçtiren form alanı.
class DatePickerField extends FormField<DateTime> {
  DatePickerField({
    super.key,
    required String label,
    super.initialValue,
    required DateTime firstDate,
    required DateTime lastDate,
    bool isRequired = false,
    bool allowClear = true,
    String? helperText,
    IconData icon = Icons.event_rounded,
    ValueChanged<DateTime?>? onChanged,
  }) : super(
          validator: (value) {
            if (isRequired && value == null) return '$label seçin.';
            if (value != null && value.isAfter(lastDate)) return 'Bu tarih seçilemez.';
            return null;
          },
          builder: (field) {
            Future<void> pick() async {
              var initial = field.value ?? DateTime.now();
              if (initial.isBefore(firstDate)) initial = firstDate;
              if (initial.isAfter(lastDate)) initial = lastDate;
              final picked = await showDatePicker(
                context: field.context,
                initialDate: initial,
                firstDate: firstDate,
                lastDate: lastDate,
                helpText: label,
                cancelText: 'Vazgeç',
                confirmText: 'Seç',
              );
              if (picked == null || !field.mounted) return;
              field.didChange(picked);
              onChanged?.call(picked);
            }

            final value = field.value;
            return InkWell(
              onTap: pick,
              borderRadius: BorderRadius.circular(AppRadius.field),
              child: InputDecorator(
                isEmpty: value == null,
                decoration: InputDecoration(
                  labelText: label,
                  helperText: helperText,
                  errorText: field.errorText,
                  prefixIcon: Icon(icon),
                  suffixIcon: allowClear && value != null
                      ? IconButton(
                          tooltip: 'Tarihi temizle',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            field.didChange(null);
                            onChanged?.call(null);
                          },
                        )
                      : const Icon(Icons.calendar_month_rounded),
                ),
                child: Text(
                  value == null ? '' : Fmt.date(value),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        );
}

/// Ondalıklı sayı girişi (virgül veya nokta).
final List<TextInputFormatter> decimalInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  LengthLimitingTextInputFormatter(12),
];

/// Kilometre girişi (rakam ve binlik ayırıcı nokta).
final List<TextInputFormatter> mileageInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  LengthLimitingTextInputFormatter(10),
];

const TextInputType decimalKeyboard = TextInputType.numberWithOptions(decimal: true);

/// Form bölümü kartı.
class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// İki alanı geniş ekranda yan yana, dar ekranda alt alta gösterir.
class FieldPair extends StatelessWidget {
  const FieldPair({super.key, required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 14), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

/// Kilometre düşüşü gibi şüpheli durumlarda kullanıcıdan onay ister.
Future<bool> showMileageWarningDialog(BuildContext context, List<String> warnings) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 32),
      title: const Text('Kilometre uyarısı'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final w in warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.speed_rounded, size: 16, color: AppColors.warning),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              'Değeri kontrol et. Gösterge değişimi gibi geçerli bir nedeni varsa yine de kaydedebilirsin.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('mileage_fix'),
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Düzelt'),
        ),
        FilledButton(
          key: const Key('mileage_save_anyway'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Yine de kaydet'),
        ),
      ],
    ),
  );
  return result ?? false;
}
