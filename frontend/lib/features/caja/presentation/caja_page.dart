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
import '../providers/ventas_activas_provider.dart';
import '../models/venta_model.dart';

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
  int _activeTab = 0;

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
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final ventasState = ref.watch(ventasActivasProvider);
    final List<VentaModel> activeVentas = ventasState.ventas;

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
                    ? _buildOpenCajaPanel(estado.caja!, activeVentas, theme, currencySymbol, currencyIso)
                    : _buildClosedCajaPanel(theme, currencySymbol, currencyIso),
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
              textAlignVertical: TextAlignVertical.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                CurrencyInputFormatter(iso: currencyIso),
              ],
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Ingresa 0 si abres con gaveta vacía',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 13),
                prefixIcon: Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    currencySymbol,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF00F0FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  maxWidth: 48,
                  minHeight: 48,
                  maxHeight: 48,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(right: 16),
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
  Widget _buildOpenCajaPanel(CajaModel caja, List<VentaModel> activeVentas, ThemeData theme, String currencySymbol, String currencyIso) {
    final String barmanNombre = caja.aperturaUsuario != null
        ? caja.aperturaUsuario!.nombre
        : 'Barman Encargado';

    final String fecha = DateFormat('dd/MM/yyyy • hh:mm a').format(caja.fechaApertura.toLocal());
    final bool isTablet = MediaQuery.of(context).size.width >= 750;

    final double totalVentasPos = caja.totalVentasEfectivo + caja.totalVentasTarjeta + caja.totalVentasTrQr;

    // Construir Bento Grid de 10 Métricas
    final List<Widget> cards = [
      _buildFinancieraCard('Fondo de Caja (Inicial)', caja.montoInicial, currencySymbol, const Color(0xFF00F0FF), currencyIso, Icons.account_balance_wallet_outlined),
      _buildFinancieraCard('Total Esperado en Gaveta', caja.totalEsperadoGaveta, currencySymbol, const Color(0xFF00F0FF), currencyIso, Icons.move_to_inbox_outlined),
      _buildFinancieraCard('Ventas Efectivo POS', caja.totalVentasEfectivo, currencySymbol, Colors.white70, currencyIso, Icons.payments_outlined),
      _buildFinancieraCard('Ventas Tarjeta POS', caja.totalVentasTarjeta, currencySymbol, Colors.white70, currencyIso, Icons.credit_card_outlined),
      _buildFinancieraCard('Ventas TR / QR POS', caja.totalVentasTrQr, currencySymbol, Colors.white70, currencyIso, Icons.mobile_friendly_outlined),
      _buildFinancieraCard('Ventas Totales POS', totalVentasPos, currencySymbol, const Color(0xFF00FF66), currencyIso, Icons.analytics_outlined),
      _buildFinancieraCard('Ganancia Neta del Bar', caja.gananciaNetaBar, currencySymbol, const Color(0xFF7000FF), currencyIso, Icons.trending_up_outlined),
      _buildFinancieraCard(
        'Comisiones Damas',
        caja.totalComisionesDamas,
        currencySymbol,
        const Color(0xFFFF00D6),
        currencyIso,
        Icons.female_outlined,
        onTap: () => _openDamasBreakdownBottomSheet(caja.id),
      ),
      _buildFinancieraCard('Ingresos Manuales', caja.totalIngresosManuales, currencySymbol, const Color(0xFF00FFCC), currencyIso, Icons.add_circle_outline),
      _buildFinancieraCard('Egresos Caja Chica', caja.totalEgresosManuales, currencySymbol, Colors.redAccent, currencyIso, Icons.remove_circle_outline),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Ficha del turno superior (Caja Abierta y Cerrar Caja)
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

              // Botón de Cierre
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

        const SizedBox(height: 16),

        // 2. Botones de Caja Chica Pill-Shaped Premium (sin parecer cards)
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openAddMovementBottomSheet('INGRESO'),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF66),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF66).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle, size: 16, color: Color(0xFF121214)),
                      const SizedBox(width: 8),
                      Text(
                        'INGRESO CHICA',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF121214),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _openAddMovementBottomSheet('EGRESO'),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.remove_circle, size: 16, color: Color(0xFF121214)),
                      const SizedBox(width: 8),
                      Text(
                        'EGRESO CHICA',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF121214),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 3. Pestañas de Navegación del Turno (Premium Segmented Control)
        Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF181A1E),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Row(
            children: [
              _buildTabButton(0, 'BALANCE', Icons.analytics_outlined),
              _buildTabButton(1, 'MOVIMIENTOS', Icons.swap_vert_outlined),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. Contenido Activo de la Pestaña Seleccionada
        _activeTab == 0
            ? GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isTablet ? 2.5 : 2.0,
                ),
                itemBuilder: (context, index) => cards[index],
              )
            : _buildMovimientosList(caja.movimientos, activeVentas, currencySymbol, currencyIso),
      ],
    );
  }

  // =========================================================================
  // 💴 BOTÓN DE PESTAÑA PERSONALIZADO
  // =========================================================================
  Widget _buildTabButton(int index, String label, IconData icon) {
    final bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF7000FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF7000FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : Colors.white30,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isActive ? Colors.white : Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
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
    String currencyIso,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final formatted = CurrencyHelper.formatAmount(amount, currencyIso);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.03),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 13,
                    color: accentColor.withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
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
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$currency $formatted',
                  style: GoogleFonts.plusJakartaSans(
                    color: accentColor,
                    fontSize: 14,
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
  // 📚 3. CRONOLOGÍA DE EVENTOS Y MOVIMIENTOS UNIFICADA
  // =========================================================================
  Widget _buildMovimientosList(List<CajaMovimientoModel> movimientos, List<VentaModel> ventas, String symbol, String iso) {
    // 1. Unificar y ordenar cronológicamente DESC
    final List<EventoMovimiento> eventos = [];
    
    for (final m in movimientos) {
      eventos.add(EventoMovimiento(
        id: m.id,
        tipo: m.tipo, // 'INGRESO' o 'EGRESO'
        fecha: m.createdAt,
        monto: m.monto,
        metodoPago: m.metodoPago,
        concepto: m.concepto,
        cajero: m.usuario?.nombre ?? 'Cajero',
        original: m,
      ));
    }

    for (final v in ventas) {
      final String conceptoVenta = v.detalles.isNotEmpty
          ? v.detalles.map((d) => '${d.cantidad}x ${d.productoNombre}').join(', ')
          : 'Venta POS';

      eventos.add(EventoMovimiento(
        id: v.id,
        tipo: 'VENTA',
        fecha: v.fecha,
        monto: v.total,
        metodoPago: v.metodoPago,
        concepto: conceptoVenta,
        cajero: v.usuario?.nombre ?? 'Cajero',
        original: v,
      ));
    }

    // Ordenar de más reciente a más antiguo
    eventos.sort((a, b) => b.fecha.compareTo(a.fecha));

    if (eventos.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Center(
          child: Text(
            'Sin eventos ni movimientos registrados en este turno.',
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
            'BITÁCORA UNIFICADA DE EVENTOS (TIEMPO REAL)',
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
            itemCount: eventos.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final ev = eventos[index];
              final String tipo = ev.tipo;
              final bool isIngreso = tipo == 'INGRESO';
              final bool isEgreso = tipo == 'EGRESO';
              final bool isVenta = tipo == 'VENTA';
              
              final time = DateFormat('hh:mm a').format(ev.fecha.toLocal());
              final formattedMonto = CurrencyHelper.formatAmount(ev.monto, iso);

              Color iconBgColor = Colors.white.withOpacity(0.05);
              Color iconColor = Colors.white;
              IconData icon = Icons.info_outline;

              if (isIngreso) {
                iconBgColor = const Color(0xFF00FF66).withOpacity(0.1);
                iconColor = const Color(0xFF00FF66);
                icon = Icons.arrow_upward;
              } else if (isEgreso) {
                iconBgColor = Colors.redAccent.withOpacity(0.1);
                iconColor = Colors.redAccent;
                icon = Icons.arrow_downward;
              } else if (isVenta) {
                iconBgColor = const Color(0xFF7000FF).withOpacity(0.1);
                iconColor = const Color(0xFF00F0FF);
                icon = Icons.receipt_long_outlined;
              }

              return InkWell(
                onTap: () => _openMovementDetailBottomSheet(ev),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVenta ? 'VENTA POS • TICKET' : ev.concepto,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isVenta)
                              Text(
                                ev.concepto,
                                style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              'Vía ${ev.metodoPago} • $time por ${ev.cajero}',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isIngreso ? '+' : '-'} $symbol $formattedMonto',
                        style: GoogleFonts.plusJakartaSans(
                          color: isIngreso ? const Color(0xFF00FF66) : (isVenta ? const Color(0xFF00F0FF) : Colors.redAccent),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 📚 BOTTOM SHEET PARA DETALLE DE TICKET / MOVIMIENTO DE CAJA
  // =========================================================================
  void _openMovementDetailBottomSheet(EventoMovimiento ev) {
    final currencySymbol = ref.read(currencySymbolProvider);
    final currencyIso = ref.read(currencyIsoProvider);
    final isVenta = ev.tipo == 'VENTA';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E2024),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                isVenta ? 'TICKET DE COMPRA' : 'DETALLE DE CAJA CHICA',
                style: GoogleFonts.plusJakartaSans(
                  color: isVenta ? const Color(0xFF00F0FF) : (ev.tipo == 'INGRESO' ? const Color(0xFF00FF66) : Colors.redAccent),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Contenido Dinámico
              isVenta
                  ? _buildTicketDetails(ev.original as VentaModel, currencySymbol, currencyIso)
                  : _buildManualMovementDetails(ev.original as CajaMovimientoModel, currencySymbol, currencyIso),
              
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.04),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Text(
                  'CERRAR TICKET',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
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
  }

  Widget _buildTicketDetails(VentaModel venta, String symbol, String iso) {
    final String barmanNombre = venta.usuario != null
        ? venta.usuario!.nombre
        : 'Cajero';

    final String fecha = DateFormat('dd/MM/yyyy • hh:mm a').format(venta.fecha.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            children: [
              _buildTicketDetailRow('Ticket ID:', venta.id.substring(0, 8).toUpperCase(), Colors.white70),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Cajero:', barmanNombre, Colors.white),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Fecha y Hora:', fecha, Colors.white54),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Canal de Pago:', venta.metodoPago, const Color(0xFF00F0FF)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'ARTÍCULOS CONSUMIDOS',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: venta.detalles.length,
          separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
          itemBuilder: (context, index) {
            final d = venta.detalles[index];
            final String variantName = d.variante?.nombre ?? 'Genérico';
            final String productName = d.productoNombre;
            final String name = '$productName ($variantName)';
            
            final double subtotal = d.precioUnitario * d.cantidad;
            final formattedSubtotal = CurrencyHelper.formatAmount(subtotal, iso);
            final formattedPrice = CurrencyHelper.formatAmount(d.precioUnitario, iso);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${d.cantidad}x $symbol $formattedPrice',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$symbol $formattedSubtotal',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (d.dama != null || d.esInvitacion) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          d.esInvitacion ? Icons.card_giftcard : Icons.female,
                          size: 11,
                          color: d.esInvitacion ? const Color(0xFF00FF66) : const Color(0xFFFF00D6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          d.esInvitacion
                              ? 'Invitación Especial (Sin comisión)'
                              : 'Asignado a: ${d.dama!.nombre} (Comisión: $symbol ${CurrencyHelper.formatAmount(d.comisionDama * d.cantidad, iso)})',
                          style: GoogleFonts.plusJakartaSans(
                            color: d.esInvitacion ? const Color(0xFF00FF66) : const Color(0xFFFF00D6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 16),
        const Divider(color: Colors.white10),
        const SizedBox(height: 10),

        if (venta.metodoPago == 'MIXTO') ...[
          _buildTicketDetailRow('Pago Efectivo:', '$symbol ${CurrencyHelper.formatAmount(venta.montoEfectivo, iso)}', Colors.white54),
          const SizedBox(height: 4),
          _buildTicketDetailRow('Pago Tarjeta:', '$symbol ${CurrencyHelper.formatAmount(venta.montoTarjeta, iso)}', Colors.white54),
          const SizedBox(height: 4),
          _buildTicketDetailRow('Pago Transf/QR:', '$symbol ${CurrencyHelper.formatAmount(venta.montoTrQr, iso)}', Colors.white54),
          const SizedBox(height: 8),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF7000FF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7000FF).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL COBRADO:',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF00F0FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '$symbol ${CurrencyHelper.formatAmount(venta.total, iso)}',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF00F0FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualMovementDetails(CajaMovimientoModel m, String symbol, String iso) {
    final String barmanNombre = m.usuario != null
        ? m.usuario!.nombre
        : 'Cajero';

    final String fecha = DateFormat('dd/MM/yyyy • hh:mm a').format(m.createdAt.toLocal());
    final bool isIngreso = m.tipo == 'INGRESO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isIngreso ? const Color(0xFF00FF66).withOpacity(0.08) : Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isIngreso ? const Color(0xFF00FF66).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  isIngreso ? 'INGRESO DE CAJA CHICA' : 'EGRESO DE CAJA CHICA',
                  style: GoogleFonts.plusJakartaSans(
                    color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            children: [
              _buildTicketDetailRow('Cajero:', barmanNombre, Colors.white),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Fecha y Hora:', fecha, Colors.white54),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Método Utilizado:', m.metodoPago, Colors.white70),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'CONCEPTO / DESCRIPCIÓN',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Text(
            m.concepto.isNotEmpty ? m.concepto : 'Sin descripción registrada.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isIngreso ? const Color(0xFF00FF66).withOpacity(0.05) : Colors.redAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isIngreso ? const Color(0xFF00FF66).withOpacity(0.1) : Colors.redAccent.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MONTO OPERACIÓN:',
                style: GoogleFonts.plusJakartaSans(
                  color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${isIngreso ? '+' : '-'} $symbol ${CurrencyHelper.formatAmount(m.monto, iso)}',
                style: GoogleFonts.plusJakartaSans(
                  color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white30,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
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
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        CurrencyInputFormatter(iso: currencyIso),
                      ],
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: CurrencyHelper.formatAmount(0.00, currencyIso),
                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 15, fontWeight: FontWeight.bold),
                        prefixIcon: Container(
                          width: 48,
                          alignment: Alignment.center,
                          child: Text(
                            currencySymbol,
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00F0FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 48,
                          maxWidth: 48,
                          minHeight: 48,
                          maxHeight: 48,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.only(right: 16),
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

class EventoMovimiento {
  final String id;
  final String tipo; // 'VENTA', 'INGRESO', 'EGRESO'
  final DateTime fecha;
  final double monto;
  final String metodoPago;
  final String concepto;
  final String cajero;
  final dynamic original; // CajaMovimientoModel o VentaModel

  EventoMovimiento({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.monto,
    required this.metodoPago,
    required this.concepto,
    required this.cajero,
    required this.original,
  });
}
