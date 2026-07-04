import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/utils/currency_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../providers/dama_provider.dart';
import '../../dashboard/presentation/widgets/dashboard_session_card.dart';
import '../../admin/providers/bar_provider.dart';
import '../../caja/models/evento_movimiento.dart';
import '../../caja/models/venta_model.dart';
import '../../caja/providers/caja_provider.dart';
import '../../caja/presentation/dialogs/movement_detail_bottom_sheet.dart';

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

  Future<void> _openVentaDetail(String ventaId) async {
    // Mostrar cargando
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4081)),
      ),
    );

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/ventas/$ventaId');
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      
      if (mounted) Navigator.pop(context); // Cerrar cargando

      final VentaModel venta = VentaModel.fromJson(data);
      
      final ev = EventoMovimiento(
        id: venta.id,
        tipo: 'VENTA',
        monto: venta.total,
        fecha: venta.fecha,
        concepto: 'Ticket de Venta #${venta.id.substring(0, 8).toUpperCase()}',
        cajero: venta.usuario?.nombre ?? 'Desconocido',
        metodoPago: venta.metodoPago,
        original: venta,
      );

      final currencySymbol = ref.read(currencySymbolProvider);
      final currencyIso = ref.read(currencyIsoProvider);
      final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

      if (mounted) {
        if (isTabletLandscape) {
          showDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.85),
            builder: (context) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: MovementDetailBottomSheet(
                    ev: ev,
                    currencySymbol: currencySymbol,
                    currencyIso: currencyIso,
                    isDialog: true,
                  ),
                ),
              );
            },
          );
        } else {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) {
              return MovementDetailBottomSheet(
                ev: ev,
                currencySymbol: currencySymbol,
                currencyIso: currencyIso,
                isDialog: false,
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar cargando
        CustomToast.show(
          context,
          message: 'No se pudo abrir el detalle del ticket: ${e.toString().replaceAll('Exception: ', '')}',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(damaComisionesProvider);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final barState = ref.watch(currentBarProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    const accentColor = Color(0xFFFF4081); // Color oficial Rose / Pink de Dama

    final String barName = barState.when(
      data: (bar) => bar.nombre,
      loading: () => 'Cargando...',
      error: (_, __) => 'Error',
    );

    final cajaState = ref.watch(cajaStateProvider);
    final bool isCajaAbierta = cajaState.value?.abierta ?? false;

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
            // Banner de Sesión Activa (Unificado con el resto de roles)
            DashboardSessionCard(
              user: user,
              activeBarId: authState.activeBarId,
              barName: barName,
            ),
            const SizedBox(height: 16),

            if (!isCajaAbierta) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.amber.withOpacity(0.35), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Turno Cerrado',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'La caja operativa está cerrada. Solicita al cajero iniciar el turno para poder registrar bebidas y comisiones.',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11.0,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Bento Grid KPIs (2 Cards)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Comisiones Totales',
                    value: '$currencySymbol ${CurrencyHelper.formatAmount(state.comisionesTotales, currencyIso)}',
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
            const SizedBox(height: 12),

            // Historial Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ],
            ),
            const SizedBox(height: 6),

            // Filtros rápidos estilo Cápsulas Slim
            Row(
              children: [
                _buildFilterButton('Todos', 'TODO'),
                const SizedBox(width: 8),
                _buildFilterButton('Comisiones', 'COMISION'),
                const SizedBox(width: 8),
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
    final Color activeBg = isActive ? const Color(0xFFFF4081).withOpacity(0.12) : const Color(0xFF1E2024);
    final Color activeBorder = isActive ? const Color(0xFFFF4081).withOpacity(0.35) : Colors.white.withOpacity(0.04);
    final Color textColor = isActive ? const Color(0xFFFF4081) : Colors.white60;

    return InkWell(
      onTap: () => setState(() => _activeFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activeBorder, width: 0.8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: textColor,
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
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
    final String? ventaId = item['venta_id']?.toString();
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: ventaId != null && ventaId.isNotEmpty ? () => _openVentaDetail(ventaId) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                          esInvitacion ? 'Invitación' : 'Comisión',
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
                        ? '+$cantidad ${cantidad == 1 ? "bebida" : "bebidas"}'
                        : '+$currencySymbol ${CurrencyHelper.formatAmount(comision, currencyIso)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: esInvitacion ? const Color(0xFF00F0FF) : const Color(0xFFFF4081),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    esInvitacion
                        ? 'Invitación'
                        : '$cantidad x $currencySymbol ${CurrencyHelper.formatAmount(comision / cantidad, currencyIso)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white24,
                      fontSize: 9.5,
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
