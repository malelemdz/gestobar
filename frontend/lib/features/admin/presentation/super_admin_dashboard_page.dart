import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../presentation/bar_selector_view.dart';
import '../../dashboard/presentation/main_dashboard_view.dart';

class SuperAdminDashboardPage extends ConsumerStatefulWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  ConsumerState<SuperAdminDashboardPage> createState() => _SuperAdminDashboardPageState();
}

class _SuperAdminDashboardPageState extends ConsumerState<SuperAdminDashboardPage> {
  int _totalBars = 0;
  int _activeBars = 0;
  int _inactiveBars = 0;
  int _totalAdmins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGlobalStats();
  }

  Future<void> _fetchGlobalStats() async {
    try {
      final dio = ref.read(dioProvider);

      // Cargar bars
      final barsRes = await dio.get(ApiConstants.bars);
      final List<dynamic> bars = barsRes.data ?? [];
      
      // Cargar users
      final usersRes = await dio.get('/users');
      final List<dynamic> users = usersRes.data ?? [];

      if (mounted) {
        setState(() {
          _totalBars = bars.length;
          _activeBars = bars.where((b) => b['estado'] == true).length;
          _inactiveBars = bars.where((b) => b['estado'] == false).length;
          _totalAdmins = users.where((u) {
            final rol = u['rol'];
            return rol != null && rol['nombre'].toString().toUpperCase() == 'ADMIN';
          }).length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;

    return RefreshIndicator(
      onRefresh: _fetchGlobalStats,
      color: const Color(0xFF00F0FF),
      backgroundColor: const Color(0xFF1E2024),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo de Bienvenida Premium
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7000FF).withOpacity(0.15),
                    blurRadius: 16.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consola Global SaaS',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '¡Hola, ${user.nombre.split(' ').first}!',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          'Monitorea el estado de suscripción, comisiones y configuración global del negocio.',
                          style: TextStyle(color: Colors.white70, fontSize: 13.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),

            // Título de Sección
            Text(
              'Métricas Generales',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16.0),

            // Bento Grid de Indicadores Globales
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width >= 720 ? 4 : 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 1.4,
                    children: [
                      _buildMetricCard(
                        title: 'Total Sucursales',
                        value: '$_totalBars',
                        icon: Icons.storefront,
                        color: const Color(0xFFDBFCFF),
                      ),
                      _buildMetricCard(
                        title: 'Activos',
                        value: '$_activeBars',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF00F0FF),
                      ),
                      _buildMetricCard(
                        title: 'Suspendidos',
                        value: '$_inactiveBars',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                      ),
                      _buildMetricCard(
                        title: 'Propietarios/Admins',
                        value: '$_totalAdmins',
                        icon: Icons.supervised_user_circle,
                        color: const Color(0xFFFFB1C3),
                      ),
                    ],
                  ),
            const SizedBox(height: 32.0),

            // Panel de Acciones Rápidas
            Text(
              'Acciones Directas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16.0),

            Card(
              color: const Color(0xFF1E2024),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0x2600F0FF),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(Icons.storefront, color: Color(0xFF00F0FF)),
                ),
                title: const Text('Administrar Sucursales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Crear, habilitar, deshabilitar y configurar tarifas.', style: TextStyle(color: Colors.white54, fontSize: 12.0)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'super_bars';
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.0,
                ),
              ),
              Icon(icon, color: color, size: 18.0),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
            ),
          ),
        ],
      ),
    );
  }
}
