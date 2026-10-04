import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const Color primary = Color(0xFF075985);
const Color primaryDark = Color(0xFF0C4A6E);
const Color bg = Color(0xFFEFF6FF);
const Color card = Color(0xFFFFFFFF);
const Color border = Color(0xFFB8C7D9);
const Color textDark = Color(0xFF0F172A);
const Color textGrey = Color(0xFF475569);
const Color green = Color(0xFF15803D);
const Color red = Color(0xFFB91C1C);
const Color orange = Color(0xFFC2410C);
const Color purple = Color(0xFF6D28D9);
const Color yellow = Color(0xFFD97706);

enum DayStatus {
  present,
  halfDay,
  absent,
  leave,
  holiday,
}

extension DayStatusExt on DayStatus {
  String get label {
    switch (this) {
      case DayStatus.present:
        return 'Present';
      case DayStatus.halfDay:
        return 'Half Day';
      case DayStatus.absent:
        return 'Absent';
      case DayStatus.leave:
        return 'Leave';
      case DayStatus.holiday:
        return 'Holiday';
    }
  }

  String get short {
    switch (this) {
      case DayStatus.present:
        return 'P';
      case DayStatus.halfDay:
        return 'H';
      case DayStatus.absent:
        return 'A';
      case DayStatus.leave:
        return 'L';
      case DayStatus.holiday:
        return 'HD';
    }
  }
}

class Attendance {
  final DateTime date;
  DayStatus status;
  double hours;
  double ot;
  String note;

  Attendance({
    required this.date,
    required this.status,
    this.hours = 0,
    this.ot = 0,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'status': status.index,
      'hours': hours,
      'ot': ot,
      'note': note,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      date: DateTime.parse(json['date']),
      status: DayStatus.values[
          (json['status'] ?? 0).clamp(0, DayStatus.values.length - 1)],
      hours: (json['hours'] ?? 0).toDouble(),
      ot: (json['ot'] ?? 0).toDouble(),
      note: json['note'] ?? '',
    );
  }
}

enum CalculationMode {
  fixedDays,
  monthDays,
  dailyWage,
}

extension CalculationModeExt on CalculationMode {
  String get title {
    switch (this) {
      case CalculationMode.fixedDays:
        return 'Fixed Days';
      case CalculationMode.monthDays:
        return 'Month Days';
      case CalculationMode.dailyWage:
        return 'Daily Wage';
    }
  }
}

class SettingsData {
  CalculationMode mode;
  double monthlySalary;
  double workingDays;
  double normalHours;
  double otRate;
  double dailyWage;
  double advance;
  double deduction;

  SettingsData({
    this.mode = CalculationMode.fixedDays,
    this.monthlySalary = 15000,
    this.workingDays = 26,
    this.normalHours = 8,
    this.otRate = 100,
    this.dailyWage = 0,
    this.advance = 0,
    this.deduction = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.index,
      'monthlySalary': monthlySalary,
      'workingDays': workingDays,
      'normalHours': normalHours,
      'otRate': otRate,
      'dailyWage': dailyWage,
      'advance': advance,
      'deduction': deduction,
    };
  }

  factory SettingsData.fromJson(Map<String, dynamic> json) {
    return SettingsData(
      mode: CalculationMode.values[
          (json['mode'] ?? 0).clamp(0, CalculationMode.values.length - 1)],
      monthlySalary: (json['monthlySalary'] ?? 15000).toDouble(),
      workingDays: (json['workingDays'] ?? 26).toDouble(),
      normalHours: (json['normalHours'] ?? 8).toDouble(),
      otRate: (json['otRate'] ?? 100).toDouble(),
      dailyWage: (json['dailyWage'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
      deduction: (json['deduction'] ?? 0).toDouble(),
    );
  }
}

class Storage {
  static const String attendanceKey = 'worker_pay_attendance_v2';
  static const String settingsKey = 'worker_pay_settings_v2';

  static Future<List<Attendance>> loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(attendanceKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Attendance.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAttendance(List<Attendance> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      attendanceKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<SettingsData> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(settingsKey);

    if (raw == null || raw.isEmpty) {
      return SettingsData();
    }

    try {
      return SettingsData.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw)),
      );
    } catch (_) {
      return SettingsData();
    }
  }

  static Future<void> saveSettings(SettingsData settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      settingsKey,
      jsonEncode(settings.toJson()),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
    MobileAds.instance.initialize();
  runApp(const WorkerPayApp());
}

class WorkerPayApp extends StatelessWidget {
  const WorkerPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Worker Pay',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Attendance> attendance = [];
  SettingsData settings = SettingsData();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await Storage.loadAttendance();
    final s = await Storage.loadSettings();

    if (!mounted) return;

    setState(() {
      attendance = a;
      settings = s;
      loading = false;
    });
  }

  Future<void> _saveAttendance() async {
    await Storage.saveAttendance(attendance);
  }

  Future<void> _saveSettings() async {
    await Storage.saveSettings(settings);
  }

  Attendance? findAttendance(DateTime date) {
    for (final item in attendance) {
      if (item.date.year == date.year &&
          item.date.month == date.month &&
          item.date.day == date.day) {
        return item;
      }
    }
    return null;
  }

  Future<void> openAttendance(DateTime date) async {
    final existing = findAttendance(date);

    final result = await showDialog<AttendanceDialogResult>(
      context: context,
      builder: (_) => AttendanceDialog(
        date: date,
        existing: existing,
        normalHours: settings.normalHours,
      ),
    );

    if (result == null) return;

    setState(() {
      attendance.removeWhere(
        (a) =>
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day,
      );

      if (!result.delete) {
        attendance.add(result.attendance!);
      }
    });

    await _saveAttendance();
  }

  Future<void> openSettings() async {
    final result = await showModalBottomSheet<SettingsData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(settings: settings),
    );

    if (result == null) return;

    setState(() {
      settings = result;
    });

    await _saveSettings();
  }

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });
  }

  void goToday() {
    setState(() {
      selectedMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: pageIndex,
          children: [
            MonthPage(
              month: selectedMonth,
              attendance: attendance,
              settings: settings,
              onPrevious: previousMonth,
              onNext: nextMonth,
              onToday: goToday,
              onTapDay: openAttendance,
              onSettings: openSettings,
            ),
            YearPage(
              year: selectedMonth.year,
              attendance: attendance,
              onTapMonth: (month) {
                setState(() {
                  selectedMonth = month;
                  pageIndex = 0;
                });
              },
            ),
            SummaryPage(
              month: selectedMonth,
              attendance: attendance,
              settings: settings,
              onSettings: openSettings,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const WorkerPayBannerAd(),
    NavigationBar(
      selectedIndex: pageIndex,
      backgroundColor: Colors.white,
      indicatorColor: primary.withOpacity(.12),
      onDestinationSelected: (value) {
        setState(() {
          pageIndex = value;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Month',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view),
          label: 'Year',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Summary',
        ),
      ],
    ),
  ],
),

class MonthPage extends StatelessWidget {
  final DateTime month;
  final List<Attendance> attendance;
  final SettingsData settings;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final Future<void> Function(DateTime) onTapDay;
  final VoidCallback onSettings;

  const MonthPage({
    super.key,
    required this.month,
    required this.attendance,
    required this.settings,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onTapDay,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final monthItems = attendance
        .where(
          (a) => a.date.year == month.year && a.date.month == month.month,
        )
        .toList();

    final present =
        monthItems.where((a) => a.status == DayStatus.present).length;
    final absent =
        monthItems.where((a) => a.status == DayStatus.absent).length;
    final half =
        monthItems.where((a) => a.status == DayStatus.halfDay).length;
    final holiday =
        monthItems.where((a) => a.status == DayStatus.holiday).length;

    final hours = monthItems.fold<double>(0, (sum, a) => sum + a.hours);
    final ot = monthItems.fold<double>(0, (sum, a) => sum + a.ot);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topHeader(context),
          const SizedBox(height: 14),
          _monthSelector(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Pill(
                  icon: Icons.schedule,
                  text: 'Hours',
                  value: fmt(hours),
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Pill(
                  icon: Icons.timer_outlined,
                  text: 'OT',
                  value: fmt(ot),
                  color: orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Pill(
                  icon: Icons.currency_rupee,
                  text: '₹ Payment',
                  value: money(calculateTotal(month, attendance, settings)),
                  color: green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CalendarWidget(
            month: month,
            attendance: attendance,
            onTapDay: onTapDay,
          ),
          const SizedBox(height: 16),
          _summaryCard(
            context,
            present,
            absent,
            half,
            holiday,
            hours,
            ot,
          ),
        ],
      ),
    );
  }

  Widget _topHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Worker Pay',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Salary & OT Configuration',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _monthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            color: Colors.white,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  monthName(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: onToday,
                  child: const Text(
                    'Tap for current month',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            color: Colors.white,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    int present,
    int absent,
    int half,
    int holiday,
    double hours,
    double ot,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ),
              Text(
                '${monthName(month)} ${month.year}',
                style: const TextStyle(
                  fontSize: 11,
                  color: textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ChipBox(
                label: 'Present',
                value: '$present',
                color: green,
              ),
              ChipBox(
                label: 'Absent',
                value: '$absent',
                color: red,
              ),
              ChipBox(
                label: 'Half Day',
                value: '$half',
                color: orange,
              ),
              ChipBox(
                label: 'Holiday',
                value: '$holiday',
                color: purple,
              ),
              ChipBox(
                label: 'Hours',
                value: fmt(hours),
                color: primary,
              ),
              ChipBox(
                label: 'OT',
                value: fmt(ot),
                color: yellow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final String value;
  final Color color;

  const Pill({
    super.key,
    required this.icon,
    required this.text,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(.11),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class CalendarWidget extends StatelessWidget {
  final DateTime month;
  final List<Attendance> attendance;
  final Future<void> Function(DateTime) onTapDay;

  const CalendarWidget({
    super.key,
    required this.month,
    required this.attendance,
    required this.onTapDay,
  });

  Attendance? _find(DateTime date) {
    for (final a in attendance) {
      if (a.date.year == date.year &&
          a.date.month == date.month &&
          a.date.day == date.day) {
        return a;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final start = firstDay.weekday % 7;
    final totalCells = ((start + daysInMonth + 6) ~/ 7) * 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.06),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              _WeekDay('SUN'),
              _WeekDay('MON'),
              _WeekDay('TUE'),
              _WeekDay('WED'),
              _WeekDay('THU'),
              _WeekDay('FRI'),
              _WeekDay('SAT'),
            ],
          ),
          const SizedBox(height: 7),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: .78,
            ),
            itemBuilder: (context, index) {
              if (index < start || index >= start + daysInMonth) {
                return const SizedBox();
              }

              final day = index - start + 1;
              final date = DateTime(month.year, month.month, day);
              final item = _find(date);

              return GestureDetector(
                onTap: () => onTapDay(date),
                child: _DayCell(
                  date: date,
                  attendance: item,
                ),
              );
            },
          ),
          const SizedBox(height: 13),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 7,
            children: const [
              _Legend('Present', green),
              _Legend('Half Day', orange),
              _Legend('Absent', red),
              _Legend('Holiday', purple),
              _Legend('OT', yellow),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final String text;

  const _WeekDay(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: textGrey,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final Attendance? attendance;

  const _DayCell({
    required this.date,
    required this.attendance,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final status = attendance?.status;

    Color accent = border;
    Color background = const Color(0xFFF8FAFC);

    if (status == DayStatus.present) {
      accent = green;
      background = green.withOpacity(.08);
    } else if (status == DayStatus.halfDay) {
      accent = orange;
      background = orange.withOpacity(.08);
    } else if (status == DayStatus.absent) {
      accent = red;
      background = red.withOpacity(.07);
    } else if (status == DayStatus.leave) {
      accent = primary;
      background = primary.withOpacity(.07);
    } else if (status == DayStatus.holiday) {
      accent = purple;
      background = purple.withOpacity(.07);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday ? primary : accent,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isToday ? primary : textDark,
              ),
            ),
          ),
          if (attendance != null) ...[
            Text(
              '${fmt(attendance!.hours)}H',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            if (attendance!.ot > 0)
              Text(
                'OT ${fmt(attendance!.ot)}H',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: orange,
                ),
              ),
          ] else
            const Text(
              '+',
              style: TextStyle(
                fontSize: 14,
                color: border,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;

  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class ChipBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const ChipBox({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withOpacity(.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceDialogResult {
  final Attendance? attendance;
  final bool delete;

  AttendanceDialogResult({
    this.attendance,
    this.delete = false,
  });
}

class AttendanceDialog extends StatefulWidget {
  final DateTime date;
  final Attendance? existing;
  final double normalHours;

  const AttendanceDialog({
    super.key,
    required this.date,
    required this.existing,
    required this.normalHours,
  });

  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  late DayStatus status;
  late double hours;
  late double ot;

  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    status = widget.existing?.status ?? DayStatus.present;
    hours = widget.existing?.hours ?? widget.normalHours;
    ot = widget.existing?.ot ?? 0;

    noteController.text = widget.existing?.note ?? '';
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void setHours(double value) {
    setState(() {
      hours = value;
    });
  }

  void setOt(double value) {
    setState(() {
      ot = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.edit_calendar,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Attendance Entry',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatDate(widget.date),
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Status',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: DayStatus.values.map((s) {
                final selected = status == s;
                final c = statusColor(s);

                return ChoiceChip(
                  label: Text(s.label),
                  selected: selected,
                  selectedColor: c.withOpacity(.15),
                  labelStyle: TextStyle(
                    color: selected ? c : textGrey,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                  side: BorderSide(
                    color: selected ? c : border,
                  ),
                  onSelected: (_) {
                    setState(() {
                      status = s;

                      if (s == DayStatus.absent ||
                          s == DayStatus.leave ||
                          s == DayStatus.holiday) {
                        hours = 0;
                        ot = 0;
                      }

                      if (s == DayStatus.halfDay && hours == 0) {
                        hours = widget.normalHours / 2;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 19),
            _numberSection(
              title: 'Normal Working Hours',
              value: hours,
              quickValues: const [4, 8, 10],
              onChanged: setHours,
              suffix: 'H',
            ),
            const SizedBox(height: 18),
            _numberSection(
              title: 'Overtime (OT) Hours',
              value: ot,
              quickValues: const [0, 2, 4],
              onChanged: setOt,
              suffix: 'H',
            ),
            const SizedBox(height: 18),
            const Text(
              'Note',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Optional note...',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (widget.existing != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          AttendanceDialogResult(delete: true),
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: red,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: red),
                      ),
                    ),
                  ),
                if (widget.existing != null)
                  const SizedBox(width: 9),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      final a = Attendance(
                        date: widget.date,
                        status: status,
                        hours: hours,
                        ot: ot,
                        note: noteController.text.trim(),
                      );

                      Navigator.pop(
                        context,
                        AttendanceDialogResult(
                          attendance: a,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Save Attendance',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberSection({
    required String title,
    required double value,
    required List<double> quickValues,
    required ValueChanged<double> onChanged,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Text(
                  '${fmt(value)}$suffix',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: quickValues.map((v) {
            final selected = value == v;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: OutlinedButton(
                  onPressed: () => onChanged(v),
                  style: OutlinedButton.styleFrom(
                    backgroundColor:
                        selected ? primary.withOpacity(.08) : Colors.white,
                    side: BorderSide(
                      color: selected ? primary : border,
                    ),
                  ),
                  child: Text(
                    '${fmt(v)}H',
                    style: TextStyle(
                      color: selected ? primary : textGrey,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SummaryPage extends StatelessWidget {
  final DateTime month;
  final List<Attendance> attendance;
  final SettingsData settings;
  final VoidCallback onSettings;

  const SummaryPage({
    super.key,
    required this.month,
    required this.attendance,
    required this.settings,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final items = attendance
        .where(
          (a) => a.date.year == month.year && a.date.month == month.month,
        )
        .toList();

    final present =
        items.where((a) => a.status == DayStatus.present).length;
    final absent =
        items.where((a) => a.status == DayStatus.absent).length;
    final half =
        items.where((a) => a.status == DayStatus.halfDay).length;
    final holiday =
        items.where((a) => a.status == DayStatus.holiday).length;

    final hours = items.fold<double>(0, (s, a) => s + a.hours);
    final ot = items.fold<double>(0, (s, a) => s + a.ot);

    final daily = calculateDailyWage(settings);
    final basic = calculateBasicPayment(month, items, settings);
    final otPayment = ot * settings.otRate;
    final total = basic + otPayment - settings.advance - settings.deduction;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: onSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${monthName(month)} ${month.year}',
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          _summaryHero(total, hours, ot),
          const SizedBox(height: 14),
          Section(
            title: 'Attendance',
            icon: Icons.event_available_outlined,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: 2.15,
              children: [
                BigStat(
                  title: 'Present',
                  value: '$present',
                  color: green,
                  icon: Icons.check_circle_outline,
                ),
                BigStat(
                  title: 'Absent',
                  value: '$absent',
                  color: red,
                  icon: Icons.cancel_outlined,
                ),
                BigStat(
                  title: 'Half Day',
                  value: '$half',
                  color: orange,
                  icon: Icons.timelapse,
                ),
                BigStat(
                  title: 'Holiday',
                  value: '$holiday',
                  color: purple,
                  icon: Icons.beach_access_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Section(
            title: 'Working Time',
            icon: Icons.access_time,
            child: Row(
              children: [
                Expanded(
                  child: InfoBox(
                    title: 'Working Hours',
                    value: '${fmt(hours)} H',
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InfoBox(
                    title: 'OT Hours',
                    value: '${fmt(ot)} H',
                    color: orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Section(
            title: 'Payment',
            icon: Icons.currency_rupee,
            child: Column(
              children: [
                PayRow(
                  label: 'Monthly Salary',
                  value: money(settings.monthlySalary),
                ),
                PayRow(
                  label: 'Daily Wage',
                  value: money(daily),
                ),
                PayRow(
                  label: 'OT Rate',
                  value: '${money(settings.otRate)}/H',
                ),
                const Divider(height: 20),
                PayRow(
                  label: 'Basic Payment',
                  value: money(basic),
                  strong: true,
                ),
                PayRow(
                  label: 'OT Payment',
                  value: money(otPayment),
                  strong: true,
                ),
                PayRow(
                  label: 'Advance',
                  value: '- ${money(settings.advance)}',
                  valueColor: red,
                ),
                PayRow(
                  label: 'Deduction',
                  value: '- ${money(settings.deduction)}',
                  valueColor: red,
                ),
                const Divider(height: 20),
                PayRow(
                  label: 'Net Payment',
                  value: money(total),
                  strong: true,
                  valueColor: green,
                  big: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryHero(double total, double hours, double ot) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryDark,
            primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Net Payment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            money(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _heroMini('Hours', '${fmt(hours)}H'),
              const SizedBox(width: 9),
              _heroMini('OT', '${fmt(ot)}H'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMini(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.11),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const Section({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class BigStat extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const BigStat({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const InfoBox({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class PayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final bool big;
  final Color? valueColor;

  const PayRow({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
    this.big = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: big ? 14 : 12,
                color: strong ? textDark : textGrey,
                fontWeight:
                    strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: big ? 18 : 13,
              color: valueColor ??
                  (strong ? textDark : textGrey),
              fontWeight:
                  strong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
class SettingsSheet extends StatefulWidget {
  final SettingsData settings;

  const SettingsSheet({
    super.key,
    required this.settings,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late CalculationMode mode;
  late TextEditingController salary;
  late TextEditingController workingDays;
  late TextEditingController normalHours;
  late TextEditingController otRate;
  late TextEditingController dailyWage;
  late TextEditingController advance;
  late TextEditingController deduction;

  @override
  void initState() {
    super.initState();

    mode = widget.settings.mode;
    salary = TextEditingController(
      text: number(widget.settings.monthlySalary),
    );
    workingDays = TextEditingController(
      text: number(widget.settings.workingDays),
    );
    normalHours = TextEditingController(
      text: number(widget.settings.normalHours),
    );
    otRate = TextEditingController(
      text: number(widget.settings.otRate),
    );
    dailyWage = TextEditingController(
      text: number(widget.settings.dailyWage),
    );
    advance = TextEditingController(
      text: number(widget.settings.advance),
    );
    deduction = TextEditingController(
      text: number(widget.settings.deduction),
    );
  }

  @override
  void dispose() {
    salary.dispose();
    workingDays.dispose();
    normalHours.dispose();
    otRate.dispose();
    dailyWage.dispose();
    advance.dispose();
    deduction.dispose();
    super.dispose();
  }

  double val(TextEditingController c) {
    return double.tryParse(c.text.trim()) ?? 0;
  }

  SettingsData buildSettings() {
    return SettingsData(
      mode: mode,
      monthlySalary: val(salary),
      workingDays: val(workingDays),
      normalHours: val(normalHours),
      otRate: val(otRate),
      dailyWage: val(dailyWage),
      advance: val(advance),
      deduction: val(deduction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * .93,
      decoration: const BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          children: [
            const SizedBox(height: 9),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 13),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Text(
                            'Salary & OT Configuration',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Set your monthly salary, working hours and overtime rules.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _label('Calculation Mode'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: CalculationMode.values.map((item) {
                          final selected = mode == item;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  mode = item;
                                });
                              },
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 11,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? primary
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : textGrey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _field(
                      title: 'Monthly Salary',
                      controller: salary,
                      icon: Icons.currency_rupee,
                      enabled: mode != CalculationMode.dailyWage,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      title: 'Standard Working Days per Month',
                      controller: workingDays,
                      icon: Icons.calendar_today_outlined,
                      enabled: mode == CalculationMode.fixedDays,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      title: 'Normal Working Hours per Day',
                      controller: normalHours,
                      icon: Icons.schedule_outlined,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      title: 'Overtime OT Rate per Hour',
                      controller: otRate,
                      icon: Icons.timer_outlined,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      title: 'Daily Wage',
                      controller: dailyWage,
                      icon: Icons.account_balance_wallet_outlined,
                      enabled: mode == CalculationMode.dailyWage,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      title: 'Optional Advance',
                      controller: advance,
                      icon: Icons.arrow_downward_outlined,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      title: 'Optional Deduction',
                      controller: deduction,
                      icon: Icons.remove_circle_outline,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.06),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: primary.withOpacity(.14),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mode == CalculationMode.dailyWage
                                  ? 'Daily Wage mode calculates payment from your daily wage and attendance.'
                                  : 'Salary mode calculates basic payment from attendance and your configured working days.',
                              style: const TextStyle(
                                color: textGrey,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        buildSettings(),
                      );
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Save Configuration',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: textDark,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _field({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: enabled ? primary : border,
            ),
            suffixText: title.contains('Hours')
                ? 'H'
                : title.contains('Rate') ||
                        title.contains('Salary') ||
                        title.contains('Wage') ||
                        title.contains('Advance') ||
                        title.contains('Deduction')
                    ? '₹'
                    : null,
          ),
        ),
      ],
    );
  }
}

class YearPage extends StatelessWidget {
  final int year;
  final List<Attendance> attendance;
  final ValueChanged<DateTime> onTapMonth;

  const YearPage({
    super.key,
    required this.year,
    required this.attendance,
    required this.onTapMonth,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Year Overview',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$year · Monthly Attendance',
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.22,
            ),
            itemBuilder: (context, index) {
              final month = DateTime(year, index + 1);
              return YearMonthCard(
                month: month,
                attendance: attendance,
                onTap: () => onTapMonth(month),
              );
            },
          ),
        ],
      ),
    );
  }
}

class YearMonthCard extends StatelessWidget {
  final DateTime month;
  final List<Attendance> attendance;
  final VoidCallback onTap;

  const YearMonthCard({
    super.key,
    required this.month,
    required this.attendance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = attendance
        .where(
          (a) => a.date.year == month.year &&
              a.date.month == month.month,
        )
        .toList();

    final present =
        items.where((a) => a.status == DayStatus.present).length;
    final absent =
        items.where((a) => a.status == DayStatus.absent).length;
    final half =
        items.where((a) => a.status == DayStatus.halfDay).length;
    final ot = items.fold<double>(0, (s, a) => s + a.ot);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    monthName(month).split(' ').first,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: border,
                ),
              ],
            ),
            Text(
              '${month.year}',
              style: const TextStyle(
                color: textGrey,
                fontSize: 9,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                _miniCount(
                  'P',
                  '$present',
                  green,
                ),
                _miniCount(
                  'A',
                  '$absent',
                  red,
                ),
                _miniCount(
                  'H',
                  '$half',
                  orange,
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 12,
                  color: orange,
                ),
                const SizedBox(width: 3),
                Text(
                  'OT ${fmt(ot)}H',
                  style: const TextStyle(
                    fontSize: 9,
                    color: textGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniCount(
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Color statusColor(DayStatus status) {
  switch (status) {
    case DayStatus.present:
      return green;
    case DayStatus.halfDay:
      return orange;
    case DayStatus.absent:
      return red;
    case DayStatus.leave:
      return primary;
    case DayStatus.holiday:
      return purple;
  }
}

double calculateDailyWage(SettingsData settings) {
  if (settings.mode == CalculationMode.dailyWage &&
      settings.dailyWage > 0) {
    return settings.dailyWage;
  }

  if (settings.workingDays <= 0) {
    return 0;
  }

  return settings.monthlySalary / settings.workingDays;
}

double calculateBasicPayment(
  DateTime month,
  List<Attendance> items,
  SettingsData settings,
) {
  final present = items
      .where((a) => a.status == DayStatus.present)
      .length;

  final half = items
      .where((a) => a.status == DayStatus.halfDay)
      .length;

  final workedEquivalent = present + (half * .5);

  if (settings.mode == CalculationMode.dailyWage) {
    return workedEquivalent * calculateDailyWage(settings);
  }

  if (settings.mode == CalculationMode.monthDays) {
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;

    if (daysInMonth <= 0) return 0;

    return settings.monthlySalary *
        (workedEquivalent / daysInMonth);
  }

  if (settings.workingDays <= 0) {
    return 0;
  }

  return settings.monthlySalary *
      (workedEquivalent / settings.workingDays);
}

double calculateTotal(
  DateTime month,
  List<Attendance> attendance,
  SettingsData settings,
) {
  final items = attendance
      .where(
        (a) =>
            a.date.year == month.year &&
            a.date.month == month.month,
      )
      .toList();

  final basic = calculateBasicPayment(
    month,
    items,
    settings,
  );

  final ot = items.fold<double>(
    0,
    (sum, a) => sum + a.ot,
  );

  return basic +
      (ot * settings.otRate) -
      settings.advance -
      settings.deduction;
}

String monthName(DateTime date) {
  const months = [
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
    'December',
  ];

  return '${months[date.month - 1]} ${date.year}';
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  const weekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  final weekday = weekdays[date.weekday % 7];

  return '$weekday, ${date.day} ${months[date.month - 1]} ${date.year}';
}

String fmt(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}

String number(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}

String money(double value) {
  final negative = value < 0;
  final v = value.abs();

  String raw;

  if (v == v.roundToDouble()) {
    raw = v.toInt().toString();
  } else {
    raw = v.toStringAsFixed(2);
  }

  final parts = raw.split('.');
  final whole = parts[0];

  String formatted = '';

  for (int i = 0; i < whole.length; i++) {
    final position = whole.length - i;

    formatted += whole[i];

    if (position > 1 && position % 3 == 1) {
      formatted += ',';
    }
  }

  if (parts.length > 1) {
    formatted += '.${parts[1]}';
  }

  return '${negative ? '-' : ''}₹$formatted';
}
class WorkerPayBannerAd extends StatefulWidget {
  const WorkerPayBannerAd({super.key});

  @override
  State<WorkerPayBannerAd> createState() => _WorkerPayBannerAdState();
}

class _WorkerPayBannerAdState extends State<WorkerPayBannerAd> {
  late final BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd.size.width.toDouble(),
      height: _bannerAd.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd),
    );
  }
}
