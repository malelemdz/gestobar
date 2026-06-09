import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../models/caja_model.dart';
import '../../models/evento_movimiento.dart';
import '../../models/venta_model.dart';
import 'movimientos_list_widgets.dart';
import 'closed_cajas_history_list.dart';

class OpenCajaPanel extends StatefulWidget {
  final CajaModel caja;
  final List<VentaModel> activeVentas;
  final String currencySymbol;
  final String currencyIso;
  final bool isLoading;
  final void Function(String cajaId) onCerrarCaja;
  final void Function(String tipo) onAddMovement;
  final void Function(String cajaId) onDamasBreakdown;
  final void Function(EventoMovimiento ev) onMovementDetail;
  final bool showHistorialTab;
  final void Function(String cajaId) onCajaTap;

  const OpenCajaPanel({
    super.key,
    required this.caja,
    required this.activeVentas,
    required this.currencySymbol,
    required this.currencyIso,
    required this.isLoading,
    required this.onCerrarCaja,
    required this.onAddMovement,
    required this.onDamasBreakdown,
    required this.onMovementDetail,
    required this.showHistorialTab,
    required this.onCajaTap,
  });

  @override
  State<OpenCajaPanel> createState() => _OpenCajaPanelState();
}

class _OpenCajaPanelState extends State<OpenCajaPanel> {
  int _activeTab = 0;

  Widget _buildFichaTurno(String barmanNombre, String fecha) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16.0),
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
          const SizedBox(height: 12.0),

          // Botón de Cierre
          InkWell(
            onTap: widget.isLoading ? null : () => widget.onCerrarCaja(widget.caja.id),
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
    );
  }

  Widget _buildCajaChicaButtons() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => widget.onAddMovement('INGRESO'),
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
                    'REG. INGRESO',
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
            onTap: () => widget.onAddMovement('EGRESO'),
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
                    'REG. EGRESO',
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
    );
  }

  Widget _buildVerticalTabButton(int index, String label, IconData icon) {
    final bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 42,
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7000FF) : const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(isActive ? 0.0 : 0.04)),
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
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.white30,
            ),
            const SizedBox(width: 12),
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
    );
  }

  Widget _buildActiveTabContent(List<Widget> cards) {
    if (_activeTab == 0) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final int cols = width < 550
              ? 2
              : width < 850
                  ? 3
                  : 4;
          final double aspect = width < 550
              ? 2.0
              : width < 850
                  ? 2.3
                  : 2.5;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: aspect,
            ),
            itemBuilder: (context, index) => cards[index],
          );
        },
      );
    } else if (_activeTab == 1) {
      return MovimientosList(
        movimientos: widget.caja.movimientos,
        ventas: widget.activeVentas,
        currencySymbol: widget.currencySymbol,
        currencyIso: widget.currencyIso,
        onMovementDetail: widget.onMovementDetail,
      );
    } else {
      return ClosedCajasHistoryList(onCajaTap: widget.onCajaTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String barmanNombre = widget.caja.aperturaUsuario != null
        ? widget.caja.aperturaUsuario!.nombre
        : 'Barman Encargado';

    final String fecha = DateFormat('dd/MM/yyyy • HH:mm').format(widget.caja.fechaApertura.toLocal());

    final double totalVentasPos = widget.caja.totalVentasEfectivo + widget.caja.totalVentasTarjeta + widget.caja.totalVentasTrQr;

    // Bento Grid setup
    final List<Widget> cards = [
      _buildFinancieraCard('Fondo de Caja (Inicial)', widget.caja.montoInicial, widget.currencySymbol, const Color(0xFF00F0FF), widget.currencyIso, Icons.account_balance_wallet_outlined),
      _buildFinancieraCard('Total Esperado en Gaveta', widget.caja.totalEsperadoGaveta, widget.currencySymbol, const Color(0xFF00F0FF), widget.currencyIso, Icons.move_to_inbox_outlined),
      _buildFinancieraCard('Ventas Efectivo POS', widget.caja.totalVentasEfectivo, widget.currencySymbol, Colors.white70, widget.currencyIso, Icons.payments_outlined),
      _buildFinancieraCard('Ventas Tarjeta POS', widget.caja.totalVentasTarjeta, widget.currencySymbol, Colors.white70, widget.currencyIso, Icons.credit_card_outlined),
      _buildFinancieraCard('Ventas TR / QR POS', widget.caja.totalVentasTrQr, widget.currencySymbol, Colors.white70, widget.currencyIso, Icons.mobile_friendly_outlined),
      _buildFinancieraCard('Ventas Totales POS', totalVentasPos, widget.currencySymbol, const Color(0xFF00FF66), widget.currencyIso, Icons.analytics_outlined),
      _buildFinancieraCard('Ganancia Neta del Bar', widget.caja.gananciaNetaBar, widget.currencySymbol, const Color(0xFF7000FF), widget.currencyIso, Icons.trending_up_outlined),
      _buildFinancieraCard(
        'Comisiones Damas',
        widget.caja.totalComisionesDamas,
        widget.currencySymbol,
        const Color(0xFFFF00D6),
        widget.currencyIso,
        Icons.female_outlined,
        onTap: () => widget.onDamasBreakdown(widget.caja.id),
      ),
      _buildFinancieraCard('Ingresos Manuales', widget.caja.totalIngresosManuales, widget.currencySymbol, const Color(0xFF00FFCC), widget.currencyIso, Icons.add_circle_outline),
      _buildFinancieraCard('Egresos Caja Chica', widget.caja.totalEgresosManuales, widget.currencySymbol, Colors.redAccent, widget.currencyIso, Icons.remove_circle_outline),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLandscapeSplit = constraints.maxWidth >= 720;

        if (isLandscapeSplit) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda (ancho fijo 300px)
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFichaTurno(barmanNombre, fecha),
                    const SizedBox(height: 12.0),
                    _buildCajaChicaButtons(),
                    const SizedBox(height: 16.0),
                    Text(
                      'SECCIONES',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildVerticalTabButton(0, 'BALANCE GENERAL', Icons.analytics_outlined),
                    _buildVerticalTabButton(1, 'REGISTRO DE MOVIMIENTOS', Icons.swap_vert_outlined),
                    if (widget.showHistorialTab)
                      _buildVerticalTabButton(2, 'HISTORIAL DE CAJAS', Icons.history),
                  ],
                ),
              ),
              const SizedBox(width: 20.0),
              // Columna derecha (Expanded)
              Expanded(
                child: _buildActiveTabContent(cards),
              ),
            ],
          );
        }

        // Diseño Móvil / Portrait
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFichaTurno(barmanNombre, fecha),
            const SizedBox(height: 12.0),
            _buildCajaChicaButtons(),
            const SizedBox(height: 12.0),
            // Pestañas horizontales
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
                  if (widget.showHistorialTab)
                    _buildTabButton(2, 'HISTORIAL', Icons.history),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            _buildActiveTabContent(cards),
          ],
        );
      },
    );
  }

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
            color: isActive ? const Color(0xFF7000FF) : Colors.transparent,
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
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(16.0),
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
}
