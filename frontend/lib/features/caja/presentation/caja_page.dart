import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/caja_model.dart';
import '../providers/caja_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';

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
    final theme = Theme.of(context);
    final cajaState = ref.watch(cajaStateProvider);
    final historyAsync = ref.watch(cajaHistoryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121214), // Midnight background
      body: cajaState.when(
        data: (estado) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // PANEL CENTRAL ACTIVO (APERTURA O CIERRE)
                // ==========================================
                estado.abierta
                    ? _buildOpenCajaPanel(estado.caja!, theme, currencySymbol)
                    : _buildClosedCajaPanel(theme, currencySymbol),

                const SizedBox(height: 32),

                // ==========================================
                // HISTORIAL DE AUDITORÍA DE CAJAS
                // ==========================================
                _buildHistorySection(historyAsync, theme, currencySymbol),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
        ),
        error: (err, stack) => Center(
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
    );
  }

  // =========================================================================
  // 🚪 1. PANEL DE CAJA CERRADA (FORMULARIO APERTURA)
  // =========================================================================
  Widget _buildClosedCajaPanel(ThemeData theme, String currencySymbol) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024), // surface-container
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAJA OPERATIVA CERRADA',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Debe abrir un turno para iniciar ventas y comisiones.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Entrada de dinero inicial con calculadora de billetes
          Text(
            'Efectivo Inicial en Gaveta (Fondo de Caja)',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282A30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Text(
                          currencySymbol,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF00F0FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón de Billeteo Táctil
              InkWell(
                onTap: () => _openBilleteoCalculator(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7000FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7000FF).withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.calculate, color: Color(0xFF00F0FF), size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Botón Confirmar Apertura
          InkWell(
            onTap: _isLoading ? null : _handleApertura,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'ABRIR CAJA REGISTRADORA',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 🔓 2. PANEL DE CAJA ABIERTA (DATOS Y FORMULARIO DE CIERRE)
  // =========================================================================
  Widget _buildOpenCajaPanel(CajaModel caja, ThemeData theme, String currencySymbol) {
    final String barmanNombre = caja.aperturaUsuario != null
        ? caja.aperturaUsuario!.nombre
        : 'Barman Encargado';

    final String fecha = DateFormat('dd/MM/yyyy • hh:mm a').format(caja.fechaApertura.toLocal());

    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open, color: Color(0xFF00F0FF), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAJA OPERATIVA ABIERTA',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Turno iniciado por $barmanNombre',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          // Metadatos del turno activo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inicio de turno:',
                style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13),
              ),
              Text(
                fecha,
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Efectivo Inicial:',
                style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13),
              ),
              Text(
                '$currencySymbol ${caja.montoInicial.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 24),

          // Formulario de arqueo final para cierre
          Text(
            'ARQUEO DE CIERRE: Efectivo Físico en Gaveta',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF282A30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Text(
                          currencySymbol,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFFF00D6),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón de Billeteo Táctil
              InkWell(
                onTap: () => _openBilleteoCalculator(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF00D6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF00D6).withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.calculate, color: Color(0xFFFF00D6), size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Botón Arqueo y Cierre
          InkWell(
            onTap: _isLoading ? null : () => _handleCierre(caja.id),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7000FF), Color(0xFFFF00D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF00D6).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'ARQUEAR Y CERRAR TURNO',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 📚 3. SECCIÓN HISTORIAL DE TURNOS CERRADOS
  // =========================================================================
  Widget _buildHistorySection(AsyncValue<List<CajaModel>> historyAsync, ThemeData theme, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de Turnos y Arqueos',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2024),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No hay registros de turnos anteriores.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 13),
                  ),
                ),
              );
            }

            // Excluir la caja que actualmente esté abierta
            final closedHistory = history.where((c) => c.estado == 'CERRADA').toList();

            if (closedHistory.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2024),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No hay arqueos anteriores finalizados.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: closedHistory.length,
              itemBuilder: (context, index) {
                final item = closedHistory[index];
                final String fApertura = DateFormat('dd/MM/yyyy • hh:mm a').format(item.fechaApertura.toLocal());
                final String cerradoPor = item.cierreUsuario != null
                    ? item.cierreUsuario!.nombre
                    : 'Encargado';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2024),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.03), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cerrado por: $cerradoPor',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Apertura: $fApertura',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white30,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Arqueo: $currencySymbol ${item.montoFinal?.toStringAsFixed(2) ?? '0.00'}',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF00F0FF),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Inicial: $currencySymbol ${item.montoInicial.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
          error: (err, stack) => Text('Error al cargar historial', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  // =========================================================================
  // ⚡ GESTIÓN DE ACCIONES: APERTURA Y CIERRE
  // =========================================================================

  Future<void> _handleApertura() async {
    final String text = _montoController.text.trim();
    final double monto = text.isEmpty ? 0.0 : (double.tryParse(text) ?? -1.0);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Caja abierta con éxito.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: const Color(0xFF7000FF),
        ),
      );
      ref.invalidate(cajaHistoryProvider); // Refrescar historial
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: AppTheme.colorDanger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCierre(String cajaId) async {
    final String text = _montoController.text.trim();
    final double monto = text.isEmpty ? 0.0 : (double.tryParse(text) ?? -1.0);
    if (monto < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monto final inválido.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: AppTheme.colorDanger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final summary = await ref.read(cajaStateProvider.notifier).cerrarCaja(monto);
      _montoController.clear();
      ref.invalidate(cajaHistoryProvider); // Refrescar historial

      // Mostrar el hermoso reporte neon de cierre final
      _showCierreSummaryDialog(summary['resumen'] ?? summary);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: AppTheme.colorDanger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  // 💴 CALCULADORA DE BILLETEO INTEGRADA (Denominaciones de Caja)
  // =========================================================================
  void _openBilleteoCalculator() {
    final currencySymbol = ref.read(currencySymbolProvider);
    final customController = TextEditingController();

    // Denominaciones iniciales típicas según moneda/país
    final List<int> initialDenominaciones = currencySymbol.contains('Bs')
        ? [10, 20, 50, 100, 200]
        : (currencySymbol.contains('USD') || currencySymbol.contains('\$')
            ? [1, 2, 5, 10, 20, 50, 100]
            : [10, 20, 50, 100, 200, 500, 1000]);

    final List<int> denominaciones = List<int>.from(initialDenominaciones);
    final Map<int, int> conteo = {for (var d in denominaciones) d: 0};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double total = conteo.entries.fold(0.0, (sum, entry) => sum + (entry.key * entry.value));

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E2024),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Billeteo / Caja Arqueadora',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                        onPressed: () {
                          customController.dispose();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cuenta cuántos billetes físicos tienes en gaveta por denominación.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 11),
                  ),
                  const SizedBox(height: 20),

                  // Lista de denominaciones
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView(
                      physics: const ClampingScrollPhysics(),
                      shrinkWrap: true,
                      children: denominaciones.map((val) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              // Etiqueta Denominación
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '$currencySymbol $val',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF00F0FF),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Icon(Icons.close, color: Colors.white24, size: 12),
                              const SizedBox(width: 16),

                              // Caja de Texto para cantidad de billetes
                              Expanded(
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF282A30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      hintStyle: TextStyle(color: Colors.white24),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.only(bottom: 8),
                                    ),
                                    onChanged: (text) {
                                      final int cant = int.tryParse(text) ?? 0;
                                      setModalState(() {
                                        conteo[val] = cant;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Subtotal denominación
                              SizedBox(
                                width: 100,
                                child: Text(
                                  '$currencySymbol ${(val * conteo[val]!).toStringAsFixed(2)}',
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Agregar denominación personalizada
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF282A30),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.04), width: 1),
                            ),
                            child: TextField(
                              controller: customController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'Agregar otro corte de billete/moneda...',
                                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 11),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(bottom: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            final int? val = int.tryParse(customController.text);
                            if (val != null && val > 0 && !denominaciones.contains(val)) {
                              setModalState(() {
                                denominaciones.add(val);
                                denominaciones.sort();
                                conteo[val] = 0;
                              });
                              customController.clear();
                            }
                          },
                          icon: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: Text(
                            'Añadir',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F0FF).withOpacity(0.15),
                            side: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.4), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 24),

                  // Cómputo Total en Tiempo Real
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL SUMADO:',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$currencySymbol ${total.toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF00F0FF),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Botón Aplicar a formulario
                  ElevatedButton(
                    onPressed: () {
                      _montoController.text = total.toStringAsFixed(2);
                      customController.dispose();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7000FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'APLICAR TOTAL A GAVETA',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 📈 4. DIÁLOGO RESUMEN DE CIERRE FINANCIERO (NEON MODAL)
  // =========================================================================
  void _showCierreSummaryDialog(Map<String, dynamic> res) {
    final currencySymbol = ref.read(currencySymbolProvider);
    // Parseo seguro de los decimales de la API de NestJS
    final double mInicial = double.tryParse(res['monto_inicial']?.toString() ?? '') ?? 0.0;
    final double mFinal = double.tryParse(res['monto_final']?.toString() ?? '') ?? 0.0;
    final double vTotales = double.tryParse(res['ventas_totales']?.toString() ?? '') ?? 0.0;
    final double comisiones = double.tryParse(res['comisiones_pagadas']?.toString() ?? '') ?? 0.0;
    final double esperado = double.tryParse(res['balance_esperado']?.toString() ?? '') ?? 0.0;
    final double diferencia = double.tryParse(res['diferencia']?.toString() ?? '') ?? 0.0;
    final List<dynamic> desgloseRaw = res['desglose_pagos'] as List? ?? [];

    final bool tieneDiscrepancia = diferencia.abs() > 0.01;
    final Color colorDiscrepancia = diferencia >= 0 ? Colors.greenAccent : Colors.redAccent;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFF00D6).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF00D6).withOpacity(0.1),
                        border: Border.all(color: const Color(0xFFFF00D6).withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFFFF00D6),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'RESUMEN FINANCIERO DE CIERRE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Desglose de saldos
                  _buildSummaryRow('Dinero Inicial:', '$currencySymbol ${mInicial.toStringAsFixed(2)}', Colors.white54),
                  _buildSummaryRow('(+) Ventas Totales:', '$currencySymbol ${vTotales.toStringAsFixed(2)}', const Color(0xFF00F0FF)),
                  _buildSummaryRow('(-) Comisiones Damas:', '$currencySymbol ${comisiones.toStringAsFixed(2)}', const Color(0xFFFF00D6)),
                  const Divider(color: Colors.white10, height: 16),
                  _buildSummaryRow('(=) Balance Esperado:', '$currencySymbol ${esperado.toStringAsFixed(2)}', Colors.white),
                  _buildSummaryRow('(=) Dinero Físico en Gaveta:', '$currencySymbol ${mFinal.toStringAsFixed(2)}', Colors.white),
                  
                  if (desgloseRaw.isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 16),
                    Text(
                      'DESGLOSE POR MÉTODOS DE PAGO:',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF00F0FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...desgloseRaw.map((item) {
                      final String metodo = item['metodo']?.toString() ?? 'DESCONOCIDO';
                      final double totalMetodo = double.tryParse(item['total']?.toString() ?? '') ?? 0.0;
                      final int cantidad = int.tryParse(item['cantidad']?.toString() ?? '') ?? 0;

                      String label = metodo;
                      IconData icon = Icons.payment;
                      Color color = Colors.white70;
                      if (metodo == 'EFECTIVO') {
                        label = 'Efectivo';
                        icon = Icons.payments;
                        color = const Color(0xFF00FF87);
                      } else if (metodo == 'TARJETA') {
                        label = 'Tarjeta (Voucher)';
                        icon = Icons.credit_card;
                        color = const Color(0xFF00F0FF);
                      } else if (metodo == 'QR') {
                        label = 'Transferencia / QR';
                        icon = Icons.qr_code;
                        color = const Color(0xFFFF00D6);
                      } else if (metodo == 'MIXTO') {
                        label = 'Pago Mixto';
                        icon = Icons.account_balance_wallet;
                        color = const Color(0xFFFFC107);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(icon, size: 14, color: color.withOpacity(0.6)),
                                const SizedBox(width: 8),
                                Text(
                                  '$label ($cantidad vtas):',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            Text(
                              '$currencySymbol ${totalMetodo.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],

                  const Divider(color: Colors.white10, height: 16),

                  // Faltante o Sobrante
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DISCREPANCIA (Arqueo):',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        tieneDiscrepancia
                            ? (diferencia >= 0
                                ? '(+) $currencySymbol ${diferencia.toStringAsFixed(2)} (Sobrante)'
                                : '(-) $currencySymbol ${diferencia.abs().toStringAsFixed(2)} (Faltante)')
                            : '$currencySymbol 0.00 (Caja Cuadrada)',
                        style: GoogleFonts.plusJakartaSans(
                          color: colorDiscrepancia,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón Aceptar y finalizar
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7000FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'CONCLUIR Y RETORNAR',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: valColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
