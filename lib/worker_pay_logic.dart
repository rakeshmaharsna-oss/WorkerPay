import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primary = Color(0xFF005086);
const Color primaryLight = Color(0xFFE8F4FB);
const Color bg = Color(0xFFF2F8FD);
const Color card = Colors.white;
const Color textDark = Color(0xFF0B1722);
const Color textGrey = Color(0xFF65717C);
const Color border = Color(0xFFD6E0E8);
const Color presentBlue = Color(0xFF005086);
const Color absentRed = Color(0xFFDC2626);
const Color halfOrange = Color(0xFFD97706);
const Color otGreen = Color(0xFF16A34A);

enum DayStatus { none, present, absent, half, holiday, leave }

class Attendance {
  DayStatus status;
  double hours;
  double ot;
  String note;
  bool paidLeave;

  Attendance({
    this.status = DayStatus.none,
    this.hours = 0,
    this.ot = 0,
    this.note = '',
    this.paidLeave = false,
  });

  Map<String, dynamic> toJson() => {
        'status': status.index,
        'hours': hours,
        'ot': ot,
        'note': note,
        'paidLeave': paidLeave,
      };

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        status: DayStatus.values[(j['status'] ?? 0).clamp(0, 5)],
        hours: (j['hours'] ?? 0).toDouble(),
        ot: (j['ot'] ?? 0).toDouble(),
        note: (j['note'] ?? '').toString(),
        paidLeave: j['paidLeave'] == true,
      );
}

class Settings {
  String mode;
  double monthlySalary;
  double workingDays;
  double normalHours;
  double otRate;
  double dailyWage;
  double advance;
  double deduction;

  Settings({
    this.mode = 'fixed',
    this.monthlySalary = 0,
    this.workingDays = 26,
    this.normalHours = 8,
    this.otRate = 0,
    this.dailyWage = 0,
    this.advance = 0,
    this.deduction = 0,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'monthlySalary': monthlySalary,
        'workingDays': workingDays,
        'normalHours': normalHours,
        'otRate': otRate,
        'dailyWage': dailyWage,
        'advance': advance,
        'deduction': deduction,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        mode: j['mode'] ?? 'fixed',
        monthlySalary: (j['monthlySalary'] ?? 0).toDouble(),
        workingDays: (j['workingDays'] ?? 26).toDouble(),
        normalHours: (j['normalHours'] ?? 8).toDouble(),
        otRate: (j['otRate'] ?? 0).toDouble(),
        dailyWage: (j['dailyWage'] ?? 0).toDouble(),
        advance: (j['advance'] ?? 0).toDouble(),
        deduction: (j['deduction'] ?? 0).toDouble(),
      );
}

class Store {
  static const _att = 'workerpay_attendance_v3';
  static const _set = 'workerpay_settings_v3';

  static Future<Map<String, Attendance>> loadAttendance() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_att);
    if (raw == null) return {};

    final m = Map<String, dynamic>.from(jsonDecode(raw));
    return m.map(
      (k, v) => MapEntry(
        k,
        Attendance.fromJson(Map<String, dynamic>.from(v)),
      ),
    );
  }

  static Future<Settings> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_set);

    if (raw == null) return Settings();

    return Settings.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw)),
    );
  }

  static Future<void> saveAttendance(
    Map<String, Attendance> a,
  ) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      _att,
      jsonEncode(
        a.map((k, v) => MapEntry(k, v.toJson())),
      ),
    );
  }

  static Future<void> saveSettings(Settings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_set, jsonEncode(s.toJson()));
  }
}

Color dayFill(DayStatus s) {
  switch (s) {
    case DayStatus.present:
      return const Color(0xFFEAF6FC);
    case DayStatus.absent:
      return const Color(0xFFFFEDEE);
    case DayStatus.half:
      return const Color(0xFFFFF5E5);
    case DayStatus.holiday:
      return const Color(0xFFF1F3F5);
    case DayStatus.leave:
      return const Color(0xFFFFF7CC);
    case DayStatus.none:
      return Colors.white;
  }
}

Color dayBorder(DayStatus s) {
  switch (s) {
    case DayStatus.present:
      return const Color(0xFF9DC8DF);
    case DayStatus.absent:
      return const Color(0xFFF1A5AA);
    case DayStatus.half:
      return const Color(0xFFE9B76D);
    case DayStatus.holiday:
      return border;
    case DayStatus.leave:
      return const Color(0xFFE8CF65);
    case DayStatus.none:
      return border;
  }
}

Color dayText(DayStatus s) {
  switch (s) {
    case DayStatus.present:
      return primary;
    case DayStatus.absent:
      return absentRed;
    case DayStatus.half:
      return halfOrange;
    case DayStatus.holiday:
      return textGrey;
    case DayStatus.leave:
      return const Color(0xFF9A7B00);
    case DayStatus.none:
      return textDark;
  }
}

Map<String, double> monthCounts(
  DateTime month,
  Map<String, Attendance> a,
) {
  double p = 0,
      ab = 0,
      h = 0,
      hol = 0,
      leave = 0,
      paidLeave = 0,
      hrs = 0,
      ot = 0;

  for (int d = 1;
      d <= DateTime(month.year, month.month + 1, 0).day;
      d++) {
    final x = a['${month.year}-${month.month}-$d'];

    if (x == null) continue;

    if (x.status == DayStatus.present) p++;
    if (x.status == DayStatus.absent) ab++;
    if (x.status == DayStatus.half) h++;
    if (x.status == DayStatus.holiday) hol++;
    if (x.status == DayStatus.leave) leave++;

    if (x.status == DayStatus.absent && x.paidLeave) {
      paidLeave++;
    }

    hrs += x.hours;
    ot += x.ot;
  }

  return {
    'present': p,
    'absent': ab,
    'half': h,
    'holiday': hol,
    'leave': leave,
    'paidLeave': paidLeave,
    'hours': hrs,
    'ot': ot,
  };
}

String monthName(DateTime d) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  return '${names[d.month - 1]} ${d.year}';
}

String formatDate(DateTime d) {
  const wd = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  const mo = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]} ${d.year}';
}

String fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String money(double v) => '₹${v.round()}';

double numVal(TextEditingController c, [double fallback = 0]) =>
    double.tryParse(c.text.trim()) ?? fallback;

InputDecoration _inputDecoration(String label) =>
    InputDecoration(labelText: label);
