import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const Color primary = Color(0xFF005086);
const Color primaryLight = Color(0xFFE8F4FB);
const Color bg = Color(0xFFF2F8FD);
const Color textDark = Color(0xFF0B1722);
const Color textGrey = Color(0xFF65717C);
const Color border = Color(0xFFD6E0E8);
const Color absentRed = Color(0xFFDC2626);
const Color halfOrange = Color(0xFFD97706);
const Color otGreen = Color(0xFF16A34A);

const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';

enum DayStatus {
  none,
  present,
  absent,
  half,
  holiday,
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

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'hours': hours,
      'ot': ot,
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final index = (json['status'] ?? 0).clamp(0, 4);

    return Attendance(
      status: DayStatus.values[index],
      hours: (json['hours'] ?? 0).toDouble(),
      ot: (json['ot'] ?? 0).toDouble(),
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
      'mode': mode,
      'monthlySalary': monthlySalary,
      'workingDays': workingDays,
      'normalHours': normalHours,
      'otRate': otRate,
      'dailyWage': dailyWage,
      'advance': advance,
      'deduction': deduction,
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      mode: json['mode'] ?? 'fixed',
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

class Store {
  static const String attendanceKey = 'workerpay_attendance';
  static const String settingsKey = 'workerpay_settings';

  static Future<Map<String, Attendance>> loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(attendanceKey);

    if (raw == null) {
      return {};
    }

    final data = Map<String, dynamic>.from(jsonDecode(raw));

    return data.map(
      (key, value) => MapEntry(
        key,
        Attendance.fromJson(
          Map<String, dynamic>.from(value),
        ),
      ),
    );
  }

  static Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(settingsKey);

    if (raw == null) {
      return Settings();
    }

    return Settings.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw)),
    );
  }

  static Future<void> saveAttendance(
    Map<String, Attendance> attendance,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      attendanceKey,
      jsonEncode(
        attendance.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      ),
    );
  }

  static Future<void> saveSettings(Settings settings) async {
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
      title: 'Worker Pay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;

  DateTime month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  Map<String, Attendance> attendance = {};

  Settings settings = Settings();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final loadedAttendance = await Store.loadAttendance();
    final loadedSettings = await Store.loadSettings();

    if (!mounted) {
      return;
    }

    setState(() {
      attendance = loadedAttendance;
      settings = loadedSettings;
      loading = false;
    });
  }

  String keyFor(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Attendance? getDay(DateTime date) {
    return attendance[keyFor(date)];
  }

  void changeMonth(int value) {
    setState(() {
      month = DateTime(
        month.year,
        month.month + value,
      );
    });
  }

  Future<void> editDay(DateTime date) async {
    final result = await showDialog<Attendance>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AttendanceDialog(
          date: date,
          initial: getDay(date) ??
              Attendance(
                status: DayStatus.present,
                hours: settings.normalHours,
              ),
          defaultHours: settings.normalHours,
        );
      },
    );

    if (result == null) {
      return;
    }

    attendance[keyFor(date)] = result;

    await Store.saveAttendance(attendance);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openSettings() async {
    final result = await showModalBottomSheet<Settings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SettingsSheet(
          initial: settings,
          month: month,
        );
      },
    );

    if (result == null) {
      return;
    }

    settings = result;

    await Store.saveSettings(settings);

    if (mounted) {
      setState(() {});
    }
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
          index: tab,
          children: [
            MonthScreen(
              month: month,
              attendance: attendance,
              settings: settings,
              onDayTap: editDay,
              onPrevious: () => changeMonth(-1),
              onNext: () => changeMonth(1),
              onSettings: openSettings,
            ),
            YearScreen(
              year: month.year,
              attendance: attendance,
              onDayTap: editDay,
              onPrevious: () {
                setState(() {
                  month = DateTime(
                    month.year - 1,
                    month.month,
                  );
                });
              },
              onNext: () {
                setState(() {
                  month = DateTime(
                    month.year + 1,
                    month.month,
                  );
                });
              },
            ),
            SummaryScreen(
              month: month,
              attendance: attendance,
              settings: settings,
              onPrevious: () => changeMonth(-1),
              onNext: () => changeMonth(1),
              onSettings: openSettings,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WorkerPayBanner(),
          NavigationBar(
            height: 78,
            backgroundColor: const Color(0xFFEFF1F6),
            indicatorColor: const Color(0xFFD6E8FB),
            selectedIndex: tab,
            onDestinationSelected: (value) {
              setState(() {
                tab = value;
              });
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
        ],
      ),
    );
  }
}

class WorkerPayBanner extends StatefulWidget {
  const WorkerPayBanner({super.key});

  @override
  State<WorkerPayBanner> createState() => _WorkerPayBannerState();
}

class _WorkerPayBannerState extends State<WorkerPayBanner> {
  BannerAd? banner;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    loadBanner();
  }

  void loadBanner() {
    final ad = BannerAd(
      adUnitId: testBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            banner = ad as BannerAd;
            loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();

          if (mounted) {
            setState(() {
              loaded = false;
            });
          }
        },
      ),
    );

    ad.load();
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded || banner == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: banner!.size.width.toDouble(),
      height: banner!.size.height.toDouble(),
      child: AdWidget(
        ad: banner!,
      ),
    );
  }
}

class MonthScreen extends StatelessWidget {
  final DateTime month;
  final Map<String, Attendance> attendance;
  final Settings settings;

  final Future<void> Function(DateTime) onDayTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSettings;

  const MonthScreen({
    super.key,
    required this.month,
    required this.attendance,
    required this.settings,
    required this.onDayTap,
    required this.onPrevious,
    required this.onNext,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final counts = monthCounts(
      month,
      attendance,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                onPressed: onPrevious,
                icon: const Icon(
                  Icons.chevron_left,
                  size: 34,
                ),
              ),
              Text(
                monthName(month),
                style: const TextStyle(
                  fontSize: 21,
                ),
              ),
              IconButton(
                onPressed: onNext,
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
                child: ActionPill(
                  icon: Icons.access_time,
                  label: 'Hours',
                  color: primary,
                  onTap: onSettings,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionPill(
                  icon: Icons.more_time,
                  label: 'OT',
                  color: otGreen,
                  onTap: onSettings,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionPill(
                  icon: Icons.currency_rupee,
                  label: 'Payment',
                  color: primary,
                  onTap: onSettings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          CalendarCard(
            month: month,
            attendance: attendance,
            onDayTap: onDayTap,
          ),
          const SizedBox(height: 18),
          SummaryMiniCard(
            month: month,
            counts: counts,
          ),
        ],
      ),
    );
  }
}

class ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionPill({
    super.key,
    required this.icon,
    required this.label,
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
        size: 28,
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 18,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 13,
        ),
        side: const BorderSide(
          color: Color(0xFF8D969E),
          width: 1.5,
        ),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class CalendarCard extends StatelessWidget {
  final DateTime month;
  final Map<String, Attendance> attendance;
  final Future<void> Function(DateTime) onDayTap;

  const CalendarCard({
    super.key,
    required this.month,
    required this.attendance,
    required this.onDayTap,
  });

  Attendance? day(DateTime date) {
    return attendance[
        '${date.year}-${date.month}-${date.day}'];
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(
      month.year,
      month.month,
      1,
    );

    final start = first.weekday % 7;

    final days = DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;

    final cells = <DateTime?>[
      ...List<DateTime?>.filled(
        start,
        null,
      ),
      ...List.generate(
        days,
        (index) => DateTime(
          month.year,
          month.month,
          index + 1,
        ),
      ),
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Container(
      padding: const EdgeInsets.all(12),
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
                          fontSize: 12,
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
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .88,
            ),
            itemBuilder: (_, index) {
              final date = cells[index];

              if (date == null) {
                return const SizedBox();
              }

              final a = day(date);

              return InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () => onDayTap(date),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: a == null
                        ? Colors.white
                        : dayFill(a.status),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: a == null
                          ? border
                          : dayBorder(a.status),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 17,
                          color: date.weekday ==
                                  DateTime.sunday
                              ? absentRed
                              : textDark,
                        ),
                      ),
                      const Spacer(),
                      if (a != null && a.hours > 0)
                        Text(
                          '${fmt(a.hours)}H',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (a != null && a.ot > 0)
                        Text(
                          'OT ${fmt(a.ot)}H',
                          style: const TextStyle(
                            color: otGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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

class SummaryMiniCard extends StatelessWidget {
  final DateTime month;
  final Map<String, double> counts;

  const SummaryMiniCard({
    super.key,
    required this.month,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              StatChip(
                'Present: ${counts['present']!.toInt()}',
                primaryLight,
                primary,
              ),
              StatChip(
                'Absent: ${counts['absent']!.toInt()}',
                const Color(0xFFFFEEF0),
                absentRed,
              ),
              StatChip(
                'Half Day: ${counts['half']!.toInt()}',
                const Color(0xFFFFF3E5),
                halfOrange,
              ),
              StatChip(
                'Holiday: ${counts['holiday']!.toInt()}',
                const Color(0xFFF0F2F4),
                textGrey,
              ),
              StatChip(
                'Hours: ${fmt(counts['hours']!)} H',
                primaryLight,
                primary,
              ),
              StatChip(
                'OT: ${fmt(counts['ot']!)} H',
                const Color(0xFFE8F8EF),
                otGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const StatChip(
    this.text,
    this.background,
    this.foreground, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class YearScreen extends StatelessWidget {
  final int year;
  final Map<String, Attendance> attendance;
  final Future<void> Function(DateTime) onDayTap;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const YearScreen({
    super.key,
    required this.year,
    required this.attendance,
    required this.onDayTap,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        24,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(
                  Icons.chevron_left,
                  size: 32,
                ),
              ),
              Text(
                '$year',
                style: const TextStyle(
                  fontSize: 21,
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(
                  Icons.chevron_right,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int month = 1; month <= 12; month++)
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: YearMonthCard(
                year: year,
                month: month,
                attendance: attendance,
                onDayTap: onDayTap,
              ),
            ),
        ],
      ),
    );
  }
}

class YearMonthCard extends StatelessWidget {
  final int year;
  final int month;
  final Map<String, Attendance> attendance;
  final Future<void> Function(DateTime) onDayTap;

  const YearMonthCard({
    super.key,
    required this.year,
    required this.month,
    required this.attendance,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(
      year,
      month,
      1,
    );

    final start = first.weekday % 7;

    final days = DateTime(
      year,
      month + 1,
      0,
    ).day;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
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
              fontWeight: FontWeight.w700,
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
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount: start + days,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (_, index) {
              if (index < start) {
                return const SizedBox();
              }

              final date = DateTime(
                year,
                month,
                index - start + 1,
              );

              final a = attendance[
                  '${date.year}-${date.month}-${date.day}'];

              return InkWell(
                onTap: () => onDayTap(date),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          a != null &&
                                  a.status !=
                                      DayStatus.none
                              ? FontWeight.w800
                              : FontWeight.w400,
                      color: a == null
                          ? date.weekday ==
                                  DateTime.sunday
                              ? absentRed
                              : textDark
                          : dayText(a.status),
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

class SummaryScreen extends StatelessWidget {
  final DateTime month;
  final Map<String, Attendance> attendance;
  final Settings settings;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSettings;

  const SummaryScreen({
    super.key,
    required this.month,
    required this.attendance,
    required this.settings,
    required this.onPrevious,
    required this.onNext,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final counts = monthCounts(
      month,
      attendance,
    );

    final workingDays =
        counts['present']! +
        counts['half']! * 0.5;

    double dailyRate;

    if (settings.mode == 'daily') {
      dailyRate = settings.dailyWage;
    } else if (settings.mode == 'month') {
      final calendarDays = DateTime(
        month.year,
        month.month + 1,
        0,
      ).day;

      dailyRate =
          settings.monthlySalary /
          calendarDays;
    } else {
      dailyRate =
          settings.monthlySalary /
          (settings.workingDays <= 0
              ? 26
              : settings.workingDays);
    }

    final basicPayment =
        workingDays * dailyRate;

    final otAmount =
        counts['ot']! * settings.otRate;

    final total =
        basicPayment +
        otAmount -
        settings.advance -
        settings.deduction;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Attendance & Payment Summary',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(
                  Icons.chevron_left,
                ),
              ),
              Text(
                monthName(month),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'ATTENDANCE BREAKDOWN',
            icon: Icons.calendar_month,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: BigStat(
                        '${counts['present']!.toInt()} Days',
                        'Present',
                        primaryLight,
                        primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BigStat(
                        '${counts['absent']!.toInt()} Days',
                        'Absent',
                        const Color(0xFFFFEEEE),
                        absentRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BigStat(
                        '${counts['half']!.toInt()} Days',
                        'Half Day',
                        const Color(0xFFFFF7D9),
                        halfOrange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InfoBox(
                        'Working Hours',
                        '${fmt(counts['hours']!)} H',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoBox(
                        'Overtime',
                        '${fmt(counts['ot']!)} H',
                        green: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'PAYMENT CALCULATION',
            icon: Icons.currency_rupee,
            trailing: TextButton.icon(
              onPressed: onSettings,
              icon: const Icon(
                Icons.edit,
                size: 16,
              ),
              label: const Text(
                'Edit Rates',
              ),
            ),
            child: Column(
              children: [
                PaymentRow(
                  'Monthly Salary',
                  money(settings.monthlySalary),
                ),
                const SizedBox(height: 12),
                PaymentRow(
                  'Basic Payment',
                  money(basicPayment),
                  bold: true,
                ),
                const SizedBox(height: 12),
                PaymentRow(
                  'OT Rate',
                  '${money(settings.otRate)} / Hour',
                  bold: true,
                ),
                const SizedBox(height: 12),
                PaymentRow(
                  'OT Amount',
                  '+ ${money(otAmount)}',
                  green: true,
                  bold: true,
                ),
                if (settings.advance > 0) ...[
                  const SizedBox(height: 12),
                  PaymentRow(
                    'Advance',
                    '- ${money(settings.advance)}',
                    red: true,
                  ),
                ],
                if (settings.deduction > 0) ...[
                  const SizedBox(height: 12),
                  PaymentRow(
                    'Deduction',
                    '- ${money(settings.deduction)}',
                    red: true,
                  ),
                ],
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius:
                        BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Expected Total Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                          ),
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

class BigStat extends StatelessWidget {
  final String value;
  final String label;
  final Color background;
  final Color foreground;

  const BigStat(
    this.value,
    this.label,
    this.background,
    this.foreground, {
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
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
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
  final bool green;

  const InfoBox(
    this.title,
    this.value, {
    super.key,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: green
            ? const Color(0xFFE9FAF0)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color:
                  green ? otGreen : textGrey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool green;
  final bool red;
  final bool bold;

  const PaymentRow(
    this.label,
    this.value, {
    super.key,
    this.green = false,
    this.red = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
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
                ? otGreen
                : red
                    ? absentRed
                    : primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: border,
        ),
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
                    letterSpacing: .7,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class AttendanceDialog extends StatefulWidget {
  final DateTime date;
  final Attendance initial;
  final double defaultHours;

  const AttendanceDialog({
    super.key,
    required this.date,
    required this.initial,
    required this.defaultHours,
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

    status = widget.initial.status ==
            DayStatus.none
        ? DayStatus.present
        : widget.initial.status;

    hours = TextEditingController(
      text: fmt(
        widget.initial.hours == 0
            ? widget.defaultHours
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
        vertical: 24,
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
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
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
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'SELECT STATUS',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusButton(
                  'PRESENT',
                  DayStatus.present,
                  status,
                  () {
                    setState(() {
                      status =
                          DayStatus.present;
                    });
                  },
                ),
                StatusButton(
                  'HALF DAY',
                  DayStatus.half,
                  status,
                  () {
                    setState(() {
                      status =
                          DayStatus.half;
                    });
                  },
                ),
                StatusButton(
                  'ABSENT',
                  DayStatus.absent,
                  status,
                  () {
                    setState(() {
                      status =
                          DayStatus.absent;
                    });
                  },
                ),
                StatusButton(
                  'HOLIDAY',
                  DayStatus.holiday,
                  status,
                  () {
                    setState(() {
                      status =
                          DayStatus.holiday;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: hours,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText: 'Working Hours',
                prefixIcon:
                    Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 16),
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
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final h =
                      double.tryParse(
                            hours.text,
                          ) ??
                          0;

                  final o =
                      double.tryParse(
                            ot.text,
                          ) ??
                          0;

                  Navigator.pop(
                    context,
                    Attendance(
                      status: status,
                      hours: h,
                      ot: o,
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
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusButton extends StatelessWidget {
  final String label;
  final DayStatus value;
  final DayStatus selected;
  final VoidCallback onTap;

  const StatusButton(
    this.label,
    this.value,
    this.selected,
    this.onTap, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;

    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: active
              ? primaryLight
              : Colors.white,
          border: Border.all(
            color: active
                ? primary
                : border,
            width: active ? 2 : 1,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
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

    salary = TextEditingController(
      text: fmt(s.monthlySalary),
    );

    days = TextEditingController(
      text: fmt(s.workingDays),
    );

    hours = TextEditingController(
      text: fmt(s.normalHours),
    );

    ot = TextEditingController(
      text: fmt(s.otRate),
    );

    daily = TextEditingController(
      text: fmt(s.dailyWage),
    );

    advance = TextEditingController(
      text: fmt(s.advance),
    );

    deduction = TextEditingController(
      text: fmt(s.deduction),
    );
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

  Widget field(
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: true,
          fillColor:
              const Color(0xFFFCFDFE),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height *
              .92,
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        20,
      ),
      decoration: const BoxDecoration(
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
                decoration:
                    BoxDecoration(
                  color: border,
                  borderRadius:
                      BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Salary & OT Configuration',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'CALCULATION MODE',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: modeButton(
                    'Fixed',
                    'fixed',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: modeButton(
                    'Month',
                    'month',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: modeButton(
                    'Daily',
                    'daily',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (mode != 'daily')
              field(
                'Monthly Salary',
                salary,
                '₹',
              ),
            if (mode == 'fixed')
              field(
                'Working Days',
                days,
                'Days',
              ),
            field(
              'Normal Hours',
              hours,
              'Hours',
            ),
            field(
              'OT Rate',
              ot,
              '₹ / Hour',
            ),
            if (mode == 'daily')
              field(
                'Daily Wage',
                daily,
                '₹ / Day',
              ),
            field(
              'Advance',
              advance,
              '₹',
            ),
            field(
              'Deduction',
              deduction,
              '₹',
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final result = Settings(
                    mode: mode,
                    monthlySalary:
                        numValue(salary),
                    workingDays:
                        numValue(days, 26),
                    normalHours:
                        numValue(hours, 8),
                    otRate:
                        numValue(ot),
                    dailyWage:
                        numValue(daily),
                    advance:
                        numValue(advance),
                    deduction:
                        numValue(deduction),
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
                child: const Text(
                  'Save',
                ),
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
  ) {
    final active = mode == value;

    return InkWell(
      onTap: () {
        setState(() {
          mode = value;
        });
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: active
              ? primaryLight
              : Colors.white,
          border: Border.all(
            color: active
                ? primary
                : border,
            width: active ? 2 : 1,
          ),
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active
                ? primary
                : textDark,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Map<String, double> monthCounts(
  DateTime month,
  Map<String, Attendance> attendance,
) {
  double present = 0;
  double absent = 0;
  double half = 0;
  double holiday = 0;
  double hours = 0;
  double ot = 0;

  final totalDays = DateTime(
    month.year,
    month.month + 1,
    0,
  ).day;

  for (int day = 1;
      day <= totalDays;
      day++) {
    final item = attendance[
        '${month.year}-${month.month}-$day'];

    if (item == null) {
      continue;
    }

    if (item.status == DayStatus.present) {
      present++;
    }

    if (item.status == DayStatus.absent) {
      absent++;
    }

    if (item.status == DayStatus.half) {
      half++;
    }

    if (item.status == DayStatus.holiday) {
      holiday++;
    }

    hours += item.hours;
    ot += item.ot;
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

Color dayFill(DayStatus status) {
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

Color dayText(DayStatus status) {
  switch (status) {
    case DayStatus.present:
      return primary;

    case DayStatus.absent:
      return absentRed;

    case DayStatus.half:
      return halfOrange;

    case DayStatus.holiday:
      return textGrey;

    case DayStatus.none:
      return textDark;
  }
}

String monthName(DateTime date) {
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

  return '${names[date.month - 1]} ${date.year}';
}

String formatDate(DateTime date) {
  const weekdays = [
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

  return '${weekdays[date.weekday - 1]}, '
      '${date.day} ${months[date.month - 1]} '
      '${date.year}';
}

String fmt(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}

String money(double value) {
  return '₹${value.round()}';
}

double numValue(
  TextEditingController controller, [
  double fallback = 0,
]) {
  return double.tryParse(
        controller.text.trim(),
      ) ??
      fallback;
}
