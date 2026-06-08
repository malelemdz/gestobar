import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../repository/catalog_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../caja/providers/caja_provider.dart';
import '../../../core/utils/currency_helper.dart';
import 'widgets/catalog_section.dart';
import 'widgets/cart_section.dart';
import 'dialogs/success_dialog.dart';

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  bool _isCheckingOut = false;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final currencyIso = ref.watch(currencyIsoProvider);

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFF121214), // Midnight background
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth >= 900;

            if (isTablet) {
              return Row(
                children: [
                  const Expanded(
                    child: CatalogSection(),
                  ),
                  Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.05),
                  ),
                  Container(
                    width: 380,
                    color: const Color(0xFF1A1C20),
                    child: CartSection(
                      isCheckingOut: _isCheckingOut,
                      onCheckout: (cartState, mCtx) =>
                          _handleCheckoutClick(cartState, mCtx, currencyIso),
                    ),
                  ),
                ],
              );
            } else {
              return Stack(
                children: [
                  const Column(
                    children: [
                      Expanded(
                        child: CatalogSection(),
                      ),
                    ],
                  ),
                  if (cart.items.isNotEmpty)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _buildMobileFloatingCartButton(context, cart, currencyIso),
                    ),
                ],
              );
            }
          },
        ),
      ),
    );

    return Stack(
      children: [
        scaffold,
        if (_isCheckingOut)
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2024).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                              strokeWidth: 4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'PROCESANDO PAGO...',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Por favor espera un momento',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white38,
                              fontWeight: FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMobileFloatingCartButton(BuildContext context, CartState cart, String currencyIso) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1C20),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: CartSection(
                          modalContext: context,
                          isCheckingOut: _isCheckingOut,
                          onCheckout: (cartState, mCtx) =>
                              _handleCheckoutClick(cartState, mCtx, currencyIso),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
          ),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${cart.items.fold(0, (sum, item) => sum + item.quantity)} items',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Ver Ticket',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleCheckoutClick(CartState cart, BuildContext? parentModalContext, String currencyIso) {
    final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;
    debugPrint("🔥 CLICK RECIBIDO: Método ${cart.metodoPago}, Total: ${cart.total}");
    if (cart.metodoPago == 'TARJETA' || cart.metodoPago == 'TR/QR') {
      _performCheckout(cart, modalContext: parentModalContext, montoTarjeta: cart.metodoPago == 'TARJETA' ? cart.total : 0, montoTrQr: cart.metodoPago == 'TR/QR' ? cart.total : 0);
      return;
    }

    final bool isMixto = cart.metodoPago == 'MIXTO';
    final currencySymbol = ref.read(currencySymbolProvider);

    double valEfectivo = isMixto ? 0.0 : cart.total;
    double valTarjeta = 0.0;
    double valTrQr = 0.0;
    
    final bool hasDecimals = CurrencyHelper.getDecimalDigits(currencyIso) > 0;
    final txtRecibidoEfectivo = TextEditingController(text: isMixto ? '' : (hasDecimals ? cart.total.toStringAsFixed(2) : cart.total.toInt().toString()));

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
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  double totalIngresado = 0.0;
                  double vuelto = 0.0;

                  if (isMixto) {
                    totalIngresado = valEfectivo + valTarjeta + valTrQr;
                  } else {
                    final ingresado = CurrencyHelper.parseAmount(txtRecibidoEfectivo.text, currencyIso);
                    totalIngresado = ingresado;
                    vuelto = ingresado > cart.total ? ingresado - cart.total : 0.0;
                  }

                  final bool canSubmit = isMixto
                      ? (totalIngresado - cart.total).abs() < 0.01
                      : totalIngresado >= cart.total - 0.01;

                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2024),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isMixto ? 'DISTRIBUCIÓN DE PAGO MIXTO' : 'COBRO EN EFECTIVO',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TOTAL A COBRAR: $currencySymbol ${CurrencyHelper.formatAmount(cart.total, currencyIso)}',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        if (!isMixto) ...[
                          Text('Monto Recibido del Cliente:', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: txtRecibidoEfectivo,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [CurrencyInputFormatter(iso: currencyIso)],
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            onChanged: (val) => setModalState(() {}),
                            decoration: InputDecoration(
                              prefixText: '$currencySymbol ',
                              prefixStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF00F0FF), fontSize: 24, fontWeight: FontWeight.bold),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Vuelto a entregar:', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 14)),
                              Text(
                                '$currencySymbol ${CurrencyHelper.formatAmount(vuelto, currencyIso)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: vuelto > 0 ? const Color(0xFFFF00D6) : Colors.white24,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildMixtoInput('Efectivo', valEfectivo, (v) => setModalState(() => valEfectivo = v), currencySymbol, currencyIso),
                          _buildMixtoInput('Tarjeta', valTarjeta, (v) => setModalState(() => valTarjeta = v), currencySymbol, currencyIso),
                          _buildMixtoInput('Transf/QR', valTrQr, (v) => setModalState(() => valTrQr = v), currencySymbol, currencyIso),
                          
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Resta por cubrir:', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 14)),
                              Text(
                                '$currencySymbol ${CurrencyHelper.formatAmount((cart.total - totalIngresado).clamp(0.0, 99999.0), currencyIso)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: (cart.total - totalIngresado) > 0.01 ? Colors.redAccent : const Color(0xFF00F0FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),
                        Center(
                          child: SizedBox(
                            width: 250,
                            child: ElevatedButton(
                              onPressed: canSubmit
                                  ? () {
                                      Navigator.pop(context);
                                      _performCheckout(
                                        cart,
                                        modalContext: parentModalContext,
                                        montoEfectivo: isMixto ? valEfectivo : cart.total,
                                        montoTarjeta: isMixto ? valTarjeta : 0.0,
                                        montoTrQr: isMixto ? valTrQr : 0.0,
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7000FF),
                                disabledBackgroundColor: Colors.white10,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                'CONFIRMAR',
                                style: GoogleFonts.plusJakartaSans(color: canSubmit ? Colors.white : Colors.white30, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              double totalIngresado = 0.0;
              double vuelto = 0.0;

              if (isMixto) {
                totalIngresado = valEfectivo + valTarjeta + valTrQr;
              } else {
                final ingresado = CurrencyHelper.parseAmount(txtRecibidoEfectivo.text, currencyIso);
                totalIngresado = ingresado;
                vuelto = ingresado > cart.total ? ingresado - cart.total : 0.0;
              }

              final bool canSubmit = isMixto
                  ? (totalIngresado - cart.total).abs() < 0.01
                  : totalIngresado >= cart.total - 0.01;

              return Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E2024),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isMixto ? 'DISTRIBUCIÓN DE PAGO MIXTO' : 'COBRO EN EFECTIVO',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TOTAL A COBRAR: $currencySymbol ${CurrencyHelper.formatAmount(cart.total, currencyIso)}',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00F0FF), fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (!isMixto) ...[
                      Text('Monto Recibido del Cliente:', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: txtRecibidoEfectivo,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [CurrencyInputFormatter(iso: currencyIso)],
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        onChanged: (val) => setModalState(() {}),
                        decoration: InputDecoration(
                          prefixText: '$currencySymbol ',
                          prefixStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF00F0FF), fontSize: 24, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Vuelto a entregar:', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 14)),
                          Text(
                            '$currencySymbol ${CurrencyHelper.formatAmount(vuelto, currencyIso)}',
                            style: GoogleFonts.plusJakartaSans(
                              color: vuelto > 0 ? const Color(0xFFFF00D6) : Colors.white24,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildMixtoInput('Efectivo', valEfectivo, (v) => setModalState(() => valEfectivo = v), currencySymbol, currencyIso),
                      _buildMixtoInput('Tarjeta', valTarjeta, (v) => setModalState(() => valTarjeta = v), currencySymbol, currencyIso),
                      _buildMixtoInput('Transf/QR', valTrQr, (v) => setModalState(() => valTrQr = v), currencySymbol, currencyIso),
                      
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Resta por cubrir:', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 14)),
                          Text(
                            '$currencySymbol ${CurrencyHelper.formatAmount((cart.total - totalIngresado).clamp(0.0, 99999.0), currencyIso)}',
                            style: GoogleFonts.plusJakartaSans(
                              color: (cart.total - totalIngresado) > 0.01 ? Colors.redAccent : const Color(0xFF00F0FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: canSubmit
                          ? () {
                              Navigator.pop(ctx);
                              _performCheckout(
                                cart,
                                modalContext: parentModalContext,
                                montoEfectivo: isMixto ? valEfectivo : cart.total,
                                montoTarjeta: isMixto ? valTarjeta : 0.0,
                                montoTrQr: isMixto ? valTrQr : 0.0,
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7000FF),
                        disabledBackgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'CONFIRMAR',
                        style: GoogleFonts.plusJakartaSans(color: canSubmit ? Colors.white : Colors.white30, fontWeight: FontWeight.bold),
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
  }

  Widget _buildMixtoInput(String label, double val, Function(double) onChanged, String currency, String currencyIso) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontWeight: FontWeight.bold))),
          Expanded(
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [CurrencyInputFormatter(iso: currencyIso)],
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
              onChanged: (text) => onChanged(CurrencyHelper.parseAmount(text, currencyIso)),
              decoration: InputDecoration(
                prefixText: '$currency ',
                prefixStyle: const TextStyle(color: Color(0xFF00F0FF)),
                filled: true,
                fillColor: Colors.black26,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performCheckout(CartState cart, {BuildContext? modalContext, double? montoEfectivo, double? montoTarjeta, double? montoTrQr}) async {
    debugPrint('⚡ [POS Checkout] Iniciando proceso de venta para ${cart.items.length} ítems. Método de pago: ${cart.metodoPago}');
    setState(() => _isCheckingOut = true);

    try {
      final repository = ref.read(catalogRepositoryProvider);

      await repository.checkout(
        metodoPago: cart.metodoPago == 'TR/QR' ? 'QR' : cart.metodoPago,
        items: cart.items,
        montoEfectivo: montoEfectivo,
        montoTarjeta: montoTarjeta,
        montoTrQr: montoTrQr,
      );

      debugPrint('⚡ [POS Checkout] Venta registrada con éxito en el servidor.');

      ref.read(cartProvider.notifier).clear();

      if (modalContext != null && modalContext.mounted) {
        try {
          if (Navigator.canPop(modalContext)) {
            debugPrint('⚡ [POS Checkout] Cerrando modal bottom sheet de móvil.');
            Navigator.pop(modalContext);
          }
        } catch (e) {
          debugPrint('⚠️ [POS Checkout] No se pudo cerrar el modal automáticamente: $e');
        }
      }

      showSuccessDialog(context);
    } catch (e, stackTrace) {
      debugPrint('❌ [POS Checkout] Error al realizar venta: $e');
      debugPrint('$stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Error en la venta: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.colorDanger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }
}
