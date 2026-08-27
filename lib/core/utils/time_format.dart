/// Display helpers for clocks and countdowns.
abstract final class TimeFormat {
  static String two(int n) => n.toString().padLeft(2, '0');

  static String hhmm(DateTime time) {
    final local = time.toLocal();
    return '${two(local.hour)}:${two(local.minute)}';
  }

  static String hhmmss(Duration diff) {
    final safe = diff.isNegative ? Duration.zero : diff;
    return '${two(safe.inHours)}:${two(safe.inMinutes % 60)}:${two(safe.inSeconds % 60)}';
  }

  static String format12h(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = two(local.minute);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
