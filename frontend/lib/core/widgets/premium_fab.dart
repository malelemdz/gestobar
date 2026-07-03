import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumFAB extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool isEnabled;

  const PremiumFAB({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: isEnabled ? onPressed : () {}, // Pass a dummy callback when disabled
      backgroundColor: isEnabled ? const Color(0xFF00F0FF) : Colors.grey.shade800,
      elevation: isEnabled ? 4 : 0,
      hoverElevation: isEnabled ? 8 : 0,
      focusElevation: isEnabled ? 4 : 0,
      highlightElevation: isEnabled ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tooltip: tooltip,
      icon: Icon(icon, color: isEnabled ? const Color(0xFF0C0E12) : Colors.white30, size: 20),
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: isEnabled ? const Color(0xFF0C0E12) : Colors.white30,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.2,
          height: 1.0,
        ),
      ),
    );
  }
}
