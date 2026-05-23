import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_helper.dart';
import '../../admin/providers/bar_provider.dart';
import '../models/caja_model.dart';
import '../providers/caja_provider.dart';
import '../repository/caja_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/local_db/hive_entities/sync_queue_hive.dart';
import '../../../core/local_db/hive_provider.dart'; // import syncWorkerProvider

class CajaPage extends ConsumerStatefulWidget {
  const CajaPage({super.key});

  @override
  ConsumerState<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends ConsumerState<CajaPage> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _movMontoCtrl = TextEditingController();
  final TextEditingController _movConceptoCtrl = TextEditingController();
  bool _isLoading = false;
  String _selectedMetodoPago = 'EFECTIVO';

  @override
  void dispose() {
    _montoController.dispose();
    _movMontoCtrl.dispose();
    _movConceptoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cajaState = ref.watch(cajaStateProvider);
    final historyAsync = ref.watch(cajaHistoryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121214), // Midnight background
      body: cajaState.when(
        data: (estado) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0), // Paddings coincidentes con POS/Menú
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ==========================================
                // PANEL CENTRAL ACTIVO (APERTURA O CIERRE)
                // ==========================================
                estado.abierta
                    ? _buildOpenCajaPanel(estado.caja!, theme, currencySymbol, currencyIso)
                    : _buildClosedCajaPanel(theme, currencySymbol, currencyIso),

                const SizedBox(height: 24),

                // ==========================================
                // HISTORIAL DE AUDITORÍA DE CAJAS CERRADAS
                // ==========================================
                _buildHistorySection(historyAsync, theme, currencySymbol, currencyIso),
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
  // 📚 1. PANEL DE CAJA CERRADA (Apertura Obligatoria y Sin Billeteo)
  // =========================================================================
  Widget _buildClosedCajaPanel(ThemeData theme, String currencySymbol, String currencyIso) {
    return Container(
      padding: const EdgeInsets.all(24.0),
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
                      'CAJA CERRADA',
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
          const SizedBox(height: 24),

          // Entrada de dinero inicial obligatoria
          Text(
            'Efectivo inicial en gaveta.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF282A30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                CurrencyInputFormatter(iso: currencyIso),
              ],
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Ingresa 0 si abres con gaveta vacía',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 13),
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
          const SizedBox(height: 24),

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
                        'ABRIR CAJA',
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
  // 📚 2. PANEL DE CAJA ABIERTA (Desglose de 9 Métricas, Caja Chica y Bitácora)
  // =========================================================================
  Widget _buildOpenCajaPanel(CajaModel caja, ThemeData theme, String currencySymbol, String currencyIso) {
    final String barmanNombre = caja.aperturaUsuario != null
        ? caja.aperturaUsuario!.nombre
        : 'Barman Encargado';

    final String fecha = DateFormat('dd/MM/yyyy • hh:mm a').format(caja.fechaApertura.toLocal());
    final bool isTablet = MediaQuery.of(context).size.width >= 750;

    // Construir Bento Grid de 9 Métricas
    final List<Widget> cards = [
      _buildFinancieraCard('Fondo de Caja (Inicial)', caja.montoInicial, currencySymbol, const Color(0xFF00F0FF), currencyIso),
      _buildFinancieraCard('Ventas Efectivo POS', caja.totalVentasEfectivo, currencySymbol, Colors.white70, currencyIso),
      _buildFinancieraCard('Ventas Tarjeta POS', caja.totalVentasTarjeta, currencySymbol, Colors.white70, currencyIso),
      _buildFinancieraCard('Ventas TR / QR POS', caja.totalVentasTrQr, currencySymbol, Colors.white70, currencyIso),
      _buildFinancieraCard('Ingresos Manuales', caja.totalIngresosManuales, currencySymbol, const Color(0xFF00FF66), currencyIso),
      _buildFinancieraCard('Egresos Caja Chica', caja.totalEgresosManuales, currencySymbol, Colors.redAccent, currencyIso),
      _buildFinancieraCard('Total Esperado en Gaveta', caja.totalEsperadoGaveta, currencySymbol, const Color(0xFF00F0FF), currencyIso, isImportant: true),
      _buildFinancieraCard(
        'Comisiones Damas',
        caja.totalComisionesDamas,
        currencySymbol,
        const Color(0xFFFF00D6),
        currencyIso,
        onTap: () => _openDamasBreakdownBottomSheet(caja.id),
      ),
      _buildFinancieraCard('Ganancia Neta del Bar', caja.gananciaNetaBar, currencySymbol, const Color(0xFF7000FF), currencyIso, isHighlighted: true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ficha del turno superior
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_open, color: Color(0xFF00F0FF), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAJA ABIERTA',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Iniciado por $barmanNombre • $fecha',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón Único de Cierre Sin Inputs
              InkWell(
                onTap: _isLoading ? null : () => _showCierreConfirmationBottomSheet(caja.id),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7000FF), Color(0xFFFF00D6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF00D6).withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'CERRAR CAJA',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Bento Grid de Métricas
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isTablet ? 2.3 : 1.9,
          ),
          itemBuilder: (context, index) => cards[index],
        ),

        const SizedBox(height: 20),

        // PANEL DE CAJA CHICA (Ingresos y Egresos Manuales)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CAJA CHICA / OPERACIONES MANUALES',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('INGRESO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF66).withOpacity(0.1),
                        foregroundColor: const Color(0xFF00FF66),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: const Color(0xFF00FF66).withOpacity(0.3)),
                        ),
                      ),
                      onPressed: () => _openAddMovementBottomSheet('INGRESO'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('EGRESO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                      ),
                      onPressed: () => _openAddMovementBottomSheet('EGRESO'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // BITÁCORA DE MOVIMIENTOS EN VIVO
        _buildMovimientosList(caja.movimientos, currencySymbol, currencyIso),
      ],
    );
  }

  // =========================================================================
  // 💴 WIDGET DE TARJETA FINANCIERA BENTO
  // =========================================================================
  Widget _buildFinancieraCard(
    String title,
    double amount,
    String currency,
    Color accentColor,
    String currencyIso, {
    bool isImportant = false,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    final formatted = CurrencyHelper.formatAmount(amount, currencyIso);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isHighlighted
                ? const Color(0xFF7000FF).withOpacity(0.08)
                : const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFF7000FF).withOpacity(0.4)
                  : (isImportant
                      ? const Color(0xFF00F0FF).withOpacity(0.3)
                      : Colors.white.withOpacity(0.03)),
              width: isHighlighted || isImportant ? 1.5 : 1,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: const Color(0xFF7000FF).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFFF00D6)),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$currency $formatted',
                  style: GoogleFonts.plusJakartaSans(
                    color: accentColor,
                    fontSize: isImportant || isHighlighted ? 18 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 📚 3. BITÁCORA DE MOVIMIENTOS EN VIVO
  // =========================================================================
  Widget _buildMovimientosList(List<CajaMovimientoModel> movimientos, String symbol, String iso) {
    if (movimientos.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Center(
          child: Text(
            'Sin movimientos de caja chica registrados en este turno.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 11),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'BITÁCORA DE CAJA CHICA (TURNO ABIERTO)',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: movimientos.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final m = movimientos[index];
              final bool isIngreso = m.tipo == 'INGRESO';
              final time = DateFormat('hh:mm a').format(m.createdAt.toLocal());
              final formattedMonto = CurrencyHelper.formatAmount(m.monto, iso);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isIngreso
                            ? const Color(0xFF00FF66).withOpacity(0.1)
                            : Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.concepto,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Vía ${m.metodoPago} • $time por ${m.usuario?.nombre ?? 'Cajero'}',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isIngreso ? '+' : '-'} $symbol $formattedMonto',
                      style: GoogleFonts.plusJakartaSans(
                        color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 📚 4. MODAL BOTTOM SHEET DE CAJA CHICA (Ingreso / Egreso)
  // =========================================================================
  void _openAddMovementBottomSheet(String tipo) {
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);
    _movMontoCtrl.clear();
    _movConceptoCtrl.clear();
    _selectedMetodoPago = 'EFECTIVO';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        'Registrar ${tipo == 'INGRESO' ? 'Ingreso de Caja Chica' : 'Egreso / Pago de Turno'}',
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
                  const SizedBox(height: 16),

                  // Input de Monto
                  Text(
                    'Monto del Movimiento',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF282A30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _movMontoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        CurrencyInputFormatter(iso: currencyIso),
                      ],
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: Colors.white24),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          child: Text(
                            currencySymbol,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00F0FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selector de Método de Pago
                  Text(
                    'Método de Pago / Canal',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: ['EFECTIVO', 'TARJETA', 'TRANSFERENCIA'].map((metodo) {
                      final bool isSelected = _selectedMetodoPago == metodo;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () {
                              setModalState(() => _selectedMetodoPago = metodo);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF00F0FF).withOpacity(0.1)
                                    : const Color(0xFF282A30),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF00F0FF) : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  metodo,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Input de Concepto / Motivo
                  Text(
                    'Concepto / Descripción del Movimiento',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF282A30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _movConceptoCtrl,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ej. Compra de limones, Pago de luz, Cambio...',
                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón de Confirmación
                  ElevatedButton(
                    onPressed: () async {
                      final textMonto = _movMontoCtrl.text.trim();
                      final textConcepto = _movConceptoCtrl.text.trim();
                      if (textMonto.isEmpty || textConcepto.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚠️ Por favor completa el monto y el concepto.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                            backgroundColor: AppTheme.colorDanger,
                          ),
                        );
                        return;
                      }

                      final double montoDouble = CurrencyHelper.parseAmount(textMonto, currencyIso);
                      if (montoDouble <= 0) return;

                      Navigator.pop(context); // Cerrar bottom sheet

                      setState(() => _isLoading = true);
                      try {
                        await ref.read(cajaStateProvider.notifier).registrarMovimiento(
                              monto: montoDouble,
                              tipo: tipo,
                              metodoPago: _selectedMetodoPago,
                              concepto: textConcepto,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ Movimiento registrado correctamente.', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                            backgroundColor: const Color(0xFF7000FF),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚠️ Error: ${e.toString().replaceAll('Exception: ', '')}', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                            backgroundColor: AppTheme.colorDanger,
                          ),
                        );
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7000FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'CONFIRMAR MOVIMIENTO',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
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
  // 📚 5. MODAL BOTTOM SHEET DE DESGLOSE DE DAMAS (Comisiones del Turno)
  // =========================================================================
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

              // Consulta en caliente agregada desde el servidor
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

  // =========================================================================
  // 📚 6. MODAL BOTTOM SHEET DE CONFIRMACIÓN DE CIERRE (Bloqueo e Intento de Sync)
  // =========================================================================
  void _showCierreConfirmationBottomSheet(String cajaId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Verificar cola de sincronización de Hive
            final syncBox = Hive.box<SyncQueueTaskHive>('sync_queue');
            final bool hasUnsynced = syncBox.isNotEmpty;

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
                        'Confirmar Cierre de Turno',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Esta acción dará por finalizado el turno activo actual de la caja. El sistema registrará los balances y comisiones generadas de forma automática.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  if (hasUnsynced) ...[
                    // Bloqueo de seguridad dinámico con botón para sincronizar ahora
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.colorDanger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.colorDanger.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppTheme.colorDanger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'BLOQUEO DE SEGURIDAD',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.colorDanger,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tienes ${syncBox.length} pedido(s) cobrados localmente que aún no suben al servidor. Debes estar conectado a internet y sincronizarlos antes de poder cerrar el turno.',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.sync, size: 16),
                            label: const Text('INTENTAR SINCRONIZAR AHORA'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.colorDanger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setModalState(() => _isLoading = true);
                                    try {
                                      final syncWorker = ref.read(syncWorkerProvider);
                                      await syncWorker.processQueue();
                                    } catch (_) {
                                    } finally {
                                      setModalState(() => _isLoading = false);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Botones de Acción
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          child: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasUnsynced ? Colors.white10 : const Color(0xFF7000FF),
                            foregroundColor: hasUnsynced ? Colors.white24 : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: hasUnsynced || _isLoading
                              ? null
                              : () {
                                  Navigator.pop(context); // Cerrar bottom sheet
                                  _handleCierre(cajaId);
                                },
                          child: Text('CONFIRMAR CIERRE', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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
  // ⚡ GESTIÓN DE ACCIONES EN CALIENTE: APERTURA Y CIERRE
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
    setState(() => _isLoading = true);

    try {
      final summary = await ref.read(cajaStateProvider.notifier).cerrarCaja();
      ref.invalidate(cajaHistoryProvider); // Refrescar historial

      // Mostrar el hermoso reporte neon de cierre final
      _showCierreSummaryDialog(summary['resumen'] ?? summary);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Error al cerrar caja: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          backgroundColor: AppTheme.colorDanger,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =========================================================================
  // 📚 7. HISTORIAL DE CAJAS CERRADAS (Turnos Archivados)
  // =========================================================================
  Widget _buildHistorySection(AsyncValue<List<CajaModel>> historyAsync, ThemeData theme, String currencySymbol, String currencyIso) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HISTORIAL DE TURNOS CERRADOS',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          historyAsync.when(
            data: (list) {
              final closedList = list.where((c) => c.estado == 'CERRADA').toList();
              if (closedList.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'No hay turnos cerrados en el historial de este bar.',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 11),
                    ),
                  ),
                );
              }

              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: closedList.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final item = closedList[index];
                  final String barman = item.aperturaUsuario != null ? item.aperturaUsuario!.nombre : 'Cajero';
                  final String fechaApertura = DateFormat('dd/MM/yyyy • hh:mm a').format(item.fechaApertura.toLocal());
                  final String formattedMonto = CurrencyHelper.formatAmount(item.montoFinal ?? 0.0, currencyIso);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.archive_outlined, color: Colors.white30, size: 20),
                    ),
                    title: Text(
                      'Turno cerrado de $barman',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      fechaApertura,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 10),
                    ),
                    trailing: Text(
                      '$currencySymbol $formattedMonto',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF00F0FF),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
            error: (err, _) => Text('Error al cargar historial: $err', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 📚 8. REPORTE FINAL NEON DE CIERRE DE CAJA (Resumen Financiero)
  // =========================================================================
  void _showCierreSummaryDialog(dynamic resumen) {
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);

    final mInicial = (resumen['monto_inicial'] as num?)?.toDouble() ?? 0.0;
    final mFinal = (resumen['monto_final'] as num?)?.toDouble() ?? 0.0;
    final vTotales = (resumen['ventas_totales'] as num?)?.toDouble() ?? 0.0;
    final comisiones = (resumen['comisiones_pagadas'] as num?)?.toDouble() ?? 0.0;
    final ingresos = (resumen['ingresos_manuales'] as num?)?.toDouble() ?? 0.0;
    final egresos = (resumen['egresos_manuales'] as num?)?.toDouble() ?? 0.0;
    final esperado = (resumen['balance_esperado'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2024),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF00F0FF), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TURNO CERRADO',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Resumen Financiero del Sistema',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  // Desglose de saldos final
                  _buildSummaryRow('Dinero Inicial (Fondo):', '$currencySymbol ${CurrencyHelper.formatAmount(mInicial, currencyIso)}', Colors.white54),
                  _buildSummaryRow('(+) Ventas Totales POS:', '$currencySymbol ${CurrencyHelper.formatAmount(vTotales, currencyIso)}', const Color(0xFF00F0FF)),
                  _buildSummaryRow('(+) Ingresos Manuales:', '$currencySymbol ${CurrencyHelper.formatAmount(ingresos, currencyIso)}', const Color(0xFF00FF66)),
                  _buildSummaryRow('(-) Egresos Manuales:', '$currencySymbol ${CurrencyHelper.formatAmount(egresos, currencyIso)}', Colors.redAccent),
                  _buildSummaryRow('(-) Comisiones Damas:', '$currencySymbol ${CurrencyHelper.formatAmount(comisiones, currencyIso)}', const Color(0xFFFF00D6)),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  _buildSummaryRow('Dinero Total Entregado:', '$currencySymbol ${CurrencyHelper.formatAmount(esperado, currencyIso)}', Colors.white, isTotal: true),

                  const SizedBox(height: 28),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7000FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('ENTENDIDO', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valColor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isTotal ? Colors.white : Colors.white30,
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: valColor,
              fontWeight: FontWeight.w900,
              fontSize: isTotal ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
