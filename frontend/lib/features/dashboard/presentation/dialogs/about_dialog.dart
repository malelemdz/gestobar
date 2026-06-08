import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';

        return AlertDialog(
          backgroundColor: const Color(0xFF1E2024),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.04),
              width: 1.0,
            ),
          ),
          title: Text(
            'Acerca de',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF7000FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7000FF).withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                child: Image.asset(
                  'assets/icon/isotipo.png',
                  width: 40.0,
                  height: 40.0,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_bar,
                      color: Color(0xFF00F0FF),
                      size: 40.0,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Gestobar v$version',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Plataforma de Alta Velocidad para Hostelería',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white30,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12.0),
              const Divider(color: Colors.white10, height: 1.0),
              const SizedBox(height: 12.0),
              Text(
                'Gestobar es la plataforma definitiva para la gestión inteligente de bares, pubs y discotecas. Optimiza el control de inventario, facturación POS, control de turnos de caja y comisiones en tiempo real, garantizando la máxima velocidad y eficiencia en entornos de alta exigencia.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 12.0,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                '© ${DateTime.now().year} Desarrollado por Oliver Malele.\nTodos los derechos reservados.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.0,
                  color: Colors.white30,
                  height: 1.3,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00F0FF),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: BorderSide(
                    color: const Color(0xFF00F0FF).withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
              ),
              child: Text(
                'Entendido',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
