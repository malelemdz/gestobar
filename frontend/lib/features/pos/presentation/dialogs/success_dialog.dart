import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/responsive_modal.dart';

Future<void> showSuccessDialog(BuildContext context) async {
  await showResponsiveDialog(
    context: context,
    maxWidth: 400,
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00F0FF).withOpacity(0.1),
              border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.4), width: 2),
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF00F0FF),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '¡Venta registrada!',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La transacción se ha guardado con éxito en el sistema.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7000FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Aceptar',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
