import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../providers/caja_provider.dart';
import '../../repository/caja_repository.dart';
import '../widgets/movimientos_list_widgets.dart';
import 'movement_detail_bottom_sheet.dart';

class ClosedCajaDetailBottomSheet extends ConsumerStatefulWidget {
  final String cajaId;
  final String currencySymbol;
  final String currencyIso;

  const ClosedCajaDetailBottomSheet({
    super.key,
    required this.cajaId,
    required this.currencySymbol,
    required this.currencyIso,
  });

  @override
  ConsumerState<ClosedCajaDetailBottomSheet> createState() => _ClosedCajaDetailBottomSheetState();
}

class _ClosedCajaDetailBottomSheetState extends ConsumerState<ClosedCajaDetailBottomSheet> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    final cajaDetailState = ref.watch(cajaDetailsProvider(widget.cajaId));
    final cajaSalesState = ref.watch(cajaSalesProvider(widget.cajaId));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E2024),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: cajaDetailState.when(
        data: (caja) {
          final String barmanApertura = caja.aperturaUsuario?.nombre ?? 'Cajero';
          final String barmanCierre = caja.cierreUsuario?.nombre ?? 'Cajero';
          final String fApertura = DateFormat('dd/MM/yyyy • HH:mm').format(caja.fechaApertura.toLocal());
          final String fCierre = caja.fechaCierre != null
              ? DateFormat('dd/MM/yyyy • HH:mm').format(caja.fechaCierre!.toLocal())
              : 'En curso';

          final double totalVentasPos = caja.totalVentasEfectivo + caja.totalVentasTarjeta + caja.totalVentasTrQr;
          final bool isTablet = MediaQuery.of(context).size.width >= 750;

          final List<Widget> cards = [
            _buildFinancieraCard('Fondo de Caja (Inicial)', caja.montoInicial, widget.currencySymbol, const Color(0xFF00F0FF), widget.currencyIso, Icons.account_balance_wallet_outlined),
            _buildFinancieraCard('Total Esperado en Gaveta', caja.totalEsperadoGaveta, widget.currencySymbol, const Color(0xFF00F0FF), widget.currencyIso, Icons.move_to_inbox_outlined),
            _buildFinancieraCard('Ventas Efectivo POS', caja.totalVentasEfectivo, widget.currencySymbol, Colors.white70, widget.currencyIso, Icons.payments_outlined),
            _buildFinancieraCard('Ventas Tarjeta POS', caja.totalVentasTarjeta, widget.currencySymbol, Colors.white70, widget.currencyIso, Icons.credit_card_outlined),
            _buildFinancieraCard('Ventas TR / QR POS', caja.totalVentasTrQr, widget.currencySymbol, Colors.white70, widget.currencyIso, Icons.mobile_friendly_outlined),
            _buildFinancieraCard('Ventas Totales POS', totalVentasPos, widget.currencySymbol, const Color(0xFF00FF66), widget.currencyIso, Icons.analytics_outlined),
            _buildFinancieraCard('Ganancia Neta del Bar', caja.gananciaNetaBar, widget.currencySymbol, const Color(0xFF7000FF), widget.currencyIso, Icons.trending_up_outlined),
            _buildFinancieraCard(
              'Comisiones Damas',
              caja.totalComisionesDamas,
              widget.currencySymbol,
              const Color(0xFFFF00D6),
              widget.currencyIso,
              Icons.female_outlined,
              onTap: () => _openDamasBreakdownBottomSheet(context, caja.id),
            ),
            _buildFinancieraCard('Ingresos Manuales', caja.totalIngresosManuales, widget.currencySymbol, const Color(0xFF00FFCC), widget.currencyIso, Icons.add_circle_outline),
            _buildFinancieraCard('Egresos Caja Chica', caja.totalEgresosManuales, widget.currencySymbol, Colors.redAccent, widget.currencyIso, Icons.remove_circle_outline),
          ];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera del Turno Cerrado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TURNO HISTÓRICO CERRADO',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              // Detalles del Turno en una Bento Card (Cuerpo)
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF181A1E),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                ),
                child: Column(
                  children: [
                    _buildDetalleTurnoRow(
                      Icons.vpn_key_outlined,
                      'Apertura:',
                      '$fApertura por $barmanApertura',
                    ),
                    const SizedBox(height: 8.0),
                    _buildDetalleTurnoRow(
                      Icons.lock_clock_outlined,
                      'Cierre:',
                      '$fCierre por $barmanCierre',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),

              // Pestañas de Balance / Movimientos
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
              const SizedBox(height: 12.0),

              // Cuerpo
              Flexible(
                child: SingleChildScrollView(
                  child: _activeTab == 0
                      ? GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: cards.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTablet ? 3 : 2,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: isTablet ? 2.5 : 2.0,
                          ),
                          itemBuilder: (context, index) => cards[index],
                        )
                      : cajaSalesState.when(
                          data: (ventas) => MovimientosList(
                            movimientos: caja.movimientos,
                            ventas: ventas,
                            currencySymbol: widget.currencySymbol,
                            currencyIso: widget.currencyIso,
                            onMovementDetail: (ev) => _openMovementDetailBottomSheet(context, ev),
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
                          ),
                          error: (err, __) => Center(
                            child: Text(
                              'Error al cargar ventas: $err',
                              style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 11),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 40),
            Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
            SizedBox(height: 40),
          ],
        ),
        error: (err, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error al cargar detalles: $err',
              style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12),
            ),
            const SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(cajaDetailsProvider(widget.cajaId));
                ref.invalidate(cajaSalesProvider(widget.cajaId));
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
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

  void _openMovementDetailBottomSheet(BuildContext context, dynamic ev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MovementDetailBottomSheet(
          ev: ev,
          currencySymbol: widget.currencySymbol,
          currencyIso: widget.currencyIso,
        );
      },
    );
  }

  void _openDamasBreakdownBottomSheet(BuildContext context, String cajaId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E2024),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
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
              const SizedBox(height: 12.0),

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
                      final formattedCom = CurrencyHelper.formatAmount(com, widget.currencyIso);

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
                              '${widget.currencySymbol} $formattedCom',
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

  Widget _buildDetalleTurnoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white30, size: 14),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white30,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
