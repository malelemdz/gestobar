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
                            'Inicia sesión en tu bar asignado',
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

/// 📋 3. Main Dashboard View (Temporal)
class MainDashboardView extends ConsumerWidget {
  const MainDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestobar'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera de bienvenida con Bento Grid Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28.0,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          backgroundImage: user.fotoUrl != null && user.fotoUrl!.isNotEmpty
                              ? NetworkImage(user.fotoUrl!)
                              : null,
                          child: user.fotoUrl == null || user.fotoUrl!.isEmpty
                              ? Text(
                                  user.nombre.isNotEmpty
                                      ? user.nombre[0].toUpperCase()
                                      : 'U',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenido de nuevo,',
                                style: theme.textTheme.labelSmall,
                              ),
                              Text(
                                user.nombre,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32.0),
                    // Información del Rol y del Bar Tenant
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rol Asignado', style: theme.textTheme.labelSmall),
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
                            Text('Tenant (Bar ID)', style: theme.textTheme.labelSmall),
                            const SizedBox(height: 4.0),
                            Text(
                              authState.activeBarId != null
                                  ? authState.activeBarId!.substring(0, 8) + '...'
                                  : 'GLOBAL / SUPERADMIN',
                              style: theme.textTheme.bodyMedium?.copyWith(
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
            
            // Bento Grid de ejemplo
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: [
                  // Tarjeta Caja
                  _buildDashboardItem(
                    context: context,
                    icon: Icons.payments,
                    title: 'Control de Caja',
                    subtitle: 'Aperturas y cierres',
                    color: AppTheme.colorWarning,
                  ),
                  // Tarjeta POS Ventas
                  _buildDashboardItem(
                    context: context,
                    icon: Icons.point_of_sale,
                    title: 'Punto de Venta',
                    subtitle: 'Registrar ventas rápidas',
                    color: AppTheme.colorSuccess,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {},
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
                child: Icon(icon, color: color, size: 28.0),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11.0,
                    ),
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
