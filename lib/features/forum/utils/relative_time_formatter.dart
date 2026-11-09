import 'package:intl/intl.dart';

class RelativeTimeFormatter {
  static String format(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      final hourFormat = DateFormat('HH:mm');
      return 'Hier à ${hourFormat.format(dateTime)}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('d MMM yyyy', 'fr_FR').format(dateTime);
    }
  }
}
