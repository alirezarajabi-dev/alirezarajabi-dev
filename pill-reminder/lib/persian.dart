/// Small helpers for showing numbers and times the way an Iranian elder
/// expects to read them: Persian digits and plain words like «صبح» and «شب».
library;

const _faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// Converts any Latin digits in [input] to Persian digits.
String faDigits(Object input) {
  final s = input.toString();
  final b = StringBuffer();
  for (final ch in s.runes) {
    if (ch >= 0x30 && ch <= 0x39) {
      b.write(_faDigits[ch - 0x30]);
    } else {
      b.writeCharCode(ch);
    }
  }
  return b.toString();
}

/// The part of the day for a 24-hour [hour].
String dayPart(int hour) {
  if (hour >= 4 && hour < 12) return 'صبح';
  if (hour >= 12 && hour < 15) return 'ظهر';
  if (hour >= 15 && hour < 19) return 'عصر';
  return 'شب';
}

/// A friendly 12-hour label such as «۸ صبح» or «۹:۳۰ شب».
String timeLabel(int hour, int minute) {
  var h12 = hour % 12;
  if (h12 == 0) h12 = 12;
  final m = minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
  return faDigits('$h12$m ${dayPart(hour)}');
}

/// A clock-style label such as «۰۸:۳۰».
String clockLabel(int hour, int minute) => faDigits(
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
