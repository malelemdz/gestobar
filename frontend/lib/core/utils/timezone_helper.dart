import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class TimezoneHelper {
  /// Converts a [DateTime] (usually UTC) to a [DateTime] representing the same moment in
  /// the target [timezoneName] (e.g. 'America/La_Paz', 'Europe/Madrid').
  static DateTime convertToBarTime(DateTime utcDateTime, String timezoneName) {
    try {
      if (tz.timeZoneDatabase.locations.isEmpty) {
        tz_data.initializeTimeZones();
      }
      final location = tz.getLocation(timezoneName);
      // Ensure the datetime is interpreted as UTC if it is not explicitly local
      final utcDateTimeResolved = utcDateTime.isUtc ? utcDateTime : utcDateTime.toUtc();
      return tz.TZDateTime.from(utcDateTimeResolved, location);
    } catch (e) {
      // Fallback to local device time if timezone location is not found/invalid
      return utcDateTime.toLocal();
    }
  }

  /// Formatea la hora actual del bar en formato de reloj de 24 horas ('HH:mm:ss').
  static String formatToClock(DateTime dateTime, String timezoneName) {
    final localDateTime = convertToBarTime(dateTime, timezoneName);
    return DateFormat('HH:mm:ss').format(localDateTime);
  }

  /// Formatea la fecha y hora en formato 'dd/MM/yyyy • HH:mm' de acuerdo a la zona horaria del bar.
  static String formatToDateTime(DateTime dateTime, String timezoneName) {
    final localDateTime = convertToBarTime(dateTime, timezoneName);
    return DateFormat('dd/MM/yyyy • HH:mm').format(localDateTime);
  }

  /// Formatea la fecha y hora en formato 'dd MMMM yyyy, HH:mm:ss' para detalles.
  static String formatToFullDateTime(DateTime dateTime, String timezoneName) {
    final localDateTime = convertToBarTime(dateTime, timezoneName);
    return DateFormat('dd MMMM yyyy, HH:mm:ss').format(localDateTime);
  }

  /// Formatea en hora y minuto 'HH:mm'.
  static String formatToHourMinute(DateTime dateTime, String timezoneName) {
    final localDateTime = convertToBarTime(dateTime, timezoneName);
    return DateFormat('HH:mm').format(localDateTime);
  }
}
