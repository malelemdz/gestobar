import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../providers/dama_provider.dart';

class DamaPage extends ConsumerStatefulWidget {
  const DamaPage({super.key});

  @override
  ConsumerState<DamaPage> createState() => _DamaPageState();
}

class _DamaPageState extends ConsumerState<DamaPage> {
  String _activeFilter = 'TODO'; // TODO, COMISION, INVITACION
  bool _isSocketConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupWebSocketListener();
    });
  }

  Future<void> _setupWebSocketListener() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final user = authState.user;

    try {
      final socketService = ref.read(socketServiceProvider);
      final socket = await socketService.connect();

      // Suscribir al canal privado de la Dama
      socket.emit('suscribir_dama', {'damaId': user.id});

      setState(() {
        _isSocketConnected = socket.connected;
      });

      socket.onConnect((_) {
        if (mounted) {
          setState(() {
            _isSocketConnected = true;
          });
        }
      });

      socket.onDisconnect((_) {
        if (mounted) {
          setState(() {
            _isSocketConnected = false;
          });
        }
      });

      socket.on('nueva_comision', (data) {
        if (mounted) {
          // Recargar comisiones silenciosamente
          ref.read(damaComisionesProvider.notifier).loadComisiones(silent: true);

          // Mostrar notificación flotante animada
          final String mensaje = data['mensaje']?.toString() ?? '¡Nueva comisión recibida!';
          CustomToast.show(
            context,
            message: mensaje,
            type: ToastType.success,
          );
        }
      });
    } catch (e) {
      debugPrint('Error al conectar socket en DamaPage: $e');
    }
  }

  @override
  void dispose() {
    // Apagar listener al salir de la pantalla
    try {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        ref.read(socketServiceProvider).socket?.off('nueva_comision');
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(damaComisionesProvider);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    const accentColor = Color(0xFFFF4081); // Color oficial Rose / Pink de Dama

    // Filtrar historial
    final filteredHistory = state.historial.where((item) {
      final bool esInvitacion = item['es_invitacion'] == true;
      if (_activeFilter == 'COMISION') return !esInvitacion;
      if (_activeFilter == 'INVITACION') return esInvitacion;
      return true;
    }).toList();

    return RefreshIndicator(
      color: accentColor,
      backgroundColor: const Color(0xFF1E2024),
      onRefresh: () => ref.read(damaComisionesProvider.notifier).loadComisiones(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header saludo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${user.nombre}!',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitorea tus comisiones en tiempo real.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Estado del WebSocket
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: _isSocketConnected ? const Color(0x1A00F0FF) : const Color(0x1AFFF3C4),
                    borderRadius: BorderRadius.circular(100.0),
                    border: Border.all(
                      color: _isSocketConnected ? const Color(0x3300F0FF) : const Color(0x33FFF3C4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.0,
                        height: 6.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isSocketConnected ? const Color(0xFF00F0FF) : const Color(0xFFFFC107),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        _isSocketConnected ? 'EN VIVO' : 'CONECTANDO',
                        style: GoogleFonts.plusJakartaSans(
                          color: _isSocketConnected ? const Color(0xFF00F0FF) : const Color(0xFFFFC107),
                          fontWeight: FontWeight.bold,
                          fontSize: 8.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bento Grid KPIs (2 Cards)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Comisiones Totales',
                    value: '${state.comisionesTotales.toStringAsFixed(2)} ${state.moneda}',
                    icon: Icons.payments_outlined,
                    color: accentColor,
                    subtitle: 'Turno activo',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Bebidas Invitadas',
                    value: '${state.totalInvitaciones}',
                    icon: Icons.local_bar_outlined,
                    color: const Color(0xFF00F0FF),
                    subtitle: 'Cantidad recibida',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filtros rápidos
            Row(
              children: [
                Text(
                  'HISTORIAL DEL TURNO',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white30,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                _buildFilterButton('Todos', 'TODO'),
                const SizedBox(width: 6),
                _buildFilterButton('Comisiones', 'COMISION'),
                const SizedBox(width: 6),
                _buildFilterButton('Invitaciones', 'INVITACION'),
              ],
            ),
            const SizedBox(height: 12),

            // Contenido / Listado
            if (state.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(color: accentColor),
                ),
              )
            else if (state.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Text(
                    'Error: ${state.error}',
                    style: TextStyle(color: Colors.redAccent.shade100, fontSize: 13),
                  ),
                ),
              )
            else if (filteredHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_outline, color: Colors.white12, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes registros de comisiones',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeFilter == 'TODO'
                          ? 'Las bebidas e invitaciones que te registren en caja aparecerán aquí en tiempo real.'
                          : 'No se encontraron registros en esta categoría.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white24,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = filteredHistory[index];
                  return _buildCommissionItemCard(item, state.moneda);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF16181C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.01),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white30,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, color: color.withOpacity(0.6), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              color: color.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    final bool isActive = _activeFilter == filter;
    final color = const Color(0xFFFF4081);

    return InkWell(
      onTap: () => setState(() => _activeFilter = filter),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isActive ? color : Colors.white30,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCommissionItemCard(dynamic item, String monedaSymbol) {
    final bool esInvitacion = item['es_invitacion'] == true;
    final String timeStr = _formatItemTime(item['fecha']?.toString());
    final double comision = (item['comision_generada'] as num?)?.toDouble() ?? 0.0;
    final int cantidad = (item['cantidad'] as num?)?.toInt() ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF16181C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          // Icon indicator
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: esInvitacion ? const Color(0x1A00F0FF) : const Color(0x1AFF4081),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              esInvitacion ? Icons.wine_bar_outlined : Icons.monetization_on_outlined,
              color: esInvitacion ? const Color(0xFF00F0FF) : const Color(0xFFFF4081),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['producto']?.toString() ?? 'Bebida',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      esInvitacion ? 'Invitación direct.' : 'Comisión de venta',
                      style: GoogleFonts.plusJakartaSans(
                        color: esInvitacion ? const Color(0xFF00F0FF) : const Color(0xFFFF4081),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(color: Colors.white10, fontSize: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white24,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price and Commission Values
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                esInvitacion
                    ? '+$cantidad cop.'
                    : '+${comision.toStringAsFixed(2)} $monedaSymbol',
                style: GoogleFonts.plusJakartaSans(
                  color: esInvitacion ? const Color(0xFF00F0FF) : const Color(0xFFFF4081),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                esInvitacion
                    ? 'Invitada'
                    : '$cantidad x ${(comision / cantidad).toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white24,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatItemTime(String? dateStr) {
    if (dateStr == null) return '--:--';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--:--';
    }
  }
}
