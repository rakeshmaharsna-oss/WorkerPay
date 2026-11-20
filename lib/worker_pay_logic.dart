
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum DayStatus {
  none,
  present,
  absent,
  half,
  holiday,
  leave,
}

class Attendance {
  DayStatus status;
  double hours;
  double ot;

  Attendance({
    this.status = DayStatus.none,
    this.hours = 0,
    this.ot = 0,
  });

  Map<String, dynamic> toJson() => {
    'status': status.index,
    'hours': hours,
    'ot': ot,
  };

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final index = (json['status'] as num?)?.toInt() ?? 0;

    return Attendance(
      status: DayStatus.values[
        index.clamp(0, DayStatus.values.length - 1)
      ],
      hours: (json['hours'] as num?)?.toDouble() ?? 0,
      ot: (json['ot'] as num?)?.toDouble() ?? 0,
    );
  }
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

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      mode: json['mode'] ?? 'fixed',
      monthlySalary:
          (json['monthlySalary'] as num?)?.toDouble() ?? 0,
      workingDays:
          (json['workingDays'] as num?)?.toDouble() ?? 26,
      normalHours:
          (json['normalHours'] as num?)?.toDouble() ?? 8,
      otRate: (json['otRate'] as num?)?.toDouble() ?? 0,
      dailyWage:
          (json['dailyWage'] as num?)?.toDouble() ?? 0,
      advance: (json['advance'] as num?)?.toDouble() ?? 0,
      deduction:
          (json['deduction'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Store {
  static const String _att = 'workerpay_attendance_v3';
  static const String _set = 'workerpay_settings_v3';

  static late SharedPreferences _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<Map<String, Attendance>> loadAttendance() async {
    final raw = _prefs.getString(_att);

    if (raw == null) return {};

    final decoded = jsonDecode(raw);

    if (decoded is! Map) return {};

    final data = Map<String, dynamic>.from(decoded);

    return data.map((key, value) {
      return MapEntry(
        key,
        Attendance.fromJson(
          Map<String, dynamic>.from(value),
        ),
      );
    });
  }

  static Future<Settings> loadSettings() async {
    final raw = _prefs.getString(_set);

    if (raw == null) return Settings();

    return Settings.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw)),
    );
  }

  static Future<void> saveAttendance(
    Map<String, Attendance> attendance,
  ) async {
    await _prefs.setString(
      _att,
      jsonEncode(
        attendance.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      ),
    );
  }

  static Future<void> saveSettings(Settings settings) async {
    await _prefs.setString(
      _set,
      jsonEncode(settings.toJson()),
    );
  }
}

String attendanceKey(DateTime date) {
  return '${date.year}-${date.month}-${date.day}';
}

double calculateWorkingDays(
  Map<String, Attendance> attendance,
  int year,
  int month,
) {
  double total = 0;

  for (final entry in attendance.entries) {
    final parts = entry.key.split('-');

    if (parts.length != 3) continue;

    if (int.tryParse(parts[0]) != year ||
        int.tryParse(parts[1]) != month) {
      continue;
    }

    if (entry.value.status == DayStatus.present) {
      total++;
    } else if (entry.value.status == DayStatus.half) {
      total += 0.5;
    }
  }

  return total;
}

double calculateOvertime(
  Map<String, Attendance> attendance,
  int year,
  int month,
) {
  double total = 0;

  for (final entry in attendance.entries) {
    final parts = entry.key.split('-');

    if (parts.length != 3) continue;

    if (int.tryParse(parts[0]) == year &&
        int.tryParse(parts[1]) == month) {
      total += entry.value.ot;
    }
  }

  return total;
}

double calculateSalary({
  required double workingDays,
  required Settings settings,
  required double overtimeHours,
}) {
  final dailyRate = settings.mode == 'daily'
      ? settings.dailyWage
      : settings.monthlySalary /
          (settings.workingDays > 0
              ? settings.workingDays
              : 26);

  final basic = workingDays * dailyRate;
  final overtime = overtimeHours * settings.otRate;

  return basic +
      overtime -
      settings.advance -
      settings.deduction;
}
