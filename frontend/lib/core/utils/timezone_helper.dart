import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
}
