import 'package:flutter/material.dart';

/// 🌟 Splash Screen Minimalista y Profesional
class PremiumSplashScreen extends StatelessWidget {
  const PremiumSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: const Color(0xFF111317), // Forzar siempre el color oscuro premium
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeIn,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                // Contenido principal del splash
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Usando el app_icon en lugar del isotipo puro
                      Image.asset(
                        'assets/icon/app_icon.png',
                        width: 90.0,
                        height: 90.0,
                        fit: BoxFit.contain, // Prevenir cualquier deformación
                      ),
                    ],
                  ),
                ),
                
                // Copyright (esquina inferior centrado)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24.0,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Gestobar © $currentYear',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11.0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
