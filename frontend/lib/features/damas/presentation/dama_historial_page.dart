import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../core/utils/currency_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../providers/dama_provider.dart';
import '../../caja/models/evento_movimiento.dart';
import '../../caja/models/venta_model.dart';
import '../../caja/presentation/dialogs/movement_detail_bottom_sheet.dart';
import '../../caja/providers/caja_provider.dart';
import '../../admin/providers/bar_provider.dart';

class DamaHistorialPage extends ConsumerStatefulWidget {
  const DamaHistorialPage({super.key});

  @override
  ConsumerState<DamaHistorialPage> createState() => _DamaHistorialPageState();
}

class _DamaHistorialPageState extends ConsumerState<DamaHistorialPage> {
  String _activeTab = 'REGISTRO'; // REGISTRO, DIARIO
  String _activeFilter = 'TODO'; // TODO, COMISION, INVITACION

  Future<void> _openVentaDetail(String ventaId) async {
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

  void _openDayDetailsBottomSheet(String dateStr, String formattedDate, List<dynamic> allHistory) {
    // Filtrar los consumos que correspondan al día seleccionado (YYYY-MM-DD)
    final dayLogs = allHistory.where((item) {
      return item['fecha']?.toString().startsWith(dateStr) == true;
    }).toList();

    const accentColor = Color(0xFFFF4081);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E2024),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DESGLOSE DE CONSUMOS',
                style: GoogleFonts.plusJakartaSans(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: dayLogs.isEmpty
                    ? Center(
                        child: Text(
                          'No hay registros para este día',
                          style: TextStyle(color: Colors.white30, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: dayLogs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = dayLogs[index];
                          return _buildDayDetailCard(item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayDetailCard(dynamic item) {
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
        onTap: ventaId != null && ventaId.isNotEmpty
            ? () {
                Navigator.pop(context); // Cerrar bottom sheet de desglose diario
                _openVentaDetail(ventaId);
              }
            : null,
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

  @override
  Widget build(BuildContext context) {
    final comisionesState = ref.watch(damaComisionesProvider);
    final diarioState = ref.watch(damaHistorialDiarioProvider);
    const accentColor = Color(0xFFFF4081);

    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segment selector at top
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              children: [
                Expanded(child: _buildTabButton('Registro de Consumos', 'REGISTRO')),
                const SizedBox(width: 12),
                Expanded(child: _buildTabButton('Resumen Diario', 'DIARIO')),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 'REGISTRO'
                ? _buildRegistroView(comisionesState)
                : _buildDiarioView(diarioState, comisionesState.historial),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String tab) {
    final bool isActive = _activeTab == tab;
    const accentColor = Color(0xFFFF4081);

    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? accentColor.withOpacity(0.12) : const Color(0xFF16181C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? accentColor.withOpacity(0.35) : Colors.white.withOpacity(0.04),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isActive ? accentColor : Colors.white60,
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRegistroView(DamaComisionesState comisionesState) {
    // Filtrar historial
    final filteredHistory = comisionesState.historial.where((item) {
      final bool esInvitacion = item['es_invitacion'] == true;
      if (_activeFilter == 'COMISION') return !esInvitacion;
      if (_activeFilter == 'INVITACION') return esInvitacion;
      return true;
    }).toList();

    const accentColor = Color(0xFFFF4081);

    return RefreshIndicator(
      color: accentColor,
      backgroundColor: const Color(0xFF1E2024),
      onRefresh: () => ref.read(damaComisionesProvider.notifier).loadComisiones(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // Filtros rápidos
          Row(
            children: [
              _buildFilterButton('Todos', 'TODO'),
              const SizedBox(width: 8),
              _buildFilterButton('Comisiones', 'COMISION'),
              const SizedBox(width: 8),
              _buildFilterButton('Invitaciones', 'INVITACION'),
            ],
          ),
          const SizedBox(height: 16),

          if (comisionesState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(color: accentColor),
              ),
            )
          else if (comisionesState.error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  'Error: ${comisionesState.error}',
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
                    'No se encontraron registros',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Las bebidas e invitaciones registradas aparecerán aquí.',
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
                return _buildCommissionItemCard(item, comisionesState.moneda);
              },
            ),
          const SizedBox(height: 20),
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

  Widget _buildDiarioView(DamaHistorialDiarioState diarioState, List<dynamic> allHistory) {
    const accentColor = Color(0xFFFF4081);

    return RefreshIndicator(
      color: accentColor,
      backgroundColor: const Color(0xFF1E2024),
      onRefresh: () => ref.read(damaHistorialDiarioProvider.notifier).loadHistorialDiario(),
      child: diarioState.isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(color: accentColor),
              ),
            )
          : diarioState.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'Error: ${diarioState.error}',
                      style: TextStyle(color: Colors.redAccent.shade100, fontSize: 13),
                    ),
                  ),
                )
              : diarioState.historialDiario.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(32.0),
                      children: [
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
                              const Icon(Icons.history_toggle_off_outlined, color: Colors.white12, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                'No hay historial diario cerrado',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cuando se cierren turnos en el bar, los acumulados diarios de tus comisiones aparecerán aquí.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white24,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: diarioState.historialDiario.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = diarioState.historialDiario[index];
                        return _buildDiarioItemCard(item, allHistory);
                      },
                    ),
    );
  }

  Widget _buildDiarioItemCard(dynamic item, List<dynamic> allHistory) {
    final String dateStr = item['fecha']?.toString() ?? '2026-07-04';
    final String formattedDate = _formatCalendarDate(dateStr);
    final double comisionDiaria = (item['total_comisiones'] as num?)?.toDouble() ?? 0.0;
    final int invitacionesDiarias = (item['total_invitaciones'] as num?)?.toInt() ?? 0;

    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);
    const accentColor = Color(0xFFFF4081);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDayDetailsBottomSheet(dateStr, formattedDate, allHistory),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF16181C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$invitacionesDiarias ${invitacionesDiarias == 1 ? "bebida invitada" : "bebidas invitadas"}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currencySymbol ${CurrencyHelper.formatAmount(comisionDiaria, currencyIso)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: accentColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Consolidado',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white12,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
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

  String _formatCalendarDate(String? dateStr) {
    if (dateStr == null) return 'Desconocido';
    try {
      final parts = dateStr.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final dt = DateTime(year, month, day);
      final dayName = DateFormat('EEEE', 'es').format(dt);
      final monthName = DateFormat('MMMM', 'es').format(dt);
      return '${dayName[0].toUpperCase()}${dayName.substring(1)}, $day de ${monthName[0].toUpperCase()}${monthName.substring(1)}';
    } catch (_) {
      return dateStr;
    }
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
