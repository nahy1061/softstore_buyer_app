import 'package:intl/intl.dart';

abstract final class Formatters {
  static String pKRCurrency(num amount) {
    return 'Rs ${NumberFormat('#,##0').format(amount)}';
  }

  static String pakistaniPhone(String phone) {
    if (phone.length != 11 || !phone.startsWith('03')) return phone;
    return '${phone.substring(0, 3)}-${phone.substring(3, 6)}-${phone.substring(6)}';
  }

  static String dateFormatted(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String dateWithTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    }

    return dateFormatted(date);
  }

  static String priceWithDiscount(double originalPrice, double discountedPrice) {
    final discount = ((originalPrice - discountedPrice) / originalPrice * 100).toInt();
    return '-$discount%';
  }
}
