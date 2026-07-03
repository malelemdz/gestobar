import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/responsive_modal.dart';
import '../../data/models/bar_model.dart';

Future<bool?> showBarStatusConfirmationBottomSheet({
  required BuildContext context,
  required BarModel bar,
  required bool targetState,
}) {
  final confirmColor = targetState ? const Color(0xFF00F0FF) : Colors.redAccent;
  final title = targetState ? '¿HABILITAR SUCURSAL?' : '¿DESHABILITAR SUCURSAL?';
  final description = targetState
      ? '¿Estás seguro de que deseas habilitar la sucursal "${bar.nombre}"? Los usuarios vinculados a este bar podrán volver a iniciar sesión y realizar ventas normalmente.'
      : '¿Estás seguro de que deseas deshabilitar la sucursal "${bar.nombre}"? Se bloquearán todos los accesos a esta terminal y ningún usuario podrá iniciar sesión.';
  final confirmText = targetState ? 'Habilitar' : 'Deshabilitar';
  final icon = targetState ? Icons.check_circle_outline : Icons.block_outlined;

  final bool isTablet = MediaQuery.of(context).size.width >= 720;

  return showResponsiveDialog<bool>(
    context: context,
    maxWidth: 450,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: isTablet
            ? BorderRadius.circular(24.0)
            : const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: isTablet
            ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
            : Border(top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isTablet) ...[
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: confirmColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: confirmColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: targetState ? const Color(0xFF0C0E12) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
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
