import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../presentation/bar_selector_view.dart';
import '../../dashboard/presentation/main_dashboard_view.dart';
import '../data/models/auditoria_model.dart';
import 'widgets/auditoria_log_card.dart';
import '../../caja/providers/caja_provider.dart';
import '../providers/bar_provider.dart';

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
  List<AuditoriaModel> _latestLogs = [];
  Map<String, String> _barMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGlobalStats();
  }

  Future<void> _fetchGlobalStats() async {
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);

      // Cargar bars
      final barsRes = await dio.get(ApiConstants.bars);
      final List<dynamic> bars = barsRes.data ?? [];
      final Map<String, String> tempBarMap = {};
      for (final item in bars) {
        if (item is Map) {
          final id = item['id']?.toString() ?? '';
          final nombre = item['nombre']?.toString() ?? '';
          if (id.isNotEmpty) tempBarMap[id] = nombre;
        }
      }

      // Cargar users
      final usersRes = await dio.get('/users');
      final List<dynamic> users = usersRes.data ?? [];

      // Cargar últimos logs de auditoría
      final auditRes = await dio.get('/auditoria', queryParameters: {'limit': '5'});
      final List<dynamic> auditData = auditRes.data ?? [];
      final List<AuditoriaModel> auditLogs = auditData.map((json) => AuditoriaModel.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _totalBars = bars.length;
          _activeBars = bars.where((b) => b['estado'] == true).length;
          _inactiveBars = bars.where((b) => b['estado'] == false).length;
          _totalAdmins = users.where((u) {
            final rol = u['rol'];
            return rol != null && rol['nombre'].toString().toUpperCase() == 'ADMIN';
          }).length;
          _latestLogs = auditLogs;
          _barMap = tempBarMap;
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
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return RefreshIndicator(
      onRefresh: _fetchGlobalStats,
      color: const Color(0xFF00F0FF),
      backgroundColor: const Color(0xFF1E2024),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (mismo color que tarjetas) ──────────────────────────
            _isLoading
                ? _buildShimmerHeader()
                : Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2024),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.white.withOpacity(0.06), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                'Monitorea el estado global de la plataforma Gestobar.',
                                style: TextStyle(color: Colors.white70, fontSize: 13.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 20.0),

            // ── Título Métricas ────────────────────────────────────────────
            _buildSectionTitle('Métricas Generales'),
            const SizedBox(height: 12.0),

            // ── Grid métricas / shimmer ────────────────────────────────────
            _isLoading
                ? _buildShimmerMetricsGrid(isWide)
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.4,
                    children: [
                      _buildMetricCard(
                        title: 'Total Sucursales',
                        value: '$_totalBars',
                        icon: Icons.storefront,
                        color: Colors.white60,
                      ),
                      _buildMetricCard(
                        title: 'Activos',
                        value: '$_activeBars',
                        icon: Icons.check_circle_outline,
                        color: Colors.white60,
                      ),
                      _buildMetricCard(
                        title: 'Suspendidos',
                        value: '$_inactiveBars',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.white60,
                      ),
                      _buildMetricCard(
                        title: 'Propietarios/Admins',
                        value: '$_totalAdmins',
                        icon: Icons.supervised_user_circle,
                        color: Colors.white60,
                      ),
                    ],
                  ),
            const SizedBox(height: 20.0),

            // ── Acciones Directas ──────────────────────────────────────────
            _buildSectionTitle('Acciones Directas'),
            const SizedBox(height: 12.0),

            _isLoading
                ? ShimmerPlaceholder(
                    width: double.infinity,
                    height: 72.0,
                    borderRadius: BorderRadius.circular(16.0),
                  )
                : Card(
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
                      title: const Text('Administrar sucursales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Gestión global, tarifas y estado de sucursales.', style: TextStyle(color: Colors.white54, fontSize: 12.0)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                      onTap: () {
                        ref.read(activeViewProvider.notifier).state = 'super_bars';
                      },
                    ),
                  ),
            const SizedBox(height: 20.0),

            // ── Actividad Reciente ─────────────────────────────────────────
            _buildSectionTitle('Actividad Reciente'),
            const SizedBox(height: 12.0),

            _isLoading
                ? _buildShimmerLogsList()
                : _latestLogs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'No hay registros de actividad recientes',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white54,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _latestLogs.length,
                        itemBuilder: (context, index) {
                          final log = _latestLogs[index];
                          final currencyIso = ref.watch(currencyIsoProvider);
                          final currencySymbol = ref.watch(currencySymbolProvider);
                          final barTimezone = ref.watch(barTimezoneProvider);
                          final sucursalNombre = _barMap[log.barId];
                          return AuditoriaLogCard(
                            log: log,
                            currencyIso: currencyIso,
                            currencySymbol: currencySymbol,
                            barTimezone: barTimezone,
                            sucursalNombre: sucursalNombre,
                            showBarLabel: true,
                          );
                        },
                      ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  // ── Shimmer helpers ────────────────────────────────────────────────────────

  Widget _buildShimmerHeader() {
    return ShimmerPlaceholder(
      width: double.infinity,
      height: 86.0,
      borderRadius: BorderRadius.circular(20.0),
    );
  }

  Widget _buildShimmerMetricsGrid(bool isWide) {
    final count = isWide ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: count,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      childAspectRatio: 1.4,
      children: List.generate(
        4,
        (_) => ShimmerPlaceholder(
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }

  Widget _buildShimmerLogsList() {
    return Column(
      children: List.generate(
        4,
        (i) => ShimmerPlaceholder(
          width: double.infinity,
          height: 72.0,
          borderRadius: BorderRadius.circular(16.0),
          margin: const EdgeInsets.only(bottom: 10.0),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15.0,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }

  // ── Metric card ────────────────────────────────────────────────────────────

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
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
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
