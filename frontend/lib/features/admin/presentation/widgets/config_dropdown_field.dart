import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';

class ConfigDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;

  const ConfigDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppTheme.liquidOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6.0),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: theme.textTheme.bodyMedium,
          icon: Icon(Icons.expand_more, color: AppTheme.liquidOnSurfaceVariant),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.liquidSurfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.liquidOutline.withOpacity(0.3), width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.liquidPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
