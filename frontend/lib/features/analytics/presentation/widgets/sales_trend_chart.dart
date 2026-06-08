import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import '../../../caja/providers/caja_provider.dart';
import '../../data/models/analytics_resumen_model.dart';

class SalesTrendChart extends ConsumerWidget {
  final List<DailySalesModel> trend;

  const SalesTrendChart({super.key, required this.trend});

  String _formatDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return '';
    }
  }

  Map<int, double> _computeSalesByDayOfWeek() {
    final Map<int, double> daySales = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (final item in trend) {
      try {
        final date = DateTime.parse(item.fecha);
        daySales[date.weekday] = (daySales[date.weekday] ?? 0.0) + item.total;
      } catch (_) {}
    }
    return daySales;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    if (trend.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(28.0),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded, size: 64.0, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 16.0),
            Text(
              'No hay datos de ventas disponibles',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              'Prueba seleccionando un rango de fechas diferente o verifica que se hayan registrado ventas.',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.3),
                fontSize: 12.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final double maxVal = trend.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal == 0 ? 100 : maxVal * 1.25;

    // Calcular días de la semana más fuertes
    final dayOfWeekSales = _computeSalesByDayOfWeek();
    int bestDay = 1;
    double maxDayVal = 0;
    dayOfWeekSales.forEach((key, val) {
      if (val > maxDayVal) {
        maxDayVal = val;
        bestDay = key;
      }
    });

    final String peakDayName = _formatDayOfWeek(bestDay);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Gráfica Lineal de Tendencia
        Container(
          height: 300,
          padding: const EdgeInsets.fromLTRB(12.0, 24.0, 24.0, 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12.0, bottom: 16.0),
                child: Text(
                  'Picos de Ingresos Diarios',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.04),
                        strokeWidth: 1.0,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (trend.length / 5).clamp(1, 100).toDouble(),
                          getTitlesWidget: (value, meta) {
                            final int idx = value.toInt();
                            if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                            try {
                              final date = DateTime.parse(trend[idx].fecha);
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(
                                  DateFormat('dd/MM').format(date),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            } catch (_) {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          getTitlesWidget: (value, meta) {
                            if (value == meta.max) return const SizedBox.shrink();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 6.0,
                              child: Text(
                                value >= 1000
                                    ? '${(value / 1000).toStringAsFixed(0)}k'
                                    : value.toStringAsFixed(0),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (trend.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) => const Color(0xFF111317),
                        tooltipRoundedRadius: 8.0,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((barSpot) {
                            final int idx = barSpot.x.toInt();
                            final item = trend[idx];
                            try {
                              final date = DateTime.parse(item.fecha);
                              final formattedDate = DateFormat('dd MMM, yyyy').format(date);
                              return LineTooltipItem(
                                '$formattedDate\n',
                                GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 10.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${item.total.toStringAsFixed(2)} $currencySymbol',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF00F0FF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              );
                            } catch (_) {
                              return null;
                            }
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          trend.length,
                          (index) => FlSpot(index.toDouble(), trend[index].total),
                        ),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7000FF).withOpacity(0.25),
                              const Color(0xFF00F0FF).withOpacity(0.02),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. Resumen Día Más Fuerte
        if (maxDayVal > 0) ...[
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0x1A00F0FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on, color: Color(0xFF00F0FF), size: 24.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Día de Mayor Venta',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white38,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        peakDayName,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${maxDayVal.toStringAsFixed(2)} $currencySymbol',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF00F0FF),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // 3. Distribución por Día de la Semana
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(28.0),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ventas por Día de la Semana',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20.0),
              ...List.generate(7, (index) {
                final int weekday = index + 1;
                final double revenue = dayOfWeekSales[weekday] ?? 0.0;
                final String dayName = _formatDayOfWeek(weekday);
                final double percent = maxDayVal == 0 ? 0.0 : (revenue / maxDayVal);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dayName,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${revenue.toStringAsFixed(2)} $currencySymbol',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Container(
                          height: 8.0,
                          color: Colors.white.withOpacity(0.03),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percent.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: weekday == bestDay
                                      ? [const Color(0xFF00F0FF), const Color(0xFF90F9FF)]
                                      : [const Color(0xFF7000FF).withOpacity(0.6), const Color(0xFF7000FF)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
