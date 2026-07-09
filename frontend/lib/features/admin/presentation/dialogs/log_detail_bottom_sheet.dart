import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../data/models/auditoria_model.dart';
import '../utils/auditoria_formatters.dart';

void showLogDetail(BuildContext context, AuditoriaModel log, String currencyIso, String currencySymbol, String barTimezone) {
  final format = DateFormat('dd MMMM yyyy, HH:mm:ss');
  final localFecha = TimezoneHelper.convertToBarTime(log.fecha, barTimezone);
  final dateStr = format.format(localFecha);

  Color actionColor = AppTheme.liquidPrimary;
  IconData actionIcon = Icons.info_outline;

  if (log.accion == 'Crear') {
    actionColor = AppTheme.colorSuccess;
    actionIcon = Icons.add_circle_outline;
  } else if (log.accion == 'Editar') {
    actionColor = Colors.orangeAccent;
    actionIcon = Icons.edit_outlined;
  } else if (log.accion == 'Eliminar') {
    actionColor = AppTheme.colorWarning;
    actionIcon = Icons.delete_outline;
  } else if (log.accion == 'Inicio de Sesión') {
    actionColor = Colors.cyanAccent;
    actionIcon = Icons.vpn_key_outlined;
  } else if (log.accion == 'Inicio de Sesión Fallido') {
    actionColor = AppTheme.colorDanger;
    actionIcon = Icons.gpp_bad_outlined;
  }

  final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

  Widget buildContent(BuildContext context, bool isDialog) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.liquidSurfaceContainerLow,
        borderRadius: isDialog
            ? BorderRadius.circular(24.0)
            : const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: isDialog
            ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
            : null,
      ),
      padding: EdgeInsets.fromLTRB(
        24.0,
        12.0,
        24.0,
        isDialog ? 24.0 : 12.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDialog)
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(actionIcon, color: actionColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AuditoriaFormatters.formatMessageWithCurrency(
                    log.detalles?['mensaje'],
                    currencyIso,
                    currencySymbol,
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: Colors.white10),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.folder_open_outlined, 'Módulo', AuditoriaFormatters.formatModulo(log.modulo)),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Usuario',
                    '${log.usuarioNombre ?? "Desconocido"} (${log.rolNombre.toLowerCase()})',
                  ),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Fecha ($barTimezone)', dateStr),
                  if (log.ipAddress != null)
                    _buildDetailRow(Icons.network_wifi_outlined, 'Dirección IP', AuditoriaFormatters.formatIpAddress(log.ipAddress)),
                  if (log.dispositivo != null)
                    _buildDetailRow(Icons.devices_outlined, 'Dispositivo/User Agent', log.dispositivo!),
                  
                  const SizedBox(height: 16),

                  _buildLogMetadataDetail(log, currencyIso, currencySymbol),
                  
                  // Render detailed changes if 'cambios' exists
                  if (log.detalles != null && log.detalles!['cambios'] != null) ...[
                    Text(
                      'CAMBIOS REALIZADOS',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: AppTheme.liquidPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildChangesList(log.detalles!['cambios'], currencyIso, currencySymbol),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  if (isTabletLandscape) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: buildContent(context, true),
          ),
        );
      },
    );
  } else {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.liquidSurfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        final maxHeight = screenHeight * 0.75; 

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: bottomInset > 0 ? bottomInset : bottomPadding,
            ),
            child: buildContent(context, false),
          ),
        );
      },
    );
  }
}

Widget _buildLogMetadataDetail(AuditoriaModel log, String currencyIso, String currencySymbol) {
  if (log.detalles == null) return const SizedBox.shrink();
  final det = log.detalles!;
  
  final action = log.accion;
  if (action != 'REGISTRAR_VENTA' && 
      action != 'APERTURA' && 
      action != 'CIERRE' && 
      action != 'REGISTRAR_MOVIMIENTO') {
    return const SizedBox.shrink();
  }

  String title = '';
  List<Widget> items = [];

  if (action == 'REGISTRAR_VENTA') {
    title = 'DETALLES DE LA VENTA';
    final totalVal = double.tryParse(det['total']?.toString() ?? '0') ?? 0.0;
    final metodo = det['metodo_pago']?.toString() ?? 'Desconocido';
    final itemsCount = det['cantidad_items']?.toString() ?? '0';
    final ventaId = det['venta_id']?.toString() ?? '';
    
    items = [
      _buildMetadataItem('ID Venta', ventaId.length > 8 ? '#${ventaId.substring(0, 8)}' : '#$ventaId', icon: Icons.receipt_long_outlined),
      _buildMetadataItem('Total Procesado', '$currencySymbol${CurrencyHelper.formatAmount(totalVal, currencyIso)}', isHighlight: true, highlightColor: AppTheme.colorSuccess, icon: Icons.monetization_on_outlined),
      _buildMetadataItem('Método de Pago', metodo, icon: Icons.payment_outlined),
      _buildMetadataItem('Cantidad de Items', itemsCount, icon: Icons.shopping_bag_outlined),
    ];
  } else if (action == 'APERTURA') {
    title = 'APERTURA DE CAJA';
    final montoInicialVal = double.tryParse(det['monto_inicial']?.toString() ?? '0') ?? 0.0;
    final cajaId = det['caja_id']?.toString() ?? '';

    items = [
      _buildMetadataItem('ID Caja', cajaId.length > 8 ? '#${cajaId.substring(0, 8)}' : '#$cajaId', icon: Icons.folder_open_outlined),
      _buildMetadataItem('Monto Inicial', '$currencySymbol${CurrencyHelper.formatAmount(montoInicialVal, currencyIso)}', isHighlight: true, highlightColor: AppTheme.liquidPrimary, icon: Icons.account_balance_wallet_outlined),
    ];
  } else if (action == 'CIERRE') {
    title = 'RESUMEN DE CIERRE DE CAJA';
    final montoInicialVal = double.tryParse(det['monto_inicial']?.toString() ?? '0') ?? 0.0;
    final montoFinalVal = double.tryParse(det['monto_final']?.toString() ?? '0') ?? 0.0;
    final ventasVal = double.tryParse(det['ventas_totales']?.toString() ?? '0') ?? 0.0;
    final comisionesVal = double.tryParse(det['comisiones_pagadas']?.toString() ?? '0') ?? 0.0;
    final ingresosVal = double.tryParse(det['ingresos_manuales']?.toString() ?? '0') ?? 0.0;
    final egresosVal = double.tryParse(det['egresos_manuales']?.toString() ?? '0') ?? 0.0;
    final esperadoVal = double.tryParse(det['balance_esperado']?.toString() ?? '0') ?? 0.0;
    final cajaId = det['caja_id']?.toString() ?? '';

    items = [
      _buildMetadataItem('ID Caja', cajaId.length > 8 ? '#${cajaId.substring(0, 8)}' : '#$cajaId', icon: Icons.folder_open_outlined),
      _buildMetadataItem('Monto Inicial', '$currencySymbol${CurrencyHelper.formatAmount(montoInicialVal, currencyIso)}', icon: Icons.account_balance_wallet_outlined),
      _buildMetadataItem('Ventas Totales (+)', '$currencySymbol${CurrencyHelper.formatAmount(ventasVal, currencyIso)}', highlightColor: AppTheme.colorSuccess, icon: Icons.add_circle_outline),
      _buildMetadataItem('Ingresos Manuales (+)', '$currencySymbol${CurrencyHelper.formatAmount(ingresosVal, currencyIso)}', icon: Icons.arrow_upward_outlined),
      _buildMetadataItem('Egresos Manuales (-)', '$currencySymbol${CurrencyHelper.formatAmount(egresosVal, currencyIso)}', icon: Icons.arrow_downward_outlined),
      _buildMetadataItem('Comisiones Pagadas (-)', '$currencySymbol${CurrencyHelper.formatAmount(comisionesVal, currencyIso)}', highlightColor: AppTheme.colorDanger, icon: Icons.percent_outlined),
      _buildMetadataItem('Balance Esperado', '$currencySymbol${CurrencyHelper.formatAmount(esperadoVal, currencyIso)}', icon: Icons.calculate_outlined),
      _buildMetadataItem('Monto Final Registrado', '$currencySymbol${CurrencyHelper.formatAmount(montoFinalVal, currencyIso)}', isHighlight: true, highlightColor: AppTheme.liquidPrimary, icon: Icons.price_check_outlined),
    ];
  } else if (action == 'REGISTRAR_MOVIMIENTO') {
    title = 'DETALLES DE MOVIMIENTO';
    final tipo = det['tipo']?.toString() ?? '';
    final montoVal = double.tryParse(det['monto']?.toString() ?? '0') ?? 0.0;
    final concepto = det['concepto']?.toString() ?? 'Sin concepto';
    final metodo = det['metodo_pago']?.toString() ?? 'Efectivo';
    final movId = det['movimiento_id']?.toString() ?? '';

    final isIngreso = tipo.toUpperCase() == 'INGRESO';
    final tipoColor = isIngreso ? AppTheme.colorSuccess : AppTheme.colorDanger;
    final tipoIcon = isIngreso ? Icons.arrow_upward_outlined : Icons.arrow_downward_outlined;

    items = [
      _buildMetadataItem('ID Movimiento', movId.length > 8 ? '#${movId.substring(0, 8)}' : '#$movId', icon: Icons.receipt_outlined),
      _buildMetadataItem('Tipo de Movimiento', isIngreso ? 'Ingreso' : 'Egreso', highlightColor: tipoColor, icon: tipoIcon),
      _buildMetadataItem('Monto', '$currencySymbol${CurrencyHelper.formatAmount(montoVal, currencyIso)}', isHighlight: true, highlightColor: tipoColor, icon: Icons.monetization_on_outlined),
      _buildMetadataItem('Concepto', concepto, icon: Icons.label_outline),
      _buildMetadataItem('Método de Pago', metodo, icon: Icons.payment_outlined),
    ];
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: AppTheme.liquidPrimary,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: AppTheme.liquidSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          children: items,
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}

Widget _buildMetadataItem(String label, String value, {bool isHighlight = false, Color? highlightColor, IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: (highlightColor ?? Colors.white70).withOpacity(0.7)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? (highlightColor ?? AppTheme.liquidPrimary) : (highlightColor ?? Colors.white),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.liquidOnSurfaceVariant.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: AppTheme.liquidOnSurfaceVariant.withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildChangesList(Map<String, dynamic> cambios, String currencyIso, String currencySymbol) {
  return Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: AppTheme.liquidSurfaceContainerHigh,
      borderRadius: BorderRadius.circular(16.0),
      border: Border.all(color: Colors.white.withOpacity(0.04)),
    ),
    child: Column(
      children: cambios.entries.map((entry) {
        final field = entry.key;
        var de = entry.value['de']?.toString() ?? 'vacío';
        var a = entry.value['a']?.toString() ?? 'vacío';

        final isCurrencyField = field == 'precio' ||
            field == 'comision' ||
            field == 'monto' ||
            field == 'diferencia' ||
            field == 'precio_unitario' ||
            field == 'monto_apertura' ||
            field == 'monto_cierre' ||
            field == 'monto_real';

        if (isCurrencyField) {
          final deNum = double.tryParse(de);
          if (deNum != null) {
            de = '$currencySymbol${CurrencyHelper.formatAmount(deNum, currencyIso)}';
          }
          final aNum = double.tryParse(a);
          if (aNum != null) {
            a = '$currencySymbol${CurrencyHelper.formatAmount(aNum, currencyIso)}';
          }
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AuditoriaFormatters.formatFieldKey(field),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: AppTheme.colorDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        de,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.colorDanger,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Icon(Icons.arrow_forward, size: 16, color: Colors.white24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: AppTheme.colorSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        a,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.colorSuccess,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
