import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';

class ConfigTimePickerField extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const ConfigTimePickerField({
    super.key,
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.0,
            fontWeight: FontWeight.w600,
            color: AppTheme.liquidOnSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6.0),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppTheme.liquidSurfaceContainerLow,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.3), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: AppTheme.liquidPrimary),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
