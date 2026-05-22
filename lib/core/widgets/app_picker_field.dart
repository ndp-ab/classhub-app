import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A read-only field that opens an external picker (date, time, modal,
/// bottom sheet, …) when tapped.
///
/// Visually matches [TextFormField] under the app's [InputDecorationTheme],
/// but renders the current selection as a [String] passed by the caller —
/// state lives in the caller, not in a [TextEditingController].
///
/// Typical usage:
/// ```dart
/// AppPickerField(
///   label: 'Hạn đóng',
///   value: _deadline == null ? null : formatDate(_deadline),
///   placeholder: 'Chưa chọn',
///   suffixIcon: const Icon(Icons.calendar_today_outlined),
///   onTap: _pickDeadline,
/// )
/// ```
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.onTap,
    this.label,
    this.value,
    this.placeholder,
    this.suffixIcon,
    this.prefixIcon,
    this.errorText,
    this.enabled = true,
  });

  final VoidCallback onTap;
  final String? label;

  /// Selected value rendered in the field. When null, [placeholder] shows.
  final String? value;

  /// Hint-style text shown when [value] is null.
  final String? placeholder;

  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;
    final Color textColor =
        hasValue ? AppColors.textPrimary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(
            label!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
        ],
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: InputDecorator(
            isEmpty: !hasValue,
            decoration: InputDecoration(
              hintText: placeholder,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              errorText: errorText,
              enabled: enabled,
            ),
            child: Text(
              hasValue ? value! : '',
              style: AppTextStyles.body.copyWith(color: textColor),
            ),
          ),
        ),
      ],
    );
  }
}
