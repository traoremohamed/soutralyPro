import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DateConverter {
  static DateTime? parseToLocalDateTime(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty || rawDate.trim() == '-') {
      return null;
    }

    DateTime? parsed = DateTime.tryParse(rawDate);
    parsed ??= DateTime.tryParse(rawDate.replaceFirst(' ', 'T'));
    if (parsed == null) {
      return null;
    }

    return parsed.toLocal();
  }

  static String toFrenchDateTime(String? rawDate, {String fallback = '-'}) {
    final DateTime? localDate = parseToLocalDateTime(rawDate);
    if (localDate == null) {
      return (rawDate == null || rawDate.trim().isEmpty) ? fallback : rawDate;
    }
    return DateFormat("dd MMMM yyyy 'a' HH'h'mm", 'fr_FR').format(localDate);
  }

  static String toFrenchDateOnly(String? rawDate, {String fallback = '-'}) {
    final DateTime? localDate = parseToLocalDateTime(rawDate);
    if (localDate == null) {
      return (rawDate == null || rawDate.trim().isEmpty) ? fallback : rawDate;
    }
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(localDate);
  }

  static String toFrenchTime(String? rawDate, {String fallback = '-'}) {
    final DateTime? localDate = parseToLocalDateTime(rawDate);
    if (localDate == null) {
      return (rawDate == null || rawDate.trim().isEmpty) ? fallback : rawDate;
    }
    return DateFormat("HH'h'mm", 'fr_FR').format(localDate);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd hh:mm:ss a').format(dateTime);
  }

  static String dateToTimeOnly(DateTime dateTime) {
    return DateFormat(_timeFormatter()).format(dateTime);
  }

  static String dateToDateAndTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  static String dateToDateAndTimeAm(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd ${_timeFormatter()}').format(dateTime);
  }

  static String dateTimeStringToDateTime(String dateTime) {
    return toFrenchDateTime(dateTime);
  }

  static String dateTimeStringToDateOnly(String dateTime) {
    return DateFormat('dd')
        .format(DateFormat('yyyy-MM-ddTHH:mm:ss').parse(dateTime));
  }

  static String dateTimeStringToMonthAndYear(String dateTime) {
    return DateFormat('MMM, yyyy')
        .format(DateFormat('yyyy-MM-ddTHH:mm:ss').parse(dateTime));
  }

  static DateTime dateTimeStringToDate(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTime);
  }

  static DateTime isoStringToLocalDate(String dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS')
        .parse(dateTime, true)
        .toLocal();
  }

  static String isoStringToLocalString(String dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.parse(dateTime).toLocal());
  }

  static String isoStringToDateTimeString(String dateTime) {
    return toFrenchDateTime(dateTime);
  }

  static String isoStringToLocalDateOnly(String dateTime) {
    return toFrenchDateOnly(dateTime);
  }

  static String stringToLocalDateOnly(String dateTime) {
    return toFrenchDateOnly(dateTime);
  }

  static String localDateToIsoString(DateTime dateTime) {
    return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').format(dateTime);
  }

  static String convertTimeToTime(String time) {
    return DateFormat(_timeFormatter()).format(DateFormat('HH:mm').parse(time));
  }

  static DateTime convertStringTimeToDate(String time) {
    return DateFormat('HH:mm').parse(time);
  }

  static String isoDateTimeStringToLocalTime(String dateTime) {
    return toFrenchTime(dateTime);
  }

  static String isoDateTimeStringToDifferentWithCurrentTime(String dateTime) {
    DateTime messageTime = isoStringToLocalDate(dateTime);
    int minutes = DateTime.now().difference(messageTime).inMinutes;
    if (minutes <= 20) {
      return '$minutes ${'min_ago'.tr}';
    } else if (minutes > 20 && minutes <= 1440) {
      return DateFormat(_timeFormatter()).format(messageTime);
    } else if (minutes > 1440 && minutes <= 2880) {
      return '${'yesterday'.tr}, ${DateFormat(_timeFormatter()).format(messageTime)}';
    } else {
      return isoStringToDateTimeString(dateTime);
    }
  }

  static String _timeFormatter() {
    return "HH'h'mm";
    // return Get.find<SplashController>().configModel.timeformat == '24' ? 'HH:mm' : 'hh:mm a';
  }

  static String convertFromMinute(int minMinute,
      {bool returnValue = false, bool returnType = false}) {
    int firstValue = minMinute;
    String type = 'min';
    if (minMinute >= 525600) {
      firstValue = (minMinute / 525600).floor();
      type = 'year';
    } else if (minMinute >= 43200) {
      firstValue = (minMinute / 43200).floor();
      type = 'month';
    } else if (minMinute >= 10080) {
      firstValue = (minMinute / 10080).floor();
      type = 'week';
    } else if (minMinute >= 1440) {
      firstValue = (minMinute / 1440).floor();
      type = 'day';
    } else if (minMinute >= 60) {
      firstValue = (minMinute / 60).floor();
      type = 'hour';
    }
    if (returnValue) {
      return '$firstValue';
    } else if (returnType) {
      return type.tr;
    } else {
      return '$firstValue ${type.tr}';
    }
  }

  static String localDateToIsoStringAMPM(DateTime dateTime) {
    return DateFormat('${_timeFormatter()} | d MMMM yyyy ', 'fr_FR')
        .format(dateTime.toLocal());
  }

  static String localToIsoString(DateTime dateTime) {
    return DateFormat('d MMMM, yyyy ', 'fr_FR').format(dateTime.toLocal());
  }

  static String isoDateTimeStringToDateOnly(String dateTime) {
    return toFrenchDateOnly(dateTime);
  }

  static String isoStringToLocalDateAndMonthOnly(String dateTime) {
    return toFrenchDateOnly(dateTime);
  }

  static String localDateTimeToDateAndMonthOnly(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy', 'fr_FR').format(dateTime);
  }

  static String stringToLocalDateTime(String dateTime) {
    return toFrenchDateTime(dateTime);
  }

  static String isoStringToTripDetailsDateTime(String dateTime) {
    return toFrenchDateTime(dateTime);
  }

  static String stringDateTimeToTimeOnly(String dateTime) {
    return DateFormat(_timeFormatter())
        .format(DateFormat('yyyy-MM-dd HH:mm').parse(dateTime));
  }

  static String tripDetailsShowFormat(String dateTime) {
    return toFrenchDateTime(dateTime);
  }

  static int findTimeDifference(String dateTime) {
    DateTime createTime = DateTime.parse(dateTime);

    return createTime.difference(DateTime.now()).inMinutes + 1;
  }

  static String getMinutesToDayHourMinutes(int value) {
    final duration = Duration(minutes: value);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    return [
      if (days > 0) '$days ${'days'.tr}',
      if (hours > 0 || days > 0) '$hours ${'hours'.tr}',
      '$minutes ${'minute'.tr}'
    ].join(' ');
  }
}
