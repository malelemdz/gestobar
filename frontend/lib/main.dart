import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/auth_state.dart';
import 'core/local_db/hive_provider.dart';
import 'core/theme/app_theme.dart';

// Importaciones de los nuevos componentes de vistas modulares
import 'features/splash/presentation/splash_screen.dart';
import 'features/auth/presentation/login_view.dart';
import 'features/dashboard/presentation/main_dashboard_view.dart';
import 'features/admin/presentation/bar_selector_view.dart';

void main() async {
  // Asegura que las llamadas a canales nativos de Flutter (como Secure Storage)
  // estén inicializadas antes de que se dibuje el árbol de widgets.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización ultra-rápida de la caché local NoSQL (Hive)
  await initHive();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Comportamiento de scroll global estático y sin deformación elástica
class ClampingScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Elimina por completo el brillo y estiramiento visual
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(); // Fuerza la física Clamping estática de forma global
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar reactivamente el estado de autenticación
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Gestobar POS & SaaS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Detecta y respeta automáticamente el tema del sistema (Modo Claro/Oscuro)
      scrollBehavior: ClampingScrollBehavior(), // Registro global del comportamiento estático
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: _resolveHomeScreen(authState),
    );
  }

  Widget _resolveHomeScreen(AuthState state) {
    if (state is AuthInitial || state is AuthLoading) {
      return const PremiumSplashScreen();
    } else if (state is AuthAuthenticated) {
      if (state.activeBarId == null) {
        return const BarSelectorView();
      }
      return const MainDashboardView();
    } else {
      return const LoginView();
    }
  }
}

// Componentes modulares cargados desde sus respectivos archivos.
