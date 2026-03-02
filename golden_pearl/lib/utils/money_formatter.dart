class MoneyFormatter {
  static const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  static String format(int halalas, String locale, {bool showFraction = false}) {
    final riyals = halalas ~/ 100;
    final fraction = halalas % 100;

    if (locale == 'ar') {
      return _formatArabic(riyals, fraction, showFraction);
    }
    return _formatEnglish(riyals, fraction, showFraction);
  }

  static String _formatEnglish(int riyals, int fraction, bool showFraction) {
    final formatted = _addCommas(riyals.toString());
    if (showFraction && fraction > 0) {
      return 'SAR $formatted.${fraction.toString().padLeft(2, '0')}';
    }
    return 'SAR $formatted';
  }

  static String _formatArabic(int riyals, int fraction, bool showFraction) {
    final formatted = _toArabicDigits(_addArabicCommas(riyals.toString()));
    if (showFraction && fraction > 0) {
      final frac = _toArabicDigits(fraction.toString().padLeft(2, '0'));
      return '$formatted٫$frac ر.س';
    }
    return '$formatted ر.س';
  }

  static String _addCommas(String number) {
    final result = StringBuffer();
    int count = 0;
    for (int i = number.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write(',');
      }
      result.write(number[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }

  static String _addArabicCommas(String number) {
    final result = StringBuffer();
    int count = 0;
    for (int i = number.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result.write('\u066C');
      }
      result.write(number[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }

  static String _toArabicDigits(String input) {
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      final digit = int.tryParse(char);
      if (digit != null) {
        buffer.write(_arabicDigits[digit]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
