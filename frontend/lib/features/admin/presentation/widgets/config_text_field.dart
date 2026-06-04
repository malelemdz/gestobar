import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';

class ConfigTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final IconData? prefixIcon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const ConfigTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: theme.textTheme.bodyMedium,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppTheme.liquidPrimary) : null,
            suffixText: suffixText,
            suffixStyle: TextStyle(color: AppTheme.liquidPrimary, fontWeight: FontWeight.bold),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.colorDanger, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24.0),
              borderSide: BorderSide(color: AppTheme.colorDanger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
