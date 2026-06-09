import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_toast.dart';

import '../../models/caja_model.dart';

class AddMovementBottomSheet extends StatefulWidget {
  final String tipo; // 'INGRESO' o 'EGRESO'
  final String currencySymbol;
  final String currencyIso;
  final bool isDialog;
  final CajaModel? caja;
  final Future<void> Function({
    required double monto,
    required String metodoPago,
    required String concepto,
  }) onConfirm;

  const AddMovementBottomSheet({
    super.key,
    required this.tipo,
    required this.currencySymbol,
    required this.currencyIso,
    this.isDialog = false,
    this.caja,
    required this.onConfirm,
  });

  @override
  State<AddMovementBottomSheet> createState() => _AddMovementBottomSheetState();
}

class _AddMovementBottomSheetState extends State<AddMovementBottomSheet> {
  final TextEditingController _movMontoCtrl = TextEditingController();
  final TextEditingController _movConceptoCtrl = TextEditingController();
  String _selectedMetodoPago = 'EFECTIVO';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _movMontoCtrl.dispose();
    _movConceptoCtrl.dispose();
    super.dispose();
  }

  double _getAvailableBalance(String metodo) {
    if (widget.caja == null) return 0.0;
    final c = widget.caja!;
    
    double balanceEfectivo = c.montoInicial + c.totalVentasEfectivo - c.totalComisionesDamas;
    double balanceTarjeta = c.totalVentasTarjeta;
    double balanceTrQr = c.totalVentasTrQr;

    for (var mov in c.movimientos) {
      final m = mov.metodoPago.toUpperCase();
      final t = mov.tipo.toUpperCase();
      final val = mov.monto;

      if (t == 'INGRESO') {
        if (m == 'EFECTIVO') balanceEfectivo += val;
        else if (m == 'TARJETA') balanceTarjeta += val;
        else if (m == 'TRANSFERENCIA' || m == 'TR/QR') balanceTrQr += val;
      } else if (t == 'EGRESO') {
        if (m == 'EFECTIVO') balanceEfectivo -= val;
        else if (m == 'TARJETA') balanceTarjeta -= val;
        else if (m == 'TRANSFERENCIA' || m == 'TR/QR') balanceTrQr -= val;
      }
    }

    if (metodo == 'EFECTIVO') return balanceEfectivo;
    if (metodo == 'TARJETA') return balanceTarjeta;
    if (metodo == 'TR/QR' || metodo == 'TRANSFERENCIA') return balanceTrQr;
    
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: widget.isDialog
            ? BorderRadius.circular(24.0)
            : const BorderRadius.vertical(top: Radius.circular(16.0)),
        border: widget.isDialog
            ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
            : null,
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: widget.isDialog ? 24.0 : MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registrar ${widget.tipo == 'INGRESO' ? 'Ingreso de Caja Chica' : 'Egreso / Pago de Turno'}',
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
          const SizedBox(height: 12.0),

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
                CurrencyInputFormatter(iso: widget.currencyIso),
              ],
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: CurrencyHelper.formatAmount(0.00, widget.currencyIso),
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 15, fontWeight: FontWeight.bold),
                prefixIcon: Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    widget.currencySymbol,
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
          const SizedBox(height: 12.0),

          // Selector de Método de Pago
          Text(
            'Método de Pago / Canal',
            style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: ['EFECTIVO', 'TARJETA', 'TR/QR'].map((metodo) {
              final bool isSelected = _selectedMetodoPago == metodo;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedMetodoPago = metodo);
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
          const SizedBox(height: 8.0),
          if (widget.tipo == 'EGRESO' && widget.caja != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Disponible en $_selectedMetodoPago:',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${widget.currencySymbol} ${CurrencyHelper.formatAmount(_getAvailableBalance(_selectedMetodoPago), widget.currencyIso)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: _getAvailableBalance(_selectedMetodoPago) > 0
                          ? const Color(0xFF00F0FF)
                          : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12.0),

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
          const SizedBox(height: 12.0),

          // Botón de Confirmación
          Center(
            child: SizedBox(
              width: widget.isDialog ? 250.0 : double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final textMonto = _movMontoCtrl.text.trim();
                        final textConcepto = _movConceptoCtrl.text.trim();
                        if (textMonto.isEmpty || textConcepto.isEmpty) {
                          CustomToast.show(
                            context,
                            message: 'Por favor completa el monto y el concepto.',
                            type: ToastType.warning,
                          );
                          return;
                        }

                        final double montoDouble = CurrencyHelper.parseAmount(textMonto, widget.currencyIso);
                        if (montoDouble <= 0) return;

                        if (widget.tipo == 'EGRESO') {
                          final disponible = _getAvailableBalance(_selectedMetodoPago);
                          if (montoDouble > disponible + 0.01) {
                            CustomToast.show(
                              context,
                              message: 'Saldo insuficiente en $_selectedMetodoPago (${widget.currencySymbol} ${CurrencyHelper.formatAmount(disponible, widget.currencyIso)})',
                              type: ToastType.warning,
                            );
                            return;
                          }
                        }

                        setState(() => _isSubmitting = true);
                        try {
                          await widget.onConfirm(
                            monto: montoDouble,
                            metodoPago: _selectedMetodoPago == 'TR/QR' ? 'TRANSFERENCIA' : _selectedMetodoPago,
                            concepto: textConcepto,
                          );
                          if (mounted) Navigator.pop(context); // Close bottom sheet on success
                        } catch (e) {
                          if (mounted) {
                            CustomToast.show(
                              context,
                              message: 'Error: ${e.toString().replaceAll('Exception: ', '')}',
                              type: ToastType.error,
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7000FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'CONFIRMAR MOVIMIENTO',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
