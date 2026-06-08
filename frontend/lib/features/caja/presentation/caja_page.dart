import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/currency_helper.dart';
import '../../admin/providers/bar_provider.dart';
import '../models/caja_model.dart';
import '../models/evento_movimiento.dart';
import '../models/venta_model.dart';
import '../providers/caja_provider.dart';
import '../repository/caja_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/ventas_activas_provider.dart';
import 'widgets/closed_caja_panel.dart';
import 'widgets/open_caja_panel.dart';
import 'dialogs/cierre_confirmation_bottom_sheet.dart';
import 'dialogs/cierre_summary_dialog.dart';
import 'dialogs/add_movement_bottom_sheet.dart';
import 'dialogs/movement_detail_bottom_sheet.dart';
import 'package:gestobar/core/widgets/shimmer_placeholder.dart';

class CajaPage extends ConsumerStatefulWidget {
  const CajaPage({super.key});

  @override
  ConsumerState<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends ConsumerState<CajaPage> {
  final TextEditingController _montoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cajaState = ref.watch(cajaStateProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final ventasState = ref.watch(ventasActivasProvider);
    final List<VentaModel> activeVentas = ventasState.ventas;

    return Scaffold(
      backgroundColor: const Color(0xFF121214), // Midnight background
      body: RefreshIndicator(
        color: const Color(0xFF00F0FF),
        backgroundColor: const Color(0xFF1E2024),
        onRefresh: () async {
          await Future.wait([
            ref.read(cajaStateProvider.notifier).refreshEstado(silent: true),
            ref.read(ventasActivasProvider.notifier).refresh(),
          ]);
        },
        child: cajaState.when(
          data: (estado) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0), // Paddings coincidentes con POS/Menú
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  estado.abierta
                      ? OpenCajaPanel(
                          caja: estado.caja!,
                          activeVentas: activeVentas,
                          currencySymbol: currencySymbol,
                          currencyIso: currencyIso,
                          isLoading: _isLoading,
                          onCerrarCaja: _showCierreConfirmationBottomSheet,
                          onAddMovement: _openAddMovementBottomSheet,
                          onDamasBreakdown: _openDamasBreakdownBottomSheet,
                          onMovementDetail: _openMovementDetailBottomSheet,
                        )
                      : ClosedCajaPanel(
                          montoController: _montoController,
                          isLoading: _isLoading,
                          currencySymbol: currencySymbol,
                          currencyIso: currencyIso,
                          onAbrirCaja: _handleApertura,
                        ),
                ],
              ),
            );
          },
          loading: () {
            return const SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShimmerPlaceholder(
                    width: double.infinity,
                    height: 280,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                  ),
                  SizedBox(height: 12.0),
                  ShimmerPlaceholder(
                    width: double.infinity,
                    height: 420,
                    borderRadius: BorderRadius.all(Radius.circular(16.0)),
                  ),
                ],
              ),
            );
          },
          error: (err, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 150,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error al cargar estado de caja',
                      style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(cajaStateProvider.notifier).refreshEstado(),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7000FF)),
                      child: Text('Reintentar', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
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

  // =========================================================================
  // ⚡ ACCIONES: APERTURA Y CIERRE
  // =========================================================================

  Future<void> _handleApertura() async {
    final String text = _montoController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Por favor ingresa el monto inicial de gaveta (digita 0 si está vacía).', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppTheme.colorDanger,
        ),
      );
      return;
    }

    final String iso = ref.read(currencyIsoProvider);
    final double monto = CurrencyHelper.parseAmount(text, iso);
    if (monto < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monto inicial inválido.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: AppTheme.colorDanger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(cajaStateProvider.notifier).abrirCaja(monto);
      _montoController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Caja abierta con éxito.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: const Color(0xFF7000FF),
          ),
        );
      }
      ref.invalidate(cajaHistoryProvider); // Refrescar historial
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error: ${e.toString().replaceAll('Exception: ', '')}',
                style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: AppTheme.colorDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCierre(String cajaId) async {
    setState(() => _isLoading = true);

    try {
      final summary = await ref.read(cajaStateProvider.notifier).cerrarCaja();
      ref.invalidate(cajaHistoryProvider); // Refrescar historial

      // Mostrar el hermoso reporte neon de cierre final
      if (mounted) {
        _showCierreSummaryDialog(summary['resumen'] ?? summary);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error al cerrar caja: ${e.toString().replaceAll('Exception: ', '')}',
                style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: AppTheme.colorDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  // 📚 DIALOGS & BOTTOM SHEETS TRIGGERS
  // =========================================================================

  void _showCierreConfirmationBottomSheet(String cajaId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CierreConfirmationBottomSheet(
          cajaId: cajaId,
          onConfirm: () => _handleCierre(cajaId),
        );
      },
    );
  }

  void _showCierreSummaryDialog(dynamic resumen) {
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return CierreSummaryDialog(
          resumen: resumen,
          currencySymbol: currencySymbol,
          currencyIso: currencyIso,
        );
      },
    );
  }

  void _openAddMovementBottomSheet(String tipo) {
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddMovementBottomSheet(
          tipo: tipo,
          currencySymbol: currencySymbol,
          currencyIso: currencyIso,
          onConfirm: ({required monto, required metodoPago, required concepto}) async {
            await ref.read(cajaStateProvider.notifier).registrarMovimiento(
                  monto: monto,
                  tipo: tipo,
                  metodoPago: metodoPago,
                  concepto: concepto,
                );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Movimiento registrado correctamente.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                  backgroundColor: const Color(0xFF7000FF),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _openMovementDetailBottomSheet(EventoMovimiento ev) {
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MovementDetailBottomSheet(
          ev: ev,
          currencySymbol: currencySymbol,
          currencyIso: currencyIso,
        );
      },
    );
  }

  void _openDamasBreakdownBottomSheet(String cajaId) {
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E2024),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comisiones del Turno por Dama',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Corresponde a la suma individual de todas las ventas al precio de compañía en este turno.',
                style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 11),
              ),
              const SizedBox(height: 20),

              FutureBuilder<List<dynamic>>(
                future: ref.read(cajaRepositoryProvider).getDamaComisiones(cajaId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFFF00D6))),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'Error al obtener desglose: ${snapshot.error}',
                          style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    );
                  }

                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          'No hay comisiones de damas generadas en este turno.',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 12),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final name = item['nombre'] as String? ?? 'Dama';
                      final com = (item['total_comision'] as num?)?.toDouble() ?? 0.0;
                      final formattedCom = CurrencyHelper.formatAmount(com, currencyIso);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFFF00D6).withOpacity(0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                                style: const TextStyle(color: Color(0xFFFF00D6), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '$currencySymbol $formattedCom',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFFF00D6),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
