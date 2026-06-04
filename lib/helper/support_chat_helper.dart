import 'package:ride_sharing_user_app/helper/date_converter.dart';

class SupportChatHelper {
  static List<String> days = [
    '',
    'LUN',
    'MAR',
    'MER',
    'JEU',
    'VEN',
    'SAM',
    'DIM'
  ];

  static DateTime _toLocalDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  static String chatTimeCalculation(String dateTime) {
    final DateTime messageTime =
        DateConverter.parseToLocalDateTime(dateTime) ?? DateTime.now();
    int daysDifference = DateTime.now().difference(messageTime).inDays;
    if (daysDifference > 7) {
      return DateConverter.isoStringToDateTimeString(dateTime);
    } else {
      return '${days[messageTime.weekday]} a ${DateConverter.isoDateTimeStringToLocalTime(dateTime)}';
    }
  }

  static bool isMessageSameDate(String dateTime1, String? dateTIme2) {
    if (dateTIme2 != null) {
      final DateTime messageTime =
          DateConverter.parseToLocalDateTime(dateTime1) ?? DateTime.now();
      final DateTime preMessageTime =
          DateConverter.parseToLocalDateTime(dateTIme2) ?? DateTime.now();
      return _toLocalDay(messageTime) == _toLocalDay(preMessageTime);
    } else {
      return true;
    }
  }
}
