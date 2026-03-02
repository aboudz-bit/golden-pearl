class ArabicDigits {
  static const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  static String convert(dynamic number, String locale) {
    if (locale != 'ar') return number.toString();
    final str = number.toString();
    final buffer = StringBuffer();
    for (final char in str.split('')) {
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
