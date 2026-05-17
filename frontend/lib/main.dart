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
                        border: Border(
                          top: BorderSide(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: BottomNavigationBar(
                        currentIndex: navItems.indexWhere((item) => item['view'] == activeView),
                        onTap: (index) {
                          ref.read(activeViewProvider.notifier).state = navItems[index]['view'] as String;
                        },
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: theme.colorScheme.surface,
                        selectedItemColor: theme.colorScheme.primary,
                        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
                        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        items: navItems.map((item) {
                          return BottomNavigationBarItem(
                            icon: Icon(item['icon'] as IconData),
                            activeIcon: Icon(item['icon_active'] as IconData),
                            label: item['label'] as String,
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
    final bool isCajaAbierta = true; // Simulación para el prototipo visual

    Widget leadingWidget;
    if (isTablet) {
      leadingWidget = const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Icon(Icons.blur_on, color: Colors.amber, size: 28.0),
      );
    } else {
      // En móvil, si estamos en una pantalla profunda (Perfil/Config), mostramos botón Atrás
      final bool isDeepView = activeView == 'perfil' || activeView == 'config';
      if (isDeepView) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(activeViewProvider.notifier).state = _getDefaultViewForRole(role);
          },
        );
      } else {
        // Hamburger Menu para abrir el Mobile Drawer
        leadingWidget = Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        );
      }
    }

    List<Widget> actionsList = [];

    // Acción 1: Estado de Caja dinámico (Redirige al tocarlo al módulo de Caja)
    if (role != 'DAMA' && activeView != 'perfil' && activeView != 'config') {
      actionsList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: InkWell(
            onTap: () {
              ref.read(activeViewProvider.notifier).state = 'caja';
            },
            borderRadius: BorderRadius.circular(30.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: isCajaAbierta
                    ? AppTheme.colorSuccess.withOpacity(0.12)
                    : AppTheme.colorWarning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(
                  color: isCajaAbierta
                      ? AppTheme.colorSuccess.withOpacity(0.4)
                      : AppTheme.colorWarning.withOpacity(0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCajaAbierta ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    size: 14.0,
                    color: isCajaAbierta ? AppTheme.colorSuccess : AppTheme.colorWarning,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    isCajaAbierta ? 'Caja Abierta' : 'Caja Cerrada',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isCajaAbierta ? AppTheme.colorSuccess : AppTheme.colorWarning,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.0,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      actionsList.add(const SizedBox(width: 12.0));
    }

    // Acción 2: Monitoreo en vivo de comisiones acumuladas y WebSocket para Damas
    if (role == 'DAMA' && activeView == 'comis') {
      // Indicador WebSocket
      actionsList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: const Color(0xFF00ADB5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFF00ADB5).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00ADB5),
                  ),
                ),
                const SizedBox(width: 6.0),
                const Text(
                  'Realtime',
                  style: TextStyle(
                    color: Color(0xFF00ADB5),
                    fontWeight: FontWeight.bold,
                    fontSize: 9.0,
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_outlined, color: Colors.amber, size: 14.0),
                const SizedBox(width: 6.0),
                Text(
                  '150.00 Bs',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0,
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz, size: 14.0),
            label: Text(
              activeBarId != null ? 'Cambiar Bar' : 'Bares',
              style: const TextStyle(fontSize: 10.0),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
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

    return AppBar(
      leading: leadingWidget,
      title: Text(
        pageLabel,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
      actions: actionsList,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      shape: Border(
        bottom: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.15),
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

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del Drawer con degradado premium Midnight Gold
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.primary.withOpacity(0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.local_bar, color: theme.colorScheme.primary, size: 24.0),
                    ),
                    const SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestobar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'SaaS Hospitality',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9.0,
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(
                  activeBarName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Usuario: ${user.nombre} (${user.rolNombre.toUpperCase()})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Links de navegación interna profunda
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context); // Cierra drawer
              ref.read(activeViewProvider.notifier).state = 'perfil';
            },
          ),
          if (role == 'SUPERADMIN' || role == 'ADMIN')
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                ref.read(activeViewProvider.notifier).state = 'config';
              },
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context, theme);
            },
          ),
          const Spacer(),
          const Divider(height: 1.0),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 24.0),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
      child: Material(
        color: isSelected 
            ? theme.colorScheme.secondary 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(100.0), // fully rounded pill
        child: InkWell(
          borderRadius: BorderRadius.circular(100.0),
          onTap: onTap,
          child: Container(
            height: 48.0, // Altura táctil según guía
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20.0,
                  color: isSelected 
                      ? theme.colorScheme.onSurface 
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.0,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected 
                          ? theme.colorScheme.onSurface 
                          : theme.colorScheme.onSurfaceVariant,
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

  // 🛠️ Botón inferior del Sidebar: Diseño premium de control táctil con estados activo/inactivo (10/10)
  Widget _buildSidebarBottomItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);

    final Color inactiveBg = Colors.transparent;
    final Color activeBg = isDanger 
        ? AppTheme.colorDanger 
        : theme.colorScheme.secondary;

    final Color activeText = Colors.white;
    final Color inactiveText = isDanger 
        ? AppTheme.colorDanger 
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Material(
        color: isSelected ? activeBg : inactiveBg,
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
                  color: isSelected ? activeText : inactiveText,
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13.0,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? activeText : inactiveText,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Grilla Bento de Tarjetas Métricas
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isTablet ? 4 : (constraints.maxWidth >= 550 ? 2 : 1),
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: isTablet ? 1.4 : 1.6,
                children: [
                  _buildMetricCard(
                    context: context,
                    label: 'Venta Bruta Diaria',
                    value: '€12.450',
                    subtext: '+12% vs ayer',
                    icon: Icons.trending_up,
                    accentColor: theme.colorScheme.primaryContainer, // Cyan
                  ),
                  _buildMetricCard(
                    context: context,
                    label: 'Mesas Activas',
                    value: '24 / 30',
                    subtext: '80% Ocupación',
                    icon: Icons.grid_view,
                    accentColor: theme.colorScheme.secondary, // Violeta
                  ),
                  _buildMetricCard(
                    context: context,
                    label: 'Rotación Media',
                    value: '52 min',
                    subtext: '-4 min vs media',
                    icon: Icons.timer,
                    accentColor: const Color(0xFFFFB1C3), // Rosado/Terciario fijo dim
                  ),
                  _buildMetricCard(
                    context: context,
                    label: 'Anulaciones Abiertas',
                    value: '03',
                    subtext: 'Requiere atención',
                    icon: Icons.assignment_late_outlined,
                    accentColor: theme.colorScheme.error, // Rojo
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // 2. Sección Media: Gráfico de Velocidad de Ingresos & Feed de Actividad en Vivo
              if (isTablet) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gráfico de Velocidad (Span 8 equivalent)
                    Expanded(
                      flex: 8,
                      child: Container(
                        height: 380.0,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2024),
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Velocidad de Ingresos',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      'Flujo de ventas en tiempo real por hora',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF282A2E),
                                    borderRadius: BorderRadius.circular(100.0),
                                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.1)),
                                  ),
                                  child: Text(
                                    'HOY',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9.0,
                                      color: theme.colorScheme.primaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24.0),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: const [
                                  _BarWidget(label: '18:00', heightPercentage: 0.66),
                                  SizedBox(width: 8.0),
                                  _BarWidget(label: '19:00', heightPercentage: 0.50),
                                  SizedBox(width: 8.0),
                                  _BarWidget(label: '20:00', heightPercentage: 0.80),
                                  SizedBox(width: 8.0),
                                  _BarWidget(label: 'AHORA', heightPercentage: 1.0, isNow: true),
                                  SizedBox(width: 8.0),
                                  _BarWidget(label: '22:00', heightPercentage: 0.0),
                                  SizedBox(width: 8.0),
                                  _BarWidget(label: '23:00', heightPercentage: 0.0),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24.0),

                    // Actividad en Vivo (Span 4 equivalent)
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 380.0,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2024),
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.08),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actividad en Vivo',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Expanded(
                              child: ListView(
                                children: [
                                  _buildActivityTile(
                                    context: context,
                                    title: 'Mesa 12 cerrada',
                                    subtitle: 'Total pagado: €142,50',
                                    icon: Icons.payments,
                                    iconColor: theme.colorScheme.secondary,
                                    time: '2m',
                                  ),
                                  _buildActivityTile(
                                    context: context,
                                    title: 'Anulación: Mesa 4',
                                    subtitle: 'Item: Negroni (Error entrada)',
                                    icon: Icons.block,
                                    iconColor: theme.colorScheme.error,
                                    time: '8m',
                                  ),
                                  _buildActivityTile(
                                    context: context,
                                    title: 'Nueva Reseña 5★',
                                    subtitle: '"Cócteles increíbles, servicio 10"',
                                    icon: Icons.star,
                                    iconColor: theme.colorScheme.primaryContainer,
                                    time: '15m',
                                  ),
                                  _buildActivityTile(
                                    context: context,
                                    title: 'Staff: Entrada',
                                    subtitle: 'Marta Ruiz ha iniciado turno',
                                    icon: Icons.person_add,
                                    iconColor: theme.colorScheme.onSurfaceVariant,
                                    time: '22m',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // En móvil, apilados verticalmente
                Container(
                  height: 280.0,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2024),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.08),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Velocidad de Ingresos',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            _BarWidget(label: '18:00', heightPercentage: 0.66),
                            SizedBox(width: 6.0),
                            _BarWidget(label: '19:00', heightPercentage: 0.50),
                            SizedBox(width: 6.0),
                            _BarWidget(label: '20:00', heightPercentage: 0.80),
                            SizedBox(width: 6.0),
                            _BarWidget(label: 'AHORA', heightPercentage: 1.0, isNow: true),
                            SizedBox(width: 6.0),
                            _BarWidget(label: '22:00', heightPercentage: 0.0),
                            SizedBox(width: 6.0),
                            _BarWidget(label: '23:00', heightPercentage: 0.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2024),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.08),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actividad en Vivo',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildActivityTile(
                            context: context,
                            title: 'Mesa 12 cerrada',
                            subtitle: 'Total pagado: €142,50',
                            icon: Icons.payments,
                            iconColor: theme.colorScheme.secondary,
                            time: '2m',
                          ),
                          _buildActivityTile(
                            context: context,
                            title: 'Anulación: Mesa 4',
                            subtitle: 'Item: Negroni (Error entrada)',
                            icon: Icons.block,
                            iconColor: theme.colorScheme.error,
                            time: '8m',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24.0),

              // 3. Sección Inferior: Próximas Reservas Carousel Horizontal
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Próximas Reservas',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  SizedBox(
                    height: 120.0,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildReservationCard(
                          context: context,
                          name: 'Familia García',
                          details: 'Mesa 8 • 4 Personas',
                          time: '21:00',
                          icon: Icons.celebration_outlined,
                          badgeText: 'Aniversario',
                        ),
                        _buildReservationCard(
                          context: context,
                          name: 'Marcos Sánchez',
                          details: 'Bar • 2 Personas',
                          time: '21:15',
                          icon: Icons.local_bar_outlined,
                          badgeText: 'Primera visita',
                        ),
                        _buildReservationCard(
                          context: context,
                          name: 'Elena Portillo',
                          details: 'VIP • 6 Personas',
                          time: '21:30',
                          icon: Icons.star_outline,
                          badgeText: 'Cliente VIP Gold',
                          isVIP: true,
                        ),
                        _buildReservationCard(
                          context: context,
                          name: 'Jorge Luis',
                          details: 'Mesa 15 • 3 Personas',
                          time: '22:00',
                          icon: Icons.event_seat_outlined,
                          badgeText: 'Mesa preferida',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 🛠️ Bento metric card builder
  Widget _buildMetricCard({
    required BuildContext context,
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024), // surface-container
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.08),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, color: accentColor, size: 20.0),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 26.0,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                subtext,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11.0,
                  color: accentColor.withOpacity(0.95),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🛠️ Live activity list tile builder
  Widget _buildActivityTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String time,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10.0,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ Upcoming reservations carousel card builder
  Widget _buildReservationCard({
    required BuildContext context,
    required String name,
    required String details,
    required String time,
    required IconData icon,
    required String badgeText,
    bool isVIP = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 280.0,
      margin: const EdgeInsets.only(right: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24.0),
        border: isVIP 
            ? Border.all(color: theme.colorScheme.primaryContainer.withOpacity(0.5), width: 1.5)
            : Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.08), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      details,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12.0,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: isVIP ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: Text(
                  time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0,
                    color: isVIP ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Icon(
                icon,
                size: 14.0,
                color: isVIP ? theme.colorScheme.primaryContainer : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6.0),
              Text(
                badgeText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11.5,
                  fontWeight: isVIP ? FontWeight.bold : FontWeight.normal,
                  color: isVIP ? theme.colorScheme.primaryContainer : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 📊 Componente de barra individual para el gráfico Bento simulador de velocidad
class _BarWidget extends StatelessWidget {
  final String label;
  final double heightPercentage;
  final bool isNow;

  const _BarWidget({
    required this.label,
    required this.heightPercentage,
    this.isNow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = isNow ? theme.colorScheme.primaryContainer : theme.colorScheme.primaryContainer.withOpacity(0.2);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Track de fondo sutil
                Container(
                  width: 32.0,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                // Barra llena
                FractionallySizedBox(
                  heightFactor: heightPercentage > 0 ? heightPercentage : 0.05,
                  child: Container(
                    width: 32.0,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8.0)),
                      border: isNow ? Border.all(color: Colors.white, width: 1.5) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10.0,
              fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
              color: isNow ? theme.colorScheme.primaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
