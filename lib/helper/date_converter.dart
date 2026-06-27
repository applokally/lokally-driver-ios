import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DateConverter {
  static const String _apiDateTimePattern = 'yyyy-MM-dd HH:mm:ss';
  static const String _apiShortDateTimePattern = 'yyyy-MM-dd HH:mm';
  static const String _apiDatePattern = 'yyyy-MM-dd';
  static const String _apiIsoMillisecondsPattern = 'yyyy-MM-ddTHH:mm:ss.SSS';

  static const String _displayDatePattern = 'dd/MM/yyyy';
  static const String _displayDateTimePattern = "dd/MM/yyyy 'às' HH:mm";
  static const String _displayMonthYearPattern = 'MM/yyyy';

  /// Mantido no padrão técnico da API.
  /// Não utilizar este método para textos exibidos ao motorista.
  static String formatDate(DateTime dateTime) {
    return DateFormat(_apiDateTimePattern).format(dateTime);
  }

  static String dateToTimeOnly(DateTime dateTime) {
    return _formatTime(dateTime);
  }

  static String dateToDateAndTime(DateTime dateTime) {
    return _formatDateTime(dateTime);
  }

  static String dateToDateAndTimeAm(DateTime dateTime) {
    return _formatDateTime(dateTime);
  }

  static String dateTimeStringToDateTime(String dateTime) {
    return _formatDateTime(
      DateFormat(_apiDateTimePattern).parse(dateTime),
    );
  }

  static String dateTimeStringToDateOnly(String dateTime) {
    return DateFormat('dd').format(
      DateFormat('yyyy-MM-ddTHH:mm:ss').parse(dateTime),
    );
  }

  static String dateTimeStringToMonthAndYear(String dateTime) {
    return DateFormat(_displayMonthYearPattern).format(
      DateFormat('yyyy-MM-ddTHH:mm:ss').parse(dateTime),
    );
  }

  static DateTime dateTimeStringToDate(String dateTime) {
    return DateFormat(_apiDateTimePattern).parse(dateTime);
  }

  static DateTime isoStringToLocalDate(String dateTime) {
    return DateFormat(_apiIsoMillisecondsPattern)
        .parse(dateTime, true)
        .toLocal();
  }

  static String isoStringToLocalString(String dateTime) {
    return _formatDateTime(DateTime.parse(dateTime).toLocal());
  }

  static String isoStringToDateTimeString(String dateTime) {
    return _formatDateTime(isoStringToLocalDate(dateTime));
  }

  static String isoStringToLocalDateOnly(String dateTime) {
    return _formatDate(isoStringToLocalDate(dateTime));
  }

  static String stringToLocalDateOnly(String dateTime) {
    return _formatDate(DateFormat(_apiDatePattern).parse(dateTime));
  }

  /// Mantido no padrão técnico da API.
  /// Não utilizar este método para textos exibidos ao motorista.
  static String localDateToIsoString(DateTime dateTime) {
    return DateFormat(_apiIsoMillisecondsPattern).format(dateTime);
  }

  static String convertTimeToTime(String time) {
    return _formatTime(DateFormat('HH:mm').parse(time));
  }

  static DateTime convertStringTimeToDate(String time) {
    return DateFormat('HH:mm').parse(time);
  }

  static String isoDateTimeStringToLocalTime(String dateTime) {
    return _formatTime(isoStringToLocalDate(dateTime));
  }

  static String isoDateTimeStringToDifferentWithCurrentTime(String dateTime) {
    final DateTime messageTime = isoStringToLocalDate(dateTime);
    final int minutes = DateTime.now().difference(messageTime).inMinutes;

    if (minutes <= 20) {
      return '$minutes ${'min_ago'.tr}';
    } else if (minutes <= 1440) {
      return _formatTime(messageTime);
    } else if (minutes <= 2880) {
      return '${'yesterday'.tr}, ${_formatTime(messageTime)}';
    } else {
      return isoStringToDateTimeString(dateTime);
    }
  }

  static String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String _formatDate(DateTime dateTime) {
    return DateFormat(_displayDatePattern).format(dateTime);
  }

  static String _formatDateTime(DateTime dateTime) {
    return DateFormat(_displayDateTimePattern).format(dateTime);
  }

  static String convertFromMinute(
    int minMinute, {
    bool returnValue = false,
    bool returnType = false,
  }) {
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
    return _formatDateTime(dateTime.toLocal());
  }

  static String localToIsoString(DateTime dateTime) {
    return _formatDate(dateTime.toLocal());
  }

  static String isoDateTimeStringToDateOnly(String dateTime) {
    return _formatDate(DateTime.parse(dateTime).toLocal());
  }

  static String isoStringToLocalDateAndMonthOnly(String dateTime) {
    return _formatDate(isoStringToLocalDate(dateTime));
  }

  static String localDateTimeToDateAndMonthOnly(DateTime dateTime) {
    return _formatDate(dateTime);
  }

  static String stringToLocalDateTime(String dateTime) {
    return _formatDateTime(
      DateFormat(_apiShortDateTimePattern).parse(dateTime),
    );
  }

  static String isoStringToTripDetailsDateTime(String dateTime) {
    return _formatDateTime(isoStringToLocalDate(dateTime));
  }

  static String stringDateTimeToTimeOnly(String dateTime) {
    return _formatTime(
      DateFormat(_apiShortDateTimePattern).parse(dateTime),
    );
  }

  static String tripDetailsShowFormat(String dateTime) {
    return _formatDateTime(
      DateFormat(_apiDateTimePattern).parse(dateTime),
    );
  }

  static int findTimeDifference(String dateTime) {
    final DateTime createTime = DateTime.parse(dateTime);

    return createTime.difference(DateTime.now()).inMinutes + 1;
  }

  static String getMinutesToDayHourMinutes(int value) {
    final Duration duration = Duration(minutes: value);
    final int days = duration.inDays;
    final int hours = duration.inHours % 24;
    final int minutes = duration.inMinutes % 60;

    return [
      if (days > 0) '$days ${'days'.tr}',
      if (hours > 0 || days > 0) '$hours ${'hours'.tr}',
      '$minutes ${'minute'.tr}',
    ].join(' ');
  }
}
