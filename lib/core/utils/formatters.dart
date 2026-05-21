String formatVnd(num value) {
  final String digits = value.toStringAsFixed(0);
  final StringBuffer buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return '${buf.toString()} đ';
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  final String d = date.day.toString().padLeft(2, '0');
  final String m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String formatDateTime(DateTime? date) {
  if (date == null) return '';
  final String h = date.hour.toString().padLeft(2, '0');
  final String min = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} $h:$min';
}
