import 'package:intl/intl.dart';

class MonthKey {
  MonthKey._();

  static const _months = <String>[
    'Januar','Februar','März','April','Mai','Juni','Juli','August','September','Oktober','November','Dezember',
  ];

  static String current() => fromDate(DateTime.now());

  static String fromDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  static DateTime toDate(String month) {
    final parts = month.split('-');
    if (parts.length != 2) throw const FormatException('Ungültiger Monat.');
    final year = int.parse(parts[0]);
    final monthNumber = int.parse(parts[1]);
    if (monthNumber < 1 || monthNumber > 12) throw const FormatException('Ungültiger Monat.');
    return DateTime(year, monthNumber, 1);
  }

  static String add(String month, int delta) {
    final date = toDate(month);
    return fromDate(DateTime(date.year, date.month + delta, 1));
  }

  static int compare(String a, String b) => a.compareTo(b);

  static String label(String month) {
    final date = toDate(month);
    return '${_months[date.month - 1]} ${date.year}';
  }

  static String shortLabel(String month) {
    final date = toDate(month);
    return '${_months[date.month - 1].substring(0, 3)} ${date.year}';
  }
}

class Money {
  Money._();

  static final NumberFormat _currency = NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);
  static final NumberFormat _decimal = NumberFormat.currency(locale: 'de_DE', symbol: '', decimalDigits: 2);

  static String format(int cents) => _currency.format(cents / 100);
  static String formatPlain(int cents) => _decimal.format(cents / 100).trim();

  static int parseCents(Object? raw) {
    if (raw == null) throw const FormatException('Bitte einen Betrag eingeben.');
    var value = raw.toString().replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ').replaceAll('€', '').trim().replaceAll(RegExp(r'\s+'), '');
    if (value.isEmpty) throw const FormatException('Bitte einen Betrag eingeben.');
    if (value.startsWith('+')) value = value.substring(1);
    if (value.startsWith('-')) throw const FormatException('Der Betrag darf nicht negativ sein.');

    final comma = value.lastIndexOf(',');
    final dot = value.lastIndexOf('.');
    if (comma >= 0 && dot >= 0) {
      if (comma > dot) {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
    } else if (comma >= 0) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (dot >= 0) {
      final dots = '.'.allMatches(value).length;
      final digitsAfter = value.length - dot - 1;
      if (dots > 1 || digitsAfter == 3) value = value.replaceAll('.', '');
    }

    final parsed = double.tryParse(value);
    if (parsed == null || !parsed.isFinite) throw const FormatException('Ungültiger Betrag. Beispiel: 1.500,00 oder 1500,00');
    return (parsed * 100).round();
  }

  static String formatPercent(int milliPercent) {
    final value = milliPercent / 1000;
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return '${formatted.replaceAll('.', ',')} %';
  }

  static String formatPercentPlain(int milliPercent) => formatPercent(milliPercent).replaceAll('%', '').trim();

  static int parseMilliPercent(Object? raw) {
    if (raw == null) throw const FormatException('Bitte einen Prozentwert eingeben.');
    final value = raw.toString().replaceAll('\u00A0', ' ').replaceAll('%', '').trim().replaceAll(' ', '').replaceAll(',', '.');
    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0 || parsed > 100) throw const FormatException('Der Anteil muss zwischen 0 und 100 % liegen.');
    return (parsed * 1000).round();
  }

  static int share(int cents, int milliPercent) {
    if (cents <= 0 || milliPercent <= 0) return 0;
    return (cents * milliPercent + 50000) ~/ 100000;
  }
}
