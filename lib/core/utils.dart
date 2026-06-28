import 'package:intl/intl.dart';

class AppUtils {
  static final _numFmt = NumberFormat('#,##0.##', 'ar_SA');
  static final _moneyFmt = NumberFormat('#,##0.00', 'ar_SA');
  static final _dateFmt = DateFormat('yyyy/MM/dd');
  static final _dateTimeFmt = DateFormat('yyyy/MM/dd  hh:mm a');

  static String num(double v) => _numFmt.format(v);
  static String money(double v, {String cur = 'ريال'}) => '${_moneyFmt.format(v)} $cur';
  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try { return _dateFmt.format(DateTime.parse(iso)); } catch (_) { return iso; }
  }
  static String dateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try { return _dateTimeFmt.format(DateTime.parse(iso)); } catch (_) { return iso; }
  }
  static String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  static String monthYear(int m, int y) {
    const months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو',
                    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${months[m]} $y';
  }
  static String arabicMonth(String yyyyMM) {
    try {
      final parts = yyyyMM.split('-');
      return monthYear(int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) { return yyyyMM; }
  }
  static bool isOverdue(String? dueDate, String status) {
    if (dueDate == null || status == 'paid' || status == 'cancelled') return false;
    return DateTime.tryParse(dueDate)?.isBefore(DateTime.now()) ?? false;
  }
  static String padNum(int n, {int width = 6}) => n.toString().padLeft(width, '0');
}
