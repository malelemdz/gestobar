import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'core/constants/api_constants.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/auth_state.dart';
import 'features/auth/models/user_model.dart';

void main() {
  // Asegura que las llamadas a canales nativos de Flutter (como Secure Storage)
  // estén inicializadas antes de que se dibuje el árbol de widgets.
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // Requerido por Riverpod para inicializar el contenedor de estados
    const ProviderScope(
      child: MyApp(),
    ),
  );
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

/// 🌟 1. Splash Screen Premium en Modo Midnight Gold
class PremiumSplashScreen extends StatelessWidget {
  const PremiumSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono con efecto de resplandor dorado
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 2.0,
                  ),
                ),
                child: Icon(
                  Icons.local_bar,
                  size: 64.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24.0),
              // Título
              Text(
                'Gestobar',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Sistemas Multi-tenant de Alto Impacto',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 48.0),
              // Spinner elegante
              SizedBox(
                width: 28.0,
                height: 28.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎨 2. Login View - Estética Premium Ultra-refinada
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabecera / Marca
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.hotel, // Hospitality icon similar a Material Symbols
                            size: 56.0,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Gestobar',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            'Inicia sesión para comenzar',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40.0),

                    // Mensaje de Error si existiera
                    if (authState is AuthError) ...[
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          border: Border.all(
                            color: theme.colorScheme.error,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.colorScheme.error),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                authState.message,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                    ],

                    // Input de Usuario
                    Text(
                      'Usuario o Celular',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'ej. admin, juan123',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.outline, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),

                    // Input de Contraseña
                    Text(
                      'Contraseña',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.outline, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.0),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32.0),

                    // Botón de Inicio de Sesión Tactil Grande
                    ElevatedButton(
                      onPressed: authState is AuthLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.brightness == Brightness.dark
                            ? const Color(0xFF261A00) // on-primary-fixed dark color
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4.0,
                        shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      child: authState is AuthLoading
                          ? const SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.login),
                                const SizedBox(width: 12.0),
                                Text(
                                  'Ingresar al Sistema',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.brightness == Brightness.dark
                                        ? const Color(0xFF261A00)
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Provider global para controlar la vista activa del sistema (Soporta navegación ilimitada y profunda)
final activeViewProvider = StateProvider<String>((ref) => 'dash');

/// 📋 3. Main Dashboard View - Caparazón de Navegación Adaptativa y Responsiva
class MainDashboardView extends ConsumerWidget {
  const MainDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final activeView = ref.watch(activeViewProvider);
    final activeBarId = authState.activeBarId;
    final String activeBarName = activeBarId != null ? 'El Templo del Oro' : 'Consola Global';

    final String role = user.rolNombre.toUpperCase();

    // auto-corrección: asegurar que la vista seleccionada sea permitida para el rol
    final List<String> allowedViews = _getAllowedViewsForRole(role);
    if (!allowedViews.contains(activeView)) {
      final String defaultView = _getDefaultViewForRole(role);
      Future.microtask(() => ref.read(activeViewProvider.notifier).state = defaultView);
      return const PremiumSplashScreen();
    }

    // 1. Obtener ítems de navegación principales (menú diario operativo)
    final List<Map<String, dynamic>> navItems = _getNavItemsForRole(role);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth >= 800;

          if (isTablet) {
            // ==========================================
            // LAYOUT TABLET / PC: Sidebar Lateral Fijo
            // ==========================================
            return Row(
              children: [
                // SIDEBAR PREMIUM CUSTOM (Mid                // SIDEBAR PREMIUM CUSTOM (Liquid Modernist - Neon Lounge Aesthetic)
                Container(
                  width: 260.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C20), // surface-container-low según guía
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.1),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera del Sidebar: Logo y título Neon Lounge
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeBarId != null ? 'Neon Lounge' : 'Gestobar',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 28.0,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primaryContainer, // Electric Cyan (#00F0FF)
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              activeBarId != null ? 'Bar Management' : 'Global Console',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13.0,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de Módulos Operativos
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          itemCount: navItems.length,
                          itemBuilder: (context, index) {
                            final item = navItems[index];
                            final String viewId = item['view'] as String;
                            final bool isSelected = activeView == viewId;

                            return _buildSidebarNavItem(
                              context: context,
                              icon: isSelected ? item['icon_active'] as IconData : item['icon'] as IconData,
                              label: item['label'] as String,
                              isSelected: isSelected,
                              onTap: () {
                                ref.read(activeViewProvider.notifier).state = viewId;
                              },
                            );
                          },
                        ),
                      ),

                      // MENÚ DE OPCIONES DE CONFIGURACIÓN Y SOPORTE (SIDEBAR BOTTOM)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Botón de Acción Principal: Nueva Venta / Nueva Orden
                            if (role == 'ADMIN' || role == 'SUPERADMIN' || role == 'BARMAN') ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  height: 48.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100.0),
                                    color: theme.colorScheme.primaryContainer, // Cyan
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(100.0),
                                      onTap: () {
                                        ref.read(activeViewProvider.notifier).state = 'pos';
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 20.0,
                                            color: theme.colorScheme.onPrimaryContainer,
                                          ),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            'NUEVA ORDEN',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.0,
                                              color: theme.colorScheme.onPrimaryContainer,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const Divider(color: Color(0xFF282A2E), height: 1.0),
                            const SizedBox(height: 12.0),

                            // Opción: Soporte & Perfil
                            _buildSidebarBottomItem(
                              context: context,
                              icon: Icons.person_outline,
                              label: 'Mi Perfil',
                              isSelected: activeView == 'perfil',
                              onTap: () {
                                ref.read(activeViewProvider.notifier).state = 'perfil';
                              },
                            ),
                            const SizedBox(height: 4.0),

                            if (role == 'SUPERADMIN' || role == 'ADMIN') ...[
                              _buildSidebarBottomItem(
                                context: context,
                                icon: Icons.settings_outlined,
                                label: 'Configuración',
                                isSelected: activeView == 'config',
                                onTap: () {
                                  ref.read(activeViewProvider.notifier).state = 'config';
                                },
                              ),
                              const SizedBox(height: 4.0),
                            ],

                            _buildSidebarBottomItem(
                              context: context,
                              icon: Icons.info_outline,
                              label: 'Acerca de',
                              isSelected: false,
                              onTap: () {
                                _showAboutDialog(context, theme);
                              },
                            ),
                            const SizedBox(height: 8.0),

                            // Perfil de Usuario Premium Row (Exactamente como en la plantilla)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18.0,
                                    backgroundColor: theme.colorScheme.secondary.withOpacity(0.15),
                                    child: Text(
                                      user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        color: theme.colorScheme.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.nombre,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.0,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          role,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontSize: 8.0,
                                            color: theme.colorScheme.onSurfaceVariant,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.logout, size: 16.0, color: AppTheme.colorDanger),
                                    onPressed: () {
                                      ref.read(authProvider.notifier).logout();
                                    },
                                    tooltip: 'Cerrar Sesión',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // CUERPO CENTRAL DE LA PÁGINA (ESTILO PANEL DE CONTROL FLAT MINIMALISTA)
                Expanded(
                  child: Scaffold(
                    appBar: _buildCustomAppBar(
                      context: context,
                      ref: ref,
                      user: user,
                      pageLabel: _getTitleForView(activeView),
                      isTablet: true,
                      activeBarId: authState.activeBarId,
                      activeView: activeView,
                    ),
                    body: _buildBodyForView(activeView),
                  ),
                ),
              ],
            );
          } else {
            // ==========================================
            // LAYOUT MÓVIL: Translúcido Bottom Bar + Drawer
            // ==========================================
            final showBottomBar = navItems.any((item) => item['view'] == activeView);

            return Scaffold(
              drawer: _buildMobileDrawer(context, ref, user, theme),
              appBar: _buildCustomAppBar(
                context: context,
                ref: ref,
                user: user,
                pageLabel: _getTitleForView(activeView),
                isTablet: false,
                activeBarId: authState.activeBarId,
                activeView: activeView,
              ),
              body: _buildBodyForView(activeView),
              bottomNavigationBar: showBottomBar && navItems.length > 1
                  ? Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2024), // Modernist surface-container
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)), // Beautiful curves!
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.05), // subtle top divider
                            width: 1.0,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 16.0,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                        top: 12.0,
                        bottom: MediaQuery.of(context).padding.bottom + 12.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: navItems.map((item) {
                          final String viewId = item['view'] as String;
                          final bool isSelected = activeView == viewId;
                          final IconData icon = isSelected ? item['icon_active'] as IconData : item['icon'] as IconData;
                          final String label = item['label'] as String;

                          if (isSelected) {
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0x2600F0FF), // 15% opacity Electric Cyan
                                borderRadius: BorderRadius.circular(100.0), // Capsule!
                                border: Border.all(
                                  color: const Color(0x3300F0FF), // 20% opacity Electric Cyan border
                                  width: 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    color: const Color(0xFF00F0FF),
                                    size: 18.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    label,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF00F0FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return InkWell(
                            borderRadius: BorderRadius.circular(100.0),
                            onTap: () {
                              ref.read(activeViewProvider.notifier).state = viewId;
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 20.0,
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    label,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withOpacity(0.4),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : null,
            );
          }
        },
      ),
    );
  }

  // Define las vistas permitidas por cada rol
  List<String> _getAllowedViewsForRole(String role) {
    switch (role) {
      case 'SUPERADMIN':
      case 'ADMIN':
        return ['dash', 'pos', 'caja', 'menu', 'staff', 'audit', 'config', 'perfil'];
      case 'BARMAN':
        return ['pos', 'caja', 'perfil'];
      case 'DAMA':
        return ['comis', 'perfil'];
      default:
        return ['dash', 'perfil'];
    }
  }

  // Vista por defecto al arrancar o reestablecer rol
  String _getDefaultViewForRole(String role) {
    switch (role) {
      case 'SUPERADMIN':
      case 'ADMIN':
        return 'dash';
      case 'BARMAN':
        return 'pos';
      case 'DAMA':
        return 'comis';
      default:
        return 'dash';
    }
  }

  // Genera el listado de páginas dinámicas del menú operativo diario
  List<Map<String, dynamic>> _getNavItemsForRole(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'SUPERADMIN':
      case 'ADMIN':
        return [
          {
            'view': 'dash',
            'label': 'Dash',
            'icon': Icons.dashboard_outlined,
            'icon_active': Icons.dashboard,
          },
          {
            'view': 'pos',
            'label': 'POS',
            'icon': Icons.point_of_sale_outlined,
            'icon_active': Icons.point_of_sale,
          },
          {
            'view': 'caja',
            'label': 'Caja',
            'icon': Icons.payments_outlined,
            'icon_active': Icons.payments,
          },
          {
            'view': 'menu',
            'label': 'Menú',
            'icon': Icons.local_bar_outlined,
            'icon_active': Icons.local_bar,
          },
          {
            'view': 'staff',
            'label': 'Staff',
            'icon': Icons.people_alt_outlined,
            'icon_active': Icons.people,
          },
        ];
      case 'BARMAN':
        return [
          {
            'view': 'pos',
            'label': 'POS',
            'icon': Icons.point_of_sale_outlined,
            'icon_active': Icons.point_of_sale,
          },
          {
            'view': 'caja',
            'label': 'Caja',
            'icon': Icons.payments_outlined,
            'icon_active': Icons.payments,
          },
        ];
      case 'DAMA':
        return [
          {
            'view': 'comis',
            'label': 'Comis',
            'icon': Icons.star_outline,
            'icon_active': Icons.star,
          },
        ];
      default:
        return [
          {
            'view': 'dash',
            'label': 'Dash',
            'icon': Icons.dashboard_outlined,
            'icon_active': Icons.dashboard,
          },
        ];
    }
  }

  // Mapea la vista activa a su correspondiente Widget modular
  Widget _buildBodyForView(String activeView) {
    switch (activeView) {
      case 'dash':
        return const DashboardPage();
      case 'pos':
        return const PosPage();
      case 'caja':
        return const CajaPage();
      case 'menu':
        return const MenuPage();
      case 'staff':
        return const StaffPage();
      case 'audit':
        return const AuditoriaPage();
      case 'config':
        return const ConfigPage();
      case 'perfil':
        return const PerfilPage();
      case 'comis':
        return const DamaPage();
      default:
        return const DashboardPage();
    }
  }

  // Obtiene el título legible para la AppBar
  String _getTitleForView(String activeView) {
    switch (activeView) {
      case 'dash': return 'Dash';
      case 'pos': return 'POS';
      case 'caja': return 'Caja';
      case 'menu': return 'Menú';
      case 'staff': return 'Staff';
      case 'audit': return 'Audit';
      case 'config': return 'Config';
      case 'perfil': return 'Mi Perfil';
      case 'comis': return 'Comis';
      default: return 'Gestobar';
    }
  }

  // 🛠️ Diseña el AppBar personalizado y dinámico para cada Rol y Vista
  AppBar _buildCustomAppBar({
    required BuildContext context,
    required WidgetRef ref,
    required UserModel user,
    required String pageLabel,
    required bool isTablet,
    required String? activeBarId,
    required String activeView,
  }) {
    final theme = Theme.of(context);
    final String role = user.rolNombre.toUpperCase();


    Widget leadingWidget;
    if (isTablet) {
      leadingWidget = const Padding(
        padding: EdgeInsets.only(left: 24.0),
        child: Icon(Icons.blur_on, color: Color(0xFF00F0FF), size: 28.0),
      );
    } else {
      // En móvil, si estamos en una pantalla profunda (Perfil/Config), mostramos botón Atrás
      final bool isDeepView = activeView == 'perfil' || activeView == 'config';
      if (isDeepView) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
          onPressed: () {
            ref.read(activeViewProvider.notifier).state = _getDefaultViewForRole(role);
          },
        );
      } else {
        // Hamburger Menu para abrir el Mobile Drawer
        leadingWidget = Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF00F0FF)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        );
      }
    }

    List<Widget> actionsList = [];

    // Acción 2: Monitoreo en vivo de comisiones acumuladas y WebSocket para Damas
    if (role == 'DAMA' && activeView == 'comis') {
      // Indicador WebSocket
      actionsList.add(
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0x1A00F0FF),
              borderRadius: BorderRadius.circular(100.0),
              border: Border.all(color: const Color(0x3300F0FF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00F0FF),
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  'REALTIME',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF00F0FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      actionsList.add(const SizedBox(width: 8.0));

      // Indicador de Ganancias Acumuladas
      actionsList.add(
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0x1AFFB1C3), // tertiary fixed dim with 10% opacity
              borderRadius: BorderRadius.circular(100.0),
              border: Border.all(color: const Color(0x33FFB1C3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_outlined, color: Color(0xFFFFB1C3), size: 13.0),
                const SizedBox(width: 6.0),
                Text(
                  '150.00 Bs',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFFFB1C3),
                    fontWeight: FontWeight.bold,
                    fontSize: 9.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      actionsList.add(const SizedBox(width: 12.0));
    }

    // Acción 3: Botón de cambio rápido de sucursal para SuperAdmins
    if (role == 'SUPERADMIN') {
      actionsList.add(
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz, size: 14.0, color: Color(0xFF00F0FF)),
            label: Text(
              activeBarId != null ? 'CAMBIAR BAR' : 'BARES',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.0,
                color: const Color(0xFF00F0FF),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              side: const BorderSide(color: Color(0x4D00F0FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100.0),
              ),
            ),
            onPressed: () {
              ref.read(authProvider.notifier).selectBar(null);
            },
          ),
        ),
      );
      actionsList.add(const SizedBox(width: 12.0));
    }

    // Acción 4: Foto de perfil premium en la esquina superior derecha (Móvil)
    if (!isTablet) {
      actionsList.add(
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: InkWell(
              onTap: () {
                ref.read(activeViewProvider.notifier).state = 'perfil';
              },
              borderRadius: BorderRadius.circular(100.0),
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x3300F0FF), // 20% opacity Electric Cyan border
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100.0),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBZZ4F3uxeKXlMSjT5dTb1O4_BTJuDlobMGJCsqzM_uclGpddIG1PoFe-ii5WY95o6-UbkutIhovD6rNMn-Yeq0BH9OJUet_BXiwV0AICeKlwpujiO_XFxYnVuCfNdrk1lasqCUyWhonZnODKafZDkpzxmUNyGoKPyZo7zMxLqhcaNnRIgINDnP5WjuhxdbwpvaiPVSK842ts9aS8GphuRhQB4reNSPcZLIz4YV4c_HPg-0Cj5n50esRHFSYrRtQQucvQXq2pCKA1c', // exact URL from code.html mockup!
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF00F0FF), size: 16.0);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add static notifications/sync elements in Tablet to match code.html
    if (isTablet) {
      actionsList.add(
        IconButton(
          icon: const Icon(Icons.sync, size: 20.0),
          color: theme.colorScheme.onSurfaceVariant,
          onPressed: () {},
        ),
      );
      actionsList.add(
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20.0),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: () {},
            ),
            Positioned(
              top: 12.0,
              right: 12.0,
              child: Container(
                width: 7.0,
                height: 7.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB4AB),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
      actionsList.add(const SizedBox(width: 8.0));
      actionsList.add(
        Container(
          width: 1.0,
          height: 24.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          color: Colors.white.withOpacity(0.08),
        ),
      );
      actionsList.add(const SizedBox(width: 8.0));
      actionsList.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ESTADO: ',
              style: GoogleFonts.jetBrainsMono(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0x1A00F0FF),
                borderRadius: BorderRadius.circular(100.0),
                border: Border.all(color: const Color(0x3300F0FF)),
              ),
              child: Text(
                'EN VIVO',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF00F0FF),
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
      actionsList.add(const SizedBox(width: 24.0));
    }

    return AppBar(
      leading: isTablet
          ? leadingWidget
          : Builder(
              builder: (context) => InkWell(
                onTap: () {
                  final bool isDeepView = activeView == 'perfil' || activeView == 'config';
                  if (isDeepView) {
                    ref.read(activeViewProvider.notifier).state = _getDefaultViewForRole(role);
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                },
                borderRadius: BorderRadius.circular(100.0),
                child: Container(
                  width: 56.0,
                  height: 56.0,
                  alignment: Alignment.center,
                  child: Icon(
                    (activeView == 'perfil' || activeView == 'config')
                        ? Icons.arrow_back
                        : Icons.menu,
                    color: const Color(0xFF00F0FF),
                    size: 24.0,
                  ),
                ),
              ),
            ),
      leadingWidth: isTablet ? 64.0 : 56.0,
      automaticallyImplyLeading: false,
      titleSpacing: isTablet ? 16.0 : 0.0, // starts exactly where leading widget ends, making horizontal gap perfect
      title: isTablet
          ? Row(
              children: [
                Text(
                  'Neon Management',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 22.0,
                    color: const Color(0xFFDBFCFF),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 24.0),
                // Search Input Bar to match code.html
                Container(
                  height: 38.0,
                  width: 240.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2024),
                    borderRadius: BorderRadius.circular(100.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), size: 16.0),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar mesas, pedidos...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Text(
              pageLabel,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20.0,
                color: const Color(0xFF00F0FF),
                letterSpacing: pageLabel == 'Gestobar' ? -0.8 : -0.3,
                height: 1.0, // perfect vertical baseline centering
              ),
            ),
      actions: actionsList,
      elevation: 0,
      toolbarHeight: isTablet ? 72.0 : 56.0,
      backgroundColor: const Color(0xFF111317), // unified dark theme background
      shape: Border(
        bottom: BorderSide(
          color: Colors.white.withOpacity(0.06),
          width: 1.0,
        ),
      ),
    );
  }

  // 🚪 Diseña el cajón de navegación lateral móvil para Perfil y Configuración
  Widget _buildMobileDrawer(BuildContext context, WidgetRef ref, UserModel user, ThemeData theme) {
    final String role = user.rolNombre.toUpperCase();
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final activeBarId = authState.activeBarId;
    final String activeBarName = activeBarId != null ? 'El Templo del Oro' : 'Consola Global';
    final List<Map<String, dynamic>> navItems = _getNavItemsForRole(role);
    final activeView = ref.watch(activeViewProvider);

    return Drawer(
      backgroundColor: const Color(0xFF1E2024), // Modernist surface-container
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sleek Drawer Header with premium Logo Box and branding
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 56.0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: const Color(0x2600F0FF), // 15% opacity Electric Cyan
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color(0x3300F0FF), // 20% opacity Electric Cyan border
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        Icons.restaurant, // restaurant icon from html mockup!
                        color: Color(0xFF00F0FF),
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestobar',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 24.0,
                            color: const Color(0xFFDBFCFF), // primary text
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Administración Pro',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10.0,
                            color: const Color(0xFF00F0FF).withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                Text(
                  activeBarName.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.0,
                    color: const Color(0xFF00F0FF),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Usuario: ${user.nombre} (${user.rolNombre.toUpperCase()})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.5,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.white.withOpacity(0.06), height: 1.0),
          const SizedBox(height: 16.0),

          // Dynamic operational pages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final String viewId = item['view'] as String;
                final bool isSelected = activeView == viewId;

                return _buildSidebarNavItem(
                  context: context,
                  icon: isSelected ? item['icon_active'] as IconData : item['icon'] as IconData,
                  label: item['label'] as String,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.pop(context); // close drawer
                    ref.read(activeViewProvider.notifier).state = viewId;
                  },
                );
              },
            ),
          ),

          // Secondary and support actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              children: [
                Divider(color: Colors.white.withOpacity(0.06), height: 1.0),
                const SizedBox(height: 8.0),
                
                // Profile internal page link
                _buildSidebarBottomItem(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Mi Perfil',
                  isSelected: activeView == 'perfil',
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(activeViewProvider.notifier).state = 'perfil';
                  },
                ),
                
                // Config page link for admins
                if (role == 'SUPERADMIN' || role == 'ADMIN')
                  _buildSidebarBottomItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    label: 'Configuración',
                    isSelected: activeView == 'config',
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(activeViewProvider.notifier).state = 'config';
                    },
                  ),

                // Support modal trigger
                _buildSidebarBottomItem(
                  context: context,
                  icon: Icons.info_outline,
                  label: 'Acerca de',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context, theme);
                  },
                ),

                // Logout danger option
                _buildSidebarBottomItem(
                  context: context,
                  icon: Icons.logout,
                  label: 'Cerrar Sesión',
                  isSelected: false,
                  isDanger: true,
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).logout();
                  },
                ),

                const SizedBox(height: 12.0),

                // Modernist primary CTA Button matching "Cerrar Turno" in mockups
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    height: 48.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF), // Solid Electric Cyan
                      borderRadius: BorderRadius.circular(100.0), // Capsule!
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withOpacity(0.15),
                          blurRadius: 16.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100.0),
                        onTap: () {
                          Navigator.pop(context);
                          // Prototype action: show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Operación de Cierre de Turno Iniciada.'),
                              backgroundColor: Color(0xFF1E2024),
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                            'CERRAR TURNO',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00363A), // Dark contrast color
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 Botón de navegación del Sidebar: Diseño premium de control táctil con estados activo/inactivo (10/10)
  Widget _buildSidebarNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x2600F0FF) : Colors.transparent, // 15% opacity Electric Cyan
          borderRadius: BorderRadius.circular(100.0), // fully rounded modernist capsule
          border: Border.all(
            color: isSelected ? const Color(0x3300F0FF) : Colors.transparent, // 20% opacity Electric Cyan border
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(100.0),
            onTap: onTap,
            child: Container(
              height: 48.0, // Altura táctil ergonómica
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20.0,
                    color: isSelected 
                        ? const Color(0xFF00F0FF) // Electric Cyan active
                        : Colors.white.withOpacity(0.4), // Muted inactive
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected 
                            ? const Color(0xFF00F0FF) 
                            : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🛠️ Botón inferior del Sidebar: Diseño premium de control táctil con estados activo/inactivo (10/10)
  Widget _buildSidebarBottomItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final Color activeColor = isDanger ? const Color(0xFFFFB4AB) : const Color(0xFF00F0FF);
    final Color activeBg = isDanger ? const Color(0x26FFB4AB) : const Color(0x2600F0FF);
    final Color activeBorder = isDanger ? const Color(0x33FFB4AB) : const Color(0x3300F0FF);
    final Color inactiveColor = isDanger ? const Color(0xFFFFB4AB).withOpacity(0.8) : Colors.white.withOpacity(0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(100.0),
          border: Border.all(
            color: isSelected ? activeBorder : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(100.0),
            onTap: onTap,
            child: Container(
              height: 44.0,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18.0,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ℹ️ Muestra un modal premium "Acerca de"
  void _showAboutDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 10.0),
              const Text('Acerca de Gestobar'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_bar, size: 40.0, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Gestobar SaaS v1.0.0',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Plataforma de Alta Velocidad para Hostelería',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.0),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24.0),
              Text(
                'Desarrollado con dedicación para ofrecer el máximo rendimiento en flujos de trabajo de bares, pubs y discotecas bajo entornos de alta exigencia.',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.0),
              ),
              const SizedBox(height: 16.0),
              Text(
                '© 2026 Antigravity Labs. Todos los derechos reservados.',
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 9.0, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendido',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =========================================================================
// 🌟 SUB-VISTAS PRINCIPALES DEL SISTEMA (Contenedores Modulares)
// =========================================================================

/// 📊 VISTA 1: Panel de Control / Dashboard Gerencial (Bento Grid)
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tarjeta Premium de Sesión Activa (Liquid Modernist Style)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024), // surface-container
              borderRadius: BorderRadius.circular(32.0), // Extreme rounded modernist corners!
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar circular con iniciales
                      Container(
                        width: 54.0,
                        height: 54.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7000FF), // Violeta/Secondary
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user.nombre.isNotEmpty ? user.nombre.substring(0, 1).toUpperCase() : 'G',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SESIÓN ACTIVA',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              user.nombre,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFDBFCFF),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),
                  Container(
                    height: 1.0,
                    color: Colors.white.withOpacity(0.06),
                  ),
                  const SizedBox(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ROL OPERATIVO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: const Color(0x1A7000FF), // violet with 10% opacity
                              borderRadius: BorderRadius.circular(100.0),
                              border: Border.all(color: const Color(0x337000FF)),
                            ),
                            child: Text(
                              user.rolNombre.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFD1BCFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SUCURSAL ACTIVA',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            authState.activeBarId != null
                                ? 'El Templo del Oro'
                                : 'CONSOLA GLOBAL',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16.0,
                              color: const Color(0xFF00F0FF), // electric cyan
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // 2. Grilla Bento de Accesos Rápidos
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 750 ? 4 : 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: MediaQuery.of(context).size.width >= 750 ? 1.4 : 1.3,
            children: [
              _buildBentoItem(
                context: context,
                icon: Icons.point_of_sale,
                title: 'POS Ventas',
                subtitle: 'Ir a facturación',
                color: const Color(0xFF00F0FF), // electric cyan
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'pos';
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.payments,
                title: 'Caja',
                subtitle: 'Control de turnos',
                color: const Color(0xFFFFB1C3), // warm rose
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'caja';
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.local_bar,
                title: 'Menú',
                subtitle: 'Editar catálogo',
                color: const Color(0xFF7000FF), // vibrant violet
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'menu';
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.people_alt,
                title: 'Staff',
                subtitle: 'Personal y roles',
                color: const Color(0xFFDBFCFF), // mint/cyan fixed dim
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'staff';
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024), // surface-container
        borderRadius: BorderRadius.circular(32.0), // 32px rounded corners!
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(icon, color: color, size: 20.0),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16.0,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 11.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
}

/// 🛒 VISTA 2: Punto de Venta (POS) Placeholder
class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.point_of_sale, size: 64.0, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16.0),
          Text(
            'Módulo POS y Facturación',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Disponible en la Fase 2: Venta Rápida y Selección de Damas.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 💵 VISTA 3: Caja y Turnos Placeholder
class CajaPage extends StatelessWidget {
  const CajaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments, size: 64.0, color: theme.colorScheme.secondary.withOpacity(0.5)),
          const SizedBox(height: 16.0),
          Text(
            'Módulo de Control de Caja',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Disponible en la Fase 3: Aperturas, Cierres y Billeteo.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 🔒 VISTA 4: Auditoría y Logs Placeholder
class AuditoriaPage extends StatelessWidget {
  const AuditoriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 64.0, color: AppTheme.colorWarning.withOpacity(0.5)),
          const SizedBox(height: 16.0),
          Text(
            'Módulo de Auditoría de Sistemas',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Registro completo de trazabilidad multi-tenant en tiempo real.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 💃 VISTA 5: Panel de Dama de Compañía Placeholder
class DamaPage extends StatelessWidget {
  const DamaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 64.0, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16.0),
          Text(
            'Panel de Comisiones e Invitaciones',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Consulta tus comisiones acumuladas del turno actual en tiempo real.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// Provider global para consultar las sucursales del sistema
final barsFutureProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.bars);
  return response.data as List<dynamic>;
});

/// 🎨 4. Bar Selector View - Estética Premium para SuperAdmins/Propietarios
class BarSelectorView extends ConsumerWidget {
  const BarSelectorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final barsAsync = ref.watch(barsFutureProvider);
    final authState = ref.watch(authProvider) as AuthAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestobar Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20.0),
                Text(
                  'Hola, ${authState.user.nombre}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Selecciona una sucursal / bar para ingresar a la terminal operativa:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32.0),
                Expanded(
                  child: barsAsync.when(
                    data: (bars) {
                      if (bars.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 64.0,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                'No hay sucursales registradas aún.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350.0,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: bars.length,
                        itemBuilder: (context, index) {
                          final bar = bars[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                              ),
                            ),
                            elevation: 0,
                            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                            child: InkWell(
                              onTap: () {
                                ref.read(authProvider.notifier).selectBar(bar['id'] as String);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: Icon(
                                            Icons.local_bar,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        Text(
                                          bar['moneda_simbolo'] ?? 'Bs',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bar['nombre'] ?? 'Sin Nombre',
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4.0),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14.0,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Expanded(
                                              child: Text(
                                                bar['ciudad'] ?? 'Ciudad',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48.0,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Error al cargar las sucursales',
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            err.toString(),
                            style: theme.textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () => ref.refresh(barsFutureProvider),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// 🌟 SUB-VISTAS ADICIONALES (Configuración, Menú, Personal, Perfil)
// =========================================================================

/// 🍔 VISTA: Gestión de Menú / Catálogo
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_bar, size: 64.0, color: theme.colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16.0),
            Text(
              'Gestión del Menú',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Fase 4: Catálogo de productos, variantes, categorías y doble precio.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 👥 VISTA: Staff y Administración de Personal
class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined, size: 64.0, color: theme.colorScheme.secondary.withOpacity(0.5)),
            const SizedBox(height: 16.0),
            Text(
              'Personal y Permisos',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Fase 2: Administración de empleados, asignación de roles y permisos de acceso.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ⚙️ VISTA: Configuración de la Sucursal / Bar
class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_outlined, size: 64.0, color: AppTheme.colorWarning.withOpacity(0.5)),
            const SizedBox(height: 16.0),
            Text(
              'Configuración del Bar',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Fase 1: Configuración de datos de facturación, redes sociales y geolocalización de la sucursal.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 👤 VISTA: Perfil Personal del Usuario Logueado
class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 16.0),
          CircleAvatar(
            radius: 50.0,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Text(
              user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 36.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            user.nombre,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Chip(
            label: Text(user.rolNombre.toUpperCase()),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 40.0),
          _buildProfileItem(context, Icons.phone_android, 'Celular', (user.celular != null && user.celular!.isNotEmpty) ? user.celular! : 'No registrado'),
          _buildProfileItem(context, Icons.badge_outlined, 'DNI / Documento', 'No registrado'),
          _buildProfileItem(context, Icons.flag_outlined, 'País / Región', 'Bolivia'),
          const SizedBox(height: 32.0),
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Restablecer Contraseña'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Acción disponible en la siguiente fase de desarrollo.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20.0),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
