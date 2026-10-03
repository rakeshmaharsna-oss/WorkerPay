import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const primary = Color(0xFF005086);
const bg = Color(0xFFF2F8FD);
const border = Color(0xFFD6E0E8);
const textGrey = Color(0xFF65717C);
const textDark = Color(0xFF0B1722);
const red = Color(0xFFDC2626);
const orange = Color(0xFFD97706);
const green = Color(0xFF16A34A);

enum DayStatus { none, present, absent, half, holiday }

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

  factory Attendance.fromJson(Map<String, dynamic> j) {
    final s = (j['status'] ?? 0) as int;
    return Attendance(
      status: DayStatus.values[s.clamp(0, 4)],
      hours: (j['hours'] ?? 0).toDouble(),
      ot: (j['ot'] ?? 0).toDouble(),
    );
  }
}

class Settings {
  String mode;
  double salary;
  double workingDays;
  double normalHours;
  double otRate;
  double dailyWage;
  double advance;
  double deduction;

  Settings({
    this.mode = 'fixed',
    this.salary = 15000,
    this.workingDays = 26,
    this.normalHours = 8,
    this.otRate = 100,
    this.dailyWage = 0,
    this.advance = 0,
    this.deduction = 0,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'salary': salary,
        'workingDays': workingDays,
        'normalHours': normalHours,
        'otRate': otRate,
        'dailyWage': dailyWage,
        'advance': advance,
        'deduction': deduction,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        mode: j['mode'] ?? 'fixed',
        salary: (j['salary'] ?? 15000).toDouble(),
        workingDays: (j['workingDays'] ?? 26).toDouble(),
        normalHours: (j['normalHours'] ?? 8).toDouble(),
        otRate: (j['otRate'] ?? 100).toDouble(),
        dailyWage: (j['dailyWage'] ?? 0).toDouble(),
        advance: (j['advance'] ?? 0).toDouble(),
        deduction: (j['deduction'] ?? 0).toDouble(),
      );
}

class Storage {
  static Future<Map<String, Attendance>> attendance() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('attendance');
    if (raw == null) return {};

    final map = Map<String, dynamic>.from(jsonDecode(raw));

    return map.map(
      (k, v) => MapEntry(
        k,
        Attendance.fromJson(Map<String, dynamic>.from(v)),
      ),
    );
  }

  static Future<Settings> settings() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('settings');

    if (raw == null) return Settings();

    return Settings.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw)),
    );
  }

  static Future<void> saveAttendance(
      Map<String, Attendance> data) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      'attendance',
      jsonEncode(
        data.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
      ),
    );
  }

  static Future<void> saveSettings(Settings data) async {
    final p = await SharedPreferences.getInstance();

    await p.setString(
      'settings',
      jsonEncode(data.toJson()),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const WorkerPay());
}

class WorkerPay extends StatelessWidget {
  const WorkerPay({super.key});

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
        ),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int page = 0;

  DateTime month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  Map<String, Attendance> data = {};
  Settings settings = Settings();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    data = await Storage.attendance();
    settings = await Storage.settings();

    if (mounted) setState(() {});
  }

  String key(DateTime d) =>
      '${d.year}-${d.month}-${d.day}';

  Future<void> editDay(DateTime d) async {
    final old = data[key(d)];

    final result = await showDialog<Attendance>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AttendanceDialog(
        date: d,
        initial: old ??
            Attendance(
              status: DayStatus.present,
              hours: settings.normalHours,
            ),
        normalHours: settings.normalHours,
      ),
    );

    if (result == null) return;

    if (result.status == DayStatus.none) {
      data.remove(key(d));
    } else {
      data[key(d)] = result;
    }

    await Storage.saveAttendance(data);

    setState(() {});
  }

  Future<void> settingsPage() async {
    final result = await showModalBottomSheet<Settings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(
        initial: settings,
        month: month,
      ),
    );

    if (result == null) return;

    settings = result;

    await Storage.saveSettings(settings);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: page,
          children: [
            MonthPage(
              month: month,
              data: data,
              onDay: editDay,
              previous: () {
                setState(() {
                  month = DateTime(
                    month.year,
                    month.month - 1,
                  );
                });
              },
              next: () {
                setState(() {
                  month = DateTime(
                    month.year,
                    month.month + 1,
                  );
                });
              },
              settings: settingsPage,
            ),

            YearPage(
              year: month.year,
              data: data,
              onDay: editDay,
              previous: () {
                setState(() {
                  month = DateTime(
                    month.year - 1,
                    month.month,
                  );
                });
              },
              next: () {
                setState(() {
                  month = DateTime(
                    month.year + 1,
                    month.month,
                  );
                });
              },
            ),

            SummaryPage(
              month: month,
              data: data,
              settings: settings,
              previous: () {
                setState(() {
                  month = DateTime(
                    month.year,
                    month.month - 1,
                  );
                });
              },
              next: () {
                setState(() {
                  month = DateTime(
                    month.year,
                    month.month + 1,
                  );
                });
              },
              edit: settingsPage,
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        height: 78,
        backgroundColor: const Color(0xFFEFF1F6),
        indicatorColor: const Color(0xFFD7E8FA),
        selectedIndex: page,
        onDestinationSelected: (i) {
          setState(() => page = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Month',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Year',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_rupee_outlined),
            selectedIcon: Icon(Icons.currency_rupee),
            label: 'Summary',
          ),
        ],
      ),
    );
  }
}

/* =========================
   MONTH PAGE
========================= */

class MonthPage extends StatelessWidget {
  final DateTime month;
  final Map<String, Attendance> data;
  final Future<void> Function(DateTime) onDay;
  final VoidCallback previous;
  final VoidCallback next;
  final VoidCallback settings;

  const MonthPage({
    super.key,
    required this.month,
    required this.data,
    required this.onDay,
    required this.previous,
    required this.next,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final c = counts(month, data);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Worker Pay',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: textDark,
                  ),
                ),
              ),

              IconButton(
                onPressed: previous,
                icon: const Icon(
                  Icons.chevron_left,
                  size: 34,
                ),
              ),

              Flexible(
                child: Text(
                  monthName(month),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),

              IconButton(
                onPressed: next,
                icon: const Icon(
                  Icons.chevron_right,
                  size: 34,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Pill(
                  icon: Icons.access_time,
                  text: 'Hours',
                  color: primary,
                  onTap: settings,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Pill(
                  icon: Icons.more_time,
                  text: 'OT',
                  color: green,
                  onTap: settings,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Pill(
                  icon: Icons.currency_rupee,
                  text: 'Payment',
                  color: primary,
                  onTap: settings,
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          CalendarWidget(
            month: month,
            data: data,
            onDay: onDay,
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${monthName(month)} Summary',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    ChipBox(
                      'Present: ${c['present']!.toInt()}',
                      const Color(0xFFE8F4FB),
                      primary,
                    ),
                    ChipBox(
                      'Absent: ${c['absent']!.toInt()}',
                      const Color(0xFFFFEEF0),
                      red,
                    ),
                    ChipBox(
                      'Half Day: ${c['half']!.toInt()}',
                      const Color(0xFFFFF3E5),
                      orange,
                    ),
                    ChipBox(
                      'Holiday: ${c['holiday']!.toInt()}',
                      const Color(0xFFF0F2F4),
                      textGrey,
                    ),
                    ChipBox(
                      'Hours: ${fmt(c['hours']!)} H',
                      const Color(0xFFE8F4FB),
                      primary,
                    ),
                    ChipBox(
                      'OT: ${fmt(c['ot']!)} H',
                      const Color(0xFFE8F8EF),
                      green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const Pill({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: color,
        size: 27,
      ),
      label: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 17,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 13,
        ),
        side: const BorderSide(
          color: Color(0xFF8D969E),
          width: 1.4,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class CalendarWidget extends StatelessWidget {
  final DateTime month;
  final Map<String, Attendance> data;
  final Future<void> Function(DateTime) onDay;

  const CalendarWidget({
    super.key,
    required this.month,
    required this.data,
    required this.onDay,
  });

  Attendance? getDay(DateTime d) {
    return data['${d.year}-${d.month}-${d.day}'];
  }

  @override
  Widget build(BuildContext context) {
    final first =
        DateTime(month.year, month.month, 1);

    final offset = first.weekday % 7;

    final total =
        DateTime(month.year, month.month + 1, 0).day;

    final cells = <DateTime?>[];

    for (int i = 0; i < offset; i++) {
      cells.add(null);
    }

    for (int i = 1; i <= total; i++) {
      cells.add(
        DateTime(month.year, month.month, i),
      );
    }

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        17,
        12,
        17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: border,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              'SUN',
              'MON',
              'TUE',
              'WED',
              'THU',
              'FRI',
              'SAT',
            ]
                .map(
                  (e) => Expanded(
                    child: Center(
                      child: Text(
                        e,
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .88,
            ),
            itemBuilder: (_, index) {
              final d = cells[index];

              if (d == null) {
                return const SizedBox();
              }

              final a = getDay(d);

              return InkWell(
                borderRadius:
                    BorderRadius.circular(17),
                onTap: () => onDay(d),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: a == null
                        ? Colors.white
                        : fill(a.status),
                    borderRadius:
                        BorderRadius.circular(17),
                    border: Border.all(
                      color: a == null
                          ? border
                          : dayBorder(a.status),
                      width:
                          a == null ? 1.2 : 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 17,
                          color: d.weekday ==
                                  DateTime.sunday
                              ? red
                              : textDark,
                        ),
                      ),

                      const Spacer(),

                      if (a != null &&
                          a.hours > 0)
                        Text(
                          '${fmt(a.hours)}H',
                          style:
                              const TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                      if (a != null &&
                          a.ot > 0)
                        Text(
                          'OT ${fmt(a.ot)}H',
                          style:
                              const TextStyle(
                            color: green,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChipBox extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color color;

  const ChipBox(
    this.text,
    this.bgColor,
    this.color, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/* =========================
   SUMMARY PAGE
========================= */

class SummaryPage extends StatelessWidget {
  final DateTime month;
  final Map<String, Attendance> data;
  final Settings settings;
  final VoidCallback previous;
  final VoidCallback next;
  final VoidCallback edit;

  const SummaryPage({
    super.key,
    required this.month,
    required this.data,
    required this.settings,
    required this.previous,
    required this.next,
    required this.edit,
  });

  @override
  Widget build(BuildContext context) {
    final c = counts(month, data);

    double daily;

    if (settings.mode == 'daily') {
      daily = settings.dailyWage;
    } else if (settings.mode == 'month') {
      final days =
          DateTime(month.year, month.month + 1, 0).day;
      daily = settings.salary / days;
    } else {
      daily = settings.salary /
          (settings.workingDays <= 0
              ? 26
              : settings.workingDays);
    }

    final payableDays =
        c['present']! + c['half']! * .5;

    final basic =
        payableDays * daily;

    final otAmount =
        c['ot']! * settings.otRate;

    final total =
        basic +
        otAmount -
        settings.advance -
        settings.deduction;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        25,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Attendance & Payment Summary',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: previous,
                icon: const Icon(
                  Icons.chevron_left,
                  size: 32,
                ),
              ),
              Flexible(
                child: Text(
                  monthName(month),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: next,
                icon: const Icon(
                  Icons.chevron_right,
                  size: 32,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Section(
            title: 'ATTENDANCE BREAKDOWN',
            icon: Icons.calendar_month,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BigStat(
                        '${c['present']!.toInt()} Days',
                        'Present',
                        const Color(0xFFE8F4FB),
                        primary,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: BigStat(
                        '${c['absent']!.toInt()} Days',
                        'Absent',
                        const Color(0xFFFFEEEE),
                        red,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: BigStat(
                        '${c['half']!.toInt()} Days',
                        'Half Day',
                        const Color(0xFFFFF7D9),
                        orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: BigStat(
                        '${c['holiday']!.toInt()} Days',
                        'Leave / Holiday',
                        const Color(0xFFF0F2F4),
                        textGrey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                Row(
                  children: [
                    Expanded(
                      child: InfoBox(
                        'Working Hours',
                        '${fmt(c['hours']!)} H',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InfoBox(
                        'Overtime (OT) Hours',
                        '${fmt(c['ot']!)} H',
                        greenBox: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Section(
            title: 'PAYMENT CALCULATION',
            icon: Icons.currency_rupee,
            trailing: TextButton.icon(
              onPressed: edit,
              icon: const Icon(
                Icons.edit,
                size: 16,
              ),
              label: const Text('Edit Rates'),
            ),
            child: Column(
              children: [
                PayRow(
                  'Monthly Salary Base',
                  money(settings.salary),
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    settings.mode == 'fixed'
                        ? 'Formula: ${settings.workingDays.toInt()} fixed days (${money(daily)}/day)'
                        : settings.mode == 'month'
                            ? 'Formula: monthly salary / calendar days'
                            : 'Formula: direct daily wage',
                    style: const TextStyle(
                      color: Color(0xFFB0B5BA),
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                PayRow(
                  'Basic Payment',
                  money(basic),
                  bold: true,
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Present (${c['present']!.toInt()}) + Half Days (${c['half']!.toInt()} × 0.5) = ${payableDays.toStringAsFixed(1)} days',
                    style: const TextStyle(
                      color: Color(0xFFB0B5BA),
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                PayRow(
                  'OT Rate',
                  '${money(settings.otRate)} / Hour',
                  bold: true,
                ),

                const SizedBox(height: 12),

                PayRow(
                  'OT Amount',
                  '+ ${money(otAmount)}',
                  green: true,
                  bold: true,
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${money(settings.otRate)} × ${fmt(c['ot']!)} H',
                    style: const TextStyle(
                      color: Color(0xFFB0B5BA),
                      fontSize: 13,
                    ),
                  ),
                ),

                if (settings.advance > 0)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 13),
                    child: PayRow(
                      'Advance',
                      '- ${money(settings.advance)}',
                      redText: true,
                    ),
                  ),

                if (settings.deduction > 0)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 13),
                    child: PayRow(
                      'Deduction',
                      '- ${money(settings.deduction)}',
                      redText: true,
                    ),
                  ),

                const SizedBox(height: 22),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius:
                        BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expected Total Payment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'For selected month',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        money(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
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

class Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const Section({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: primary,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}

class BigStat extends StatelessWidget {
  final String value;
  final String label;
  final Color background;
  final Color color;

  const BigStat(
    this.value,
    this.label,
    this.background,
    this.color, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
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
  final bool greenBox;

  const InfoBox(
    this.title,
    this.value, {
    super.key,
    this.greenBox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: greenBox
            ? const Color(0xFFE9FAF0)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color:
                  greenBox ? green : textGrey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class PayRow extends StatelessWidget {
  final String title;
  final String value;
  final bool green;
  final bool redText;
  final bool bold;

  const PayRow(
    this.title,
    this.value, {
    super.key,
    this.green = false,
    this.redText = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: textGrey,
              fontSize: 16,
              fontWeight: bold
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: green
    ? const Color(0xFF16A34A)
    : redText
        ? red
        : primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/* =========================
   ATTENDANCE DIALOG
========================= */

class AttendanceDialog extends StatefulWidget {
  final DateTime date;
  final Attendance initial;
  final double normalHours;

  const AttendanceDialog({
    super.key,
    required this.date,
    required this.initial,
    required this.normalHours,
  });

  @override
  State<AttendanceDialog> createState() =>
      _AttendanceDialogState();
}

class _AttendanceDialogState
    extends State<AttendanceDialog> {
  late DayStatus status;
  late TextEditingController hours;
  late TextEditingController ot;

  @override
  void initState() {
    super.initState();

    status = widget.initial.status;

    if (status == DayStatus.none) {
      status = DayStatus.present;
    }

    hours = TextEditingController(
      text: fmt(
        widget.initial.hours == 0
            ? widget.normalHours
            : widget.initial.hours,
      ),
    );

    ot = TextEditingController(
      text: fmt(widget.initial.ot),
    );
  }

  @override
  void dispose() {
    hours.dispose();
    ot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attendance Entry',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            Text(
              formatDate(widget.date),
              style: const TextStyle(
                color: primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'SELECT STATUS',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                statusButton(
                  'PRESENT',
                  DayStatus.present,
                ),
                statusButton(
                  'HALF DAY',
                  DayStatus.half,
                ),
                statusButton(
                  'ABSENT',
                  DayStatus.absent,
                ),
                statusButton(
                  'HOLIDAY',
                  DayStatus.holiday,
                ),
              ],
            ),

            const SizedBox(height: 22),

            const Text(
              'NORMAL WORKING HOURS',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: hours,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText: 'Hours',
                prefixIcon:
                    Icon(Icons.access_time),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'OVERTIME (OT) HOURS',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: ot,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText: 'OT Hours',
                prefixIcon:
                    Icon(Icons.more_time),
                helperText:
                    'OT will appear in green',
              ),
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      Attendance(),
                    );
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: red,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      color: red,
                    ),
                  ),
                ),

                const Spacer(),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      Attendance(
                        status: status,
                        hours:
                            double.tryParse(
                                  hours.text,
                                ) ??
                                0,
                        ot:
                            double.tryParse(
                                  ot.text,
                                ) ??
                                0,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.check_circle,
                  ),
                  label: const Text(
                    'Save Attendance',
                  ),
                  style:
                      FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 14,
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

  Widget statusButton(
    String text,
    DayStatus value,
  ) {
    final selected = status == value;

    return InkWell(
      onTap: () {
        setState(() => status = value);
      },
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F4FB)
              : Colors.white,
          border: Border.all(
            color:
                selected ? primary : border,
            width: selected ? 2 : 1,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? primary
                : textDark,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/* =========================
   SETTINGS
========================= */

class SettingsSheet extends StatefulWidget {
  final Settings initial;
  final DateTime month;

  const SettingsSheet({
    super.key,
    required this.initial,
    required this.month,
  });

  @override
  State<SettingsSheet> createState() =>
      _SettingsSheetState();
}

class _SettingsSheetState
    extends State<SettingsSheet> {
  late String mode;

  late TextEditingController salary;
  late TextEditingController days;
  late TextEditingController hours;
  late TextEditingController ot;
  late TextEditingController daily;
  late TextEditingController advance;
  late TextEditingController deduction;

  @override
  void initState() {
    super.initState();

    final s = widget.initial;

    mode = s.mode;

    salary =
        TextEditingController(text: fmt(s.salary));
    days =
        TextEditingController(text: fmt(s.workingDays));
    hours =
        TextEditingController(text: fmt(s.normalHours));
    ot =
        TextEditingController(text: fmt(s.otRate));
    daily =
        TextEditingController(text: fmt(s.dailyWage));
    advance =
        TextEditingController(text: fmt(s.advance));
    deduction =
        TextEditingController(text: fmt(s.deduction));
  }

  @override
  void dispose() {
    salary.dispose();
    days.dispose();
    hours.dispose();
    ot.dispose();
    daily.dispose();
    advance.dispose();
    deduction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height:
          MediaQuery.of(context).size.height * .93,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + keyboard,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius:
                      BorderRadius.circular(5),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Salary & OT Configuration',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      Text(
                        'For ${monthName(widget.month)}',
                        style: const TextStyle(
                          color: primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  icon:
                      const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Text(
              'CALCULATION MODE',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                modeButton(
                  'Fixed Days',
                  'fixed',
                  'Monthly / 26 days',
                ),
                modeButton(
                  'Month Days',
                  'month',
                  'Monthly / 30–31 days',
                ),
                modeButton(
                  'Daily Wage',
                  'daily',
                  'Direct per day',
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (mode != 'daily')
              field(
                'MONTHLY SALARY (₹)',
                salary,
                '₹ / Month',
              ),

            if (mode == 'fixed')
              field(
                'STANDARD WORKING DAYS PER MONTH',
                days,
                'Days (default 26)',
              ),

            field(
              'NORMAL WORKING HOURS PER DAY',
              hours,
              'Hours / Day',
            ),

            field(
              'OVERTIME (OT) RATE PER HOUR (₹)',
              ot,
              '₹ / Hour',
            ),

            if (mode == 'daily')
              field(
                'DAILY WAGE (₹)',
                daily,
                '₹ / Day',
              ),

            field(
              'OPTIONAL ADVANCE (₹)',
              advance,
              'Advance taken',
            ),

            field(
              'OPTIONAL DEDUCTION (₹)',
              deduction,
              'Other deductions',
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final result = Settings(
                    mode: mode,
                    salary:
                        number(salary, 15000),
                    workingDays:
                        number(days, 26),
                    normalHours:
                        number(hours, 8),
                    otRate:
                        number(ot, 100),
                    dailyWage:
                        number(daily),
                    advance:
                        number(advance),
                    deduction:
                        number(deduction),
                  );

                  Navigator.pop(
                    context,
                    result,
                  );
                },
                style:
                    FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
                child:
                    const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget modeButton(
    String title,
    String value,
    String subtitle,
  ) {
    final active = mode == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => mode = value);
        },
        child: Container(
          height: 74,
          margin:
              const EdgeInsets.only(right: 5),
          padding:
              const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFE8F4FB)
                : Colors.white,
            border: Border.all(
              color:
                  active ? primary : border,
              width: active ? 2 : 1,
            ),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active
                      ? primary
                      : textDark,
                  fontWeight:
                      FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(
                  color: textGrey,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget field(
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration:
                InputDecoration(
              prefixText:
                  label.contains('₹')
                      ? '₹ '
                      : null,
              suffixText: suffix,
              filled: true,
              fillColor:
                  const Color(0xFFFCFDFE),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   YEAR PAGE
========================= */

class YearPage extends StatelessWidget {
  final int year;
  final Map<String, Attendance> data;
  final Future<void> Function(DateTime) onDay;
  final VoidCallback previous;
  final VoidCallback next;

  const YearPage({
    super.key,
    required this.year,
    required this.data,
    required this.onDay,
    required this.previous,
    required this.next,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        25,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Year Calendar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: previous,
                icon: const Icon(
                  Icons.chevron_left,
                  size: 32,
                ),
              ),
              Text(
                '$year',
                style:
                    const TextStyle(
                  fontSize: 21,
                ),
              ),
              IconButton(
                onPressed: next,
                icon: const Icon(
                  Icons.chevron_right,
                  size: 32,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          for (int m = 1; m <= 12; m++)
            Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: YearMonth(
                year: year,
                month: m,
                data: data,
                onDay: onDay,
              ),
            ),
        ],
      ),
    );
  }
}

class YearMonth extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, Attendance> data;
  final Future<void> Function(DateTime) onDay;

  const YearMonth({
    super.key,
    required this.year,
    required this.month,
    required this.data,
    required this.onDay,
  });

  @override
  Widget build(BuildContext context) {
    final first =
        DateTime(year, month, 1);

    final offset = first.weekday % 7;

    final total =
        DateTime(year, month + 1, 0).day;

    return Container(
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            monthName(first),
            style: const TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: const [
              'S',
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
            ]
                .map(
                  (e) => Expanded(
                    child: Center(
                      child: Text(
                        e,
                        style:
                            TextStyle(
                          color:
                              textGrey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount:
                offset + total,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (_, i) {
              if (i < offset) {
                return const SizedBox();
              }

              final d = DateTime(
                year,
                month,
                i - offset + 1,
              );

              final a = data[
                  '${d.year}-${d.month}-${d.day}'];

              return InkWell(
                onTap: () => onDay(d),
                child: Center(
                  child: Text(
                    '${d.day}',
                    style: TextStyle(
                      color: a == null
                          ? (d.weekday ==
                                  DateTime.sunday
                              ? red
                              : textDark)
                          : dayColor(
                              a.status,
                            ),
                      fontSize: 12,
                      fontWeight:
                          a != null
                              ? FontWeight.w800
                              : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* =========================
   HELPERS
========================= */

Map<String, double> counts(
  DateTime month,
  Map<String, Attendance> data,
) {
  double present = 0;
  double absent = 0;
  double half = 0;
  double holiday = 0;
  double hours = 0;
  double ot = 0;

  final total =
      DateTime(
        month.year,
        month.month + 1,
        0,
      ).day;

  for (int i = 1; i <= total; i++) {
    final a = data[
        '${month.year}-${month.month}-$i'];

    if (a == null) continue;

    if (a.status ==
        DayStatus.present) {
      present++;
    }

    if (a.status ==
        DayStatus.absent) {
      absent++;
    }

    if (a.status ==
        DayStatus.half) {
      half++;
    }

    if (a.status ==
        DayStatus.holiday) {
      holiday++;
    }

    hours += a.hours;
    ot += a.ot;
  }

  return {
    'present': present,
    'absent': absent,
    'half': half,
    'holiday': holiday,
    'hours': hours,
    'ot': ot,
  };
}

Color fill(DayStatus status) {
  switch (status) {
    case DayStatus.present:
      return const Color(0xFFEAF6FC);

    case DayStatus.absent:
      return const Color(0xFFFFEDEE);

    case DayStatus.half:
      return const Color(0xFFFFF5E5);

    case DayStatus.holiday:
      return const Color(0xFFF1F3F5);

    case DayStatus.none:
      return Colors.white;
  }
}

Color dayBorder(DayStatus status) {
  switch (status) {
    case DayStatus.present:
      return const Color(0xFF9DC8DF);

    case DayStatus.absent:
      return const Color(0xFFF1A5AA);

    case DayStatus.half:
      return const Color(0xFFE9B76D);

    case DayStatus.holiday:
      return border;

    case DayStatus.none:
      return border;
  }
}

Color dayColor(DayStatus status) {
  switch (status) {
    case DayStatus.present:
      return primary;

    case DayStatus.absent:
      return red;

    case DayStatus.half:
      return orange;

    case DayStatus.holiday:
      return textGrey;

    case DayStatus.none:
      return textDark;
  }
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
    'December',
  ];

  return '${names[d.month - 1]} ${d.year}';
}

String formatDate(DateTime d) {
  const week = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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

  return '${week[d.weekday - 1]}, '
      '${d.day} ${months[d.month - 1]} '
      '${d.year}';
}

String fmt(double n) {
  if (n == n.roundToDouble()) {
    return n.toInt().toString();
  }

  return n.toStringAsFixed(1);
}

String money(double n) {
  return '₹${n.round()}';
}

double number(
  TextEditingController c, [
  double fallback = 0,
]) {
  return double.tryParse(
        c.text.trim(),
      ) ??
      fallback;
}
