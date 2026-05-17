import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/network/dio_client.dart';
import 'core/constants/api_constants.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/auth_state.dart';

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
      themeMode: ThemeMode.dark, // Midnight Gold por defecto para la noche del bar
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

/// Provider para controlar el índice de navegación activo en el Shell
final navIndexProvider = StateProvider<int>((ref) => 0);

/// 📋 3. Main Dashboard View - Caparazón de Navegación Adaptativa y Responsiva
class MainDashboardView extends ConsumerWidget {
  const MainDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final selectedIndex = ref.watch(navIndexProvider);

    // 1. Definir los destinos de navegación dinámicamente según el Rol del usuario
    final List<Map<String, dynamic>> navItems = _getNavItemsForRole(user.rolNombre);

    // Si el índice seleccionado quedó fuera de rango por cambio de rol, reiniciarlo
    if (selectedIndex >= navItems.length) {
      Future.microtask(() => ref.read(navIndexProvider.notifier).state = 0);
      return const PremiumSplashScreen();
    }

    final activeItem = navItems[selectedIndex];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // CONTROL DE PANTALLA: Pantallas >= 800px se consideran Tablets / PCs
          final bool isTablet = constraints.maxWidth >= 800;

          if (isTablet) {
            // ==========================================
            // LAYOUT TABLET / PC: Sidebar Lateral Fijo
            // ==========================================
            return Row(
              children: [
                // SIDEBAR PREMIUM CUSTOM (Midnight Gold)
                Container(
                  width: 260.0,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabecera del Sidebar: Logo y Marca
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Icon(
                                Icons.local_bar,
                                color: theme.colorScheme.primary,
                                size: 24.0,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Text(
                              'Gestobar',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1.0),
                      const SizedBox(height: 16.0),

                      // Lista de Navegación del Sidebar
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemCount: navItems.length,
                          itemBuilder: (context, index) {
                            final item = navItems[index];
                            final bool isSelected = index == selectedIndex;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                selected: isSelected,
                                selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                leading: Icon(
                                  isSelected ? item['icon_active'] as IconData : item['icon'] as IconData,
                                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  item['label'] as String,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                                onTap: () {
                                  ref.read(navIndexProvider.notifier).state = index;
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      // Perfil del Usuario en el pie del Sidebar
                      const Divider(height: 1.0),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20.0,
                                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                                  child: Text(
                                    user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.nombre,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        user.rolNombre.toUpperCase(),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 10.0,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            // Botones de acción rápida en el Sidebar
                            Row(
                              children: [
                                if (user.rolNombre == 'SUPERADMIN')
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.swap_horiz, size: 16.0),
                                      label: const Text('Cambiar Bar', style: TextStyle(fontSize: 11.0)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      ),
                                      onPressed: () {
                                        ref.read(authProvider.notifier).selectBar(null);
                                      },
                                    ),
                                  )
                                else
                                  const Spacer(),
                                const SizedBox(width: 8.0),
                                IconButton(
                                  icon: const Icon(Icons.logout, size: 20.0),
                                  tooltip: 'Cerrar Sesión',
                                  onPressed: () {
                                    ref.read(authProvider.notifier).logout();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // CUERPO CENTRAL DE LA PÁGINA
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(activeItem['label'] as String),
                      elevation: 0,
                    ),
                    body: activeItem['view'] as Widget,
                  ),
                ),
              ],
            );
          } else {
            // ==========================================
            // LAYOUT MÓVIL: Translúcido Bottom Bar / Drawer
            // ==========================================
            final showBottomBar = navItems.length > 1;

            return Scaffold(
              appBar: AppBar(
                title: Text(activeItem['label'] as String),
                actions: [
                  if (user.rolNombre == 'SUPERADMIN')
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Cambiar de Sucursal',
                      onPressed: () {
                        ref.read(authProvider.notifier).selectBar(null);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Cerrar Sesión',
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                  ),
                ],
              ),
              body: activeItem['view'] as Widget,
              bottomNavigationBar: showBottomBar
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
                        currentIndex: selectedIndex,
                        onTap: (index) {
                          ref.read(navIndexProvider.notifier).state = index;
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

  // Genera el listado de páginas dinámicas según el rol autenticado
  List<Map<String, dynamic>> _getNavItemsForRole(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'SUPERADMIN':
      case 'ADMIN':
        return [
          {
            'label': 'Dashboard',
            'icon': Icons.dashboard_outlined,
            'icon_active': Icons.dashboard,
            'view': const DashboardPage(),
          },
          {
            'label': 'Punto de Venta',
            'icon': Icons.point_of_sale_outlined,
            'icon_active': Icons.point_of_sale,
            'view': const PosPage(),
          },
          {
            'label': 'Caja y Turnos',
            'icon': Icons.payments_outlined,
            'icon_active': Icons.payments,
            'view': const CajaPage(),
          },
          {
            'label': 'Auditoría',
            'icon': Icons.security_outlined,
            'icon_active': Icons.security,
            'view': const AuditoriaPage(),
          },
        ];
      case 'BARMAN':
        return [
          {
            'label': 'Punto de Venta',
            'icon': Icons.point_of_sale_outlined,
            'icon_active': Icons.point_of_sale,
            'view': const PosPage(),
          },
          {
            'label': 'Caja y Turnos',
            'icon': Icons.payments_outlined,
            'icon_active': Icons.payments,
            'view': const CajaPage(),
          },
        ];
      case 'DAMA':
        return [
          {
            'label': 'Mis Comisiones',
            'icon': Icons.star_outline,
            'icon_active': Icons.star,
            'view': const DamaPage(),
          },
        ];
      default:
        return [
          {
            'label': 'Dashboard',
            'icon': Icons.dashboard_outlined,
            'icon_active': Icons.dashboard,
            'view': const DashboardPage(),
          },
        ];
    }
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta Bento Principal: Información del Usuario y Local
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26.0,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                        child: Text(
                          user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20.0),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SESIÓN ACTIVA', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.0)),
                            Text(
                              user.nombre,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ROL OPERATIVO', style: theme.textTheme.labelSmall),
                          const SizedBox(height: 4.0),
                          Chip(
                            label: Text(user.rolNombre.toUpperCase()),
                            backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                            labelStyle: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('SUCURSAL ACTIVA', style: theme.textTheme.labelSmall),
                          const SizedBox(height: 4.0),
                          Text(
                            authState.activeBarId != null
                                ? authState.activeBarId!.substring(0, 8) + '...'
                                : 'GLOBAL',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
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

          // Grilla Bento de Accesos Rápidos
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.25,
            children: [
              _buildBentoItem(
                context: context,
                icon: Icons.point_of_sale,
                title: 'POS Ventas',
                subtitle: 'Ir a facturación',
                color: AppTheme.colorSuccess,
                onTap: () {
                  ref.read(navIndexProvider.notifier).state = 1;
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.payments,
                title: 'Caja',
                subtitle: 'Control de turnos',
                color: AppTheme.colorWarning,
                onTap: () {
                  ref.read(navIndexProvider.notifier).state = 2;
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.security,
                title: 'Auditoría',
                subtitle: 'Registro de logs',
                color: theme.colorScheme.secondary,
                onTap: () {
                  ref.read(navIndexProvider.notifier).state = 3;
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.storefront,
                title: 'Sucursales',
                subtitle: 'Gestionar bares',
                color: theme.colorScheme.primary,
                onTap: () {
                  if (user.rolNombre == 'SUPERADMIN') {
                    ref.read(authProvider.notifier).selectBar(null);
                  }
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: color, size: 24.0),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
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
