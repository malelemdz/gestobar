import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../../admin/providers/bar_provider.dart';
import '../../../admin/providers/tarifas_provider.dart';
import '../../../admin/data/models/tarifa_model.dart';
import '../../../auth/models/user_model.dart';
import '../../../caja/providers/caja_provider.dart';
import '../../../../core/utils/currency_helper.dart';

class CartSection extends ConsumerWidget {
  final BuildContext? modalContext;
  final bool isCheckingOut;
  final void Function(CartState cart, BuildContext? modalContext) onCheckout;

  const CartSection({
    super.key,
    this.modalContext,
    required this.isCheckingOut,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final damasAsync = ref.watch(damasProvider);
    final cajaState = ref.watch(cajaStateProvider);
    final barState = ref.watch(currentBarProvider);
    final tarifasState = ref.watch(barTarifasProvider);
    
    final bool isCajaAbierta = cajaState.maybeWhen(
      data: (estado) => estado.abierta,
      orElse: () => false,
    );
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabecera del ticket compactada para optimizar espacio y evitar desperdicio arriba
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket de Venta',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (cart.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                  onPressed: () => ref.read(cartProvider.notifier).clear(),
                  tooltip: 'Limpiar ticket',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 8), 
        
        // --- SELECTOR GLOBAL DE COMPAÑÍA ---
        barState.maybeWhen(
          data: (bar) {
            if (bar.moduloDamasActivo && bar.tarifaCompaniaId != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: damasAsync.when(
                      data: (damas) {
                        final isDamaValid = cart.selectedDamaId != null && damas.any((d) => d.id == cart.selectedDamaId);
                        final safeSelectedDamaId = isDamaValid ? cart.selectedDamaId : null;

                        return DropdownButton<String?>(
                          isExpanded: true,
                          value: safeSelectedDamaId,
                          hint: Text('Sin Compañía (Cliente Normal)', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13)),
                          dropdownColor: const Color(0xFF1E2024),
                          icon: const Icon(Icons.people_alt_outlined, color: Colors.blueAccent, size: 20),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Sin Compañía', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13)),
                            ),
                            ...damas.map((d) => DropdownMenuItem<String?>(
                              value: d.id,
                              child: Text(d.nombre, style: GoogleFonts.plusJakartaSans(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                            )),
                          ],
                          onChanged: (val) {
                            final dama = damas.firstWhere((d) => d.id == val, orElse: () => UserModel(id: '', username: '', nombre: '', rolId: '', rolNombre: ''));
                            
                            final tarifaDefaultId = tarifasState.maybeWhen(
                              data: (tfs) => tfs.firstWhere((t) => t.esDefault, orElse: () => tfs.first).id,
                              orElse: () => '',
                            );

                            ref.read(cartProvider.notifier).setDama(
                              val,
                              val == null ? null : dama.nombre,
                              tarifaCompaniaId: bar.tarifaCompaniaId!,
                              tarifaDefaultId: tarifaDefaultId,
                            );
                          },
                        );
                      },
                      loading: () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text('Cargando personal...', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      error: (err, _) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Text('No se pudo cargar el personal', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
          orElse: () => const SizedBox(),
        ),
        if (!isCajaAbierta)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Turno cerrado. Abra la caja operativa antes de registrar ventas.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Lista de bebidas añadidas
        Expanded(
          child: cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 40, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      Text(
                        'Ticket vacío',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final List<TarifaModel> tarifasActivas = tarifasState.maybeWhen(data: (t) => t, orElse: () => []);
                    final String tDefaultId = tarifasActivas.firstWhere((t) => t.esDefault, orElse: () => TarifaModel(id: '', barId: '', nombre: '', esDefault: true, activo: true)).id;
                    final String tCompaniaId = barState.maybeWhen(data: (b) => b.tarifaCompaniaId ?? '', orElse: () => '');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (cart.selectedDamaId != null && cart.selectedDamaId!.isNotEmpty && !item.esInvitacion)
                                ? const Color(0xFFFF00D6).withOpacity(0.2)
                                : (item.esInvitacion
                                    ? Colors.amber.withOpacity(0.2)
                                    : (item.tarifaId != tDefaultId ? const Color(0xFF00F0FF).withOpacity(0.2) : Colors.white.withOpacity(0.04))),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.nombre,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (item.product.variantes.length > 1) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Formato: ${item.variant.nombre}',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white54,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '$currencySymbol${CurrencyHelper.formatAmount(item.precioUnitario, currencyIso)} x ${item.quantity}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: (cart.selectedDamaId != null && cart.selectedDamaId!.isNotEmpty && !item.esInvitacion)
                                              ? const Color(0xFFFF00D6)
                                              : (item.esInvitacion ? Colors.amber : const Color(0xFF00F0FF)),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 20),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantityByIndex(index, -1);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Text(
                                        '${item.quantity}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 20),
                                      onPressed: () {
                                        final barStateVal = ref.read(currentBarProvider);
                                        final bool splitSameVariantsVal = barStateVal.maybeWhen(
                                          data: (bar) => bar.moduloDamasActivo && (cart.selectedDamaId != null && cart.selectedDamaId!.isNotEmpty),
                                          orElse: () => false,
                                        );
                                        ref.read(cartProvider.notifier).updateQuantityByIndex(index, 1, splitSameVariants: splitSameVariantsVal);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (cart.selectedDamaId != null && cart.selectedDamaId!.isNotEmpty) ...[
                                  InkWell(
                                    onTap: () {
                                      ref.read(cartProvider.notifier).toggleInvitacion(
                                        index, 
                                        tarifaDefaultId: tDefaultId, 
                                        tarifaCompaniaId: tCompaniaId
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: item.esInvitacion ? Colors.amber.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: item.esInvitacion ? Colors.amber.withOpacity(0.5) : Colors.white10,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.card_giftcard, size: 14, color: item.esInvitacion ? Colors.amber : Colors.white38),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Invitación',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: item.esInvitacion ? Colors.amber : Colors.white38,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    height: 30,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: item.tarifaId.isEmpty ? (tDefaultId.isEmpty ? null : tDefaultId) : item.tarifaId,
                                        dropdownColor: const Color(0xFF1E2024),
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                                        items: tarifasActivas.map<DropdownMenuItem<String>>((TarifaModel t) => DropdownMenuItem<String>(
                                          value: t.id,
                                          child: Text(t.nombre, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold)),
                                        )).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            ref.read(cartProvider.notifier).setItemTarifa(index, val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                                Text(
                                  '$currencySymbol${CurrencyHelper.formatAmount(item.subtotal, currencyIso)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Cómputo Total y Checkout
        if (cart.items.isNotEmpty) ...[
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Método de Pago',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['EFECTIVO', 'TARJETA', 'TR/QR', 'MIXTO'].map((metodo) {
                    final bool isSel = cart.metodoPago == metodo;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: InkWell(
                          onTap: () => ref.read(cartProvider.notifier).setMetodoPago(metodo),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSel
                                  ? const LinearGradient(
                                      colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                                    )
                                  : null,
                              color: isSel ? null : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? const Color(0xFF00F0FF).withOpacity(0.3) : Colors.white10,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                metodo,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSel ? Colors.white : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL:',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$currencySymbol${CurrencyHelper.formatAmount(cart.total, currencyIso)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF00F0FF),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: (isCheckingOut || !isCajaAbierta) ? null : () => onCheckout(cart, modalContext),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isCajaAbierta
                          ? const LinearGradient(
                              colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isCajaAbierta ? null : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: isCajaAbierta
                          ? null
                          : Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                      boxShadow: isCajaAbierta
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00F0FF).withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCheckingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isCajaAbierta ? 'CONFIRMAR PAGO' : 'CAJA CERRADA (ABRA TURNO)',
                              style: GoogleFonts.plusJakartaSans(
                                color: isCajaAbierta ? Colors.white : Colors.white24,
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
          ),
        ],
      ],
    );
  }
}
