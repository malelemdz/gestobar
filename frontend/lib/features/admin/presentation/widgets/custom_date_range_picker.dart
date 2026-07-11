import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final bool isDialog;

  const CustomDateRangePicker({
    super.key,
    this.initialRange,
    this.isDialog = false,
  });

  static Future<DateTimeRange?> show(BuildContext context, DateTimeRange? initialRange) async {
    final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

    if (isTabletLandscape) {
      return showDialog<DateTimeRange>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.85),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
              child: CustomDateRangePicker(
                initialRange: initialRange,
                isDialog: true,
              ),
            ),
          );
        },
      );
    } else {
      return showModalBottomSheet<DateTimeRange>(
        context: context,
        backgroundColor: AppTheme.liquidSurfaceContainerLow,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
        ),
        builder: (context) {
          return CustomDateRangePicker(
            initialRange: initialRange,
            isDialog: false,
          );
        },
      );
    }
  }

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _focusedMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialRange?.start;
    _endDate = widget.initialRange?.end;
    _focusedMonth = _startDate ?? DateTime.now();
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
  }

  int _daysInMonth(DateTime date) {
    var firstDayOfNextMonth = DateTime(date.year, date.month + 1, 1);
    var lastDayOfThisMonth = firstDayOfNextMonth.subtract(const Duration(days: 1));
    return lastDayOfThisMonth.day;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<DateTime> _generateCalendarDays() {
    final days = <DateTime>[];
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    
    final pad = firstDay.weekday - 1;
    
    final prevMonth = DateTime(year, month - 1, 1);
    final daysInPrevMonth = _daysInMonth(prevMonth);
    for (int i = pad - 1; i >= 0; i--) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i));
    }
    
    final daysInCurrentMonth = _daysInMonth(firstDay);
    for (int i = 1; i <= daysInCurrentMonth; i++) {
      days.add(DateTime(year, month, i));
    }
    
    final totalCells = 42;
    final nextMonth = DateTime(year, month + 1, 1);
    final remaining = totalCells - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(nextMonth.year, nextMonth.month, i));
    }
    
    return days;
  }

  void _onDayTapped(DateTime day) {
    final normDay = _normalizeDate(day);
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = normDay;
        _endDate = null;
      } else {
        if (normDay.isBefore(_startDate!)) {
          _startDate = normDay;
          _endDate = null;
        } else {
          _endDate = normDay;
        }
      }
    });
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normStart = _startDate != null ? _normalizeDate(_startDate!) : null;
    final normEnd = _endDate != null ? _normalizeDate(_endDate!) : null;
    
    final df = DateFormat('dd MMM, yyyy', 'es');
    final startText = _startDate != null ? df.format(_startDate!) : 'Fecha Inicio';
    final endText = _endDate != null ? df.format(_endDate!) : 'Fecha Fin';

    final monthName = DateFormat('MMMM yyyy', 'es').format(_focusedMonth);
    final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final days = _generateCalendarDays();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.liquidSurfaceContainerLow,
        borderRadius: widget.isDialog
            ? BorderRadius.circular(24.0)
            : const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: widget.isDialog
            ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
            : null,
      ),
      child: widget.isDialog
          ? Container(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
              child: _buildPickerBody(context, weekdays, days, normStart, normEnd, startText, endText, formattedMonth),
            )
          : SafeArea(
              top: false,
              child: Center(
                heightFactor: 1.0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indicator bar
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
                      const SizedBox(height: 16),
                      _buildPickerBody(context, weekdays, days, normStart, normEnd, startText, endText, formattedMonth),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPickerBody(
    BuildContext context,
    List<String> weekdays,
    List<DateTime> days,
    DateTime? normStart,
    DateTime? normEnd,
    String startText,
    String endText,
    String formattedMonth,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Seleccionar Rango de Fechas',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Wrap calendar content in a Flexible scroll view to support short landscape heights!
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Visual range boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: _startDate != null ? AppTheme.liquidPrimary.withOpacity(0.06) : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _startDate != null ? AppTheme.liquidPrimary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DESDE',
                              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              startText,
                              style: GoogleFonts.poppins(
                                fontSize: 13, 
                                fontWeight: FontWeight.bold, 
                                color: _startDate != null ? Colors.white : Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 14),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: _endDate != null ? AppTheme.liquidPrimary.withOpacity(0.06) : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _endDate != null ? AppTheme.liquidPrimary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HASTA',
                              style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              endText,
                              style: GoogleFonts.poppins(
                                fontSize: 13, 
                                fontWeight: FontWeight.bold, 
                                color: _endDate != null ? Colors.white : Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quick options
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickDateChip('Hoy', () {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, now.day);
                        final end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildQuickDateChip('Ayer', () {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, now.day - 1);
                        final end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildQuickDateChip('Últimos 7 días', () {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, now.day - 6);
                        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildQuickDateChip('Este mes', () {
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, 1);
                        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                        });
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5, color: Colors.white10),
                const SizedBox(height: 12),
                
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                        });
                      },
                    ),
                    Text(
                      formattedMonth,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Weekdays
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekdays.map((day) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white30,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                
                // Days Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final d = days[index];
                    final normD = _normalizeDate(d);
                    
                    final isSelectedStart = normStart != null && normD.isAtSameMomentAs(normStart);
                    final isSelectedEnd = normEnd != null && normD.isAtSameMomentAs(normEnd);
                    final isInRange = normStart != null && normEnd != null && normD.isAfter(normStart) && normD.isBefore(normEnd);
                    final isToday = normD.isAtSameMomentAs(_normalizeDate(DateTime.now()));
                    final isCurrentMonth = normD.month == _focusedMonth.month;

                    BoxDecoration? rangeDecoration;
                    if (isInRange) {
                      rangeDecoration = BoxDecoration(
                        color: AppTheme.liquidPrimary.withOpacity(0.12),
                      );
                    } else if (isSelectedStart && normEnd != null) {
                      rangeDecoration = BoxDecoration(
                        color: AppTheme.liquidPrimary.withOpacity(0.12),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      );
                    } else if (isSelectedEnd) {
                      rangeDecoration = BoxDecoration(
                        color: AppTheme.liquidPrimary.withOpacity(0.12),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                      );
                    }

                    return GestureDetector(
                      onTap: () => _onDayTapped(d),
                      child: Container(
                        decoration: rangeDecoration,
                        child: Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isSelectedStart || isSelectedEnd)
                                  ? AppTheme.liquidPrimary
                                  : Colors.transparent,
                              border: isToday && !(isSelectedStart || isSelectedEnd)
                                  ? Border.all(color: AppTheme.liquidPrimary.withOpacity(0.4), width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${normD.day}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: (isSelectedStart || isSelectedEnd) ? FontWeight.bold : FontWeight.w600,
                                  color: (isSelectedStart || isSelectedEnd)
                                      ? Colors.black
                                      : isCurrentMonth
                                          ? Colors.white
                                          : Colors.white24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Footer buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: _startDate != null ? AppTheme.liquidPrimary : Colors.white.withOpacity(0.04),
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white.withOpacity(0.04),
                  disabledForegroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _startDate != null
                    ? () {
                        final end = _endDate ?? _startDate!;
                        Navigator.pop(
                          context,
                          DateTimeRange(
                            start: DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
                            end: DateTime(end.year, end.month, end.day, 23, 59, 59),
                          ),
                        );
                      }
                    : null,
                child: Text(
                  'Aceptar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _startDate != null ? Colors.black : Colors.white24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
