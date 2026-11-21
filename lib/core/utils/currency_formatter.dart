abstract final class AppCurrencyFormatter {
  static String formatInr(double amount) {
    final intVal = amount.round();
    final str = intVal.toString();
    if (str.length <= 3) return '₹$str';

    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    final formattedRemaining = remaining.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '₹$formattedRemaining,$lastThree';
  }
}
