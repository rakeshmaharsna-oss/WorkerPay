import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color primaryBlue = Color(0xFF005086);
const Color bgColor = Color(0xFFF2F8FD);
const Color textColor = Color(0xFF081725);
const Color secondaryColor = Color(0xFF596571);
const Color borderColor = Color(0xFFD6DFE8);
const Color presentColor = Color(0xFF005086);
const Color absentColor = Color(0xFFDC2626);
const Color halfDayColor = Color(0xFFD97706);
const Color otColor = Color(0xFF16A34A);
const Color holidayColor = Color(0xFFE5E7EB);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = LocalStorage();
  await storage.load();
  runApp(WorkerPayApp(storage: storage));
}

class Attendance {
  String status;
  double hours;
  double otHours;
  double otRate;

  Attendance({
    required this.status,
    this.hours = 0,
    this.otHours = 0,
    this.otRate = 0,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'hours': hours,
        'otHours': otHours,
        'otRate': otRate,
      };

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      status: json['status'] ?? 'present',
      hours: (json['hours'] ?? 0).toDouble(),
      otHours: (json['otHours'] ?? 0).toDouble(),
      otRate: (json['otRate'] ?? 0).toDouble(),
    );
  }
}

class MonthSettings {
  double salary;
  double dailyWage;
  double normalHours;
  double otRate;
  double advance;
  double deduction;

  MonthSettings({
    this.salary = 0,
    this.dailyWage = 0,
    this.normalHours = 8,
    this.otRate = 0,
    this.advance = 0,
    this.deduction = 0,
  });

  Map<String, dynamic> toJson() => {
        'salary': salary,
        'dailyWage': dailyWage,
        'normalHours': normalHours,
        'otRate': otRate,
        'advance': advance,
        'deduction': deduction,
      };

  factory MonthSettings.fromJson(Map<String, dynamic> json) {
    return MonthSettings(
      salary: (json['salary'] ?? 0).toDouble(),
      dailyWage: (json['dailyWage'] ?? 0).toDouble(),
      normalHours: (json['normalHours'] ?? 8).toDouble(),
      otRate: (json['otRate'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
      deduction: (json['deduction'] ?? 0).toDouble(),
    );
  }
}

String dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String monthKey(int year, int month) {
  return '$year-${month.toString().padLeft(2, '0')}';
}

String money(double value) {
  return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
}

String fmt(double value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}

const List<String> months = [
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

class LocalStorage extends ChangeNotifier {
  final Map<String, Attendance> attendance = {};
  final Map<String, MonthSettings> settings = {};

  SharedPreferences? prefs;

  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();

    final attendanceData = prefs!.getString('attendance');

    if (attendanceData != null) {
      final map = jsonDecode(attendanceData) as Map<String, dynamic>;

      for (final item in map.entries) {
        attendance[item.key] =
            Attendance.fromJson(item.value as Map<String, dynamic>);
      }
    }

    final settingsData = prefs!.getString('settings');

    if (settingsData != null) {
      final map = jsonDecode(settingsData) as Map<String, dynamic>;

      for (final item in map.entries) {
        settings[item.key] =
            MonthSettings.fromJson(item.value as Map<String, dynamic>);
      }
    }
  }

  Future<void> save() async {
    await prefs?.setString(
      'attendance',
      jsonEncode(
        attendance.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      ),
    );

    await prefs?.setString(
      'settings',
      jsonEncode(
        settings.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      ),
    );
  }

  Attendance? getAttendance(DateTime date) {
    return attendance[dateKey(date)];
  }

  MonthSettings getSettings(int year, int month) {
    return settings.putIfAbsent(
      monthKey(year, month),
      () => MonthSettings(),
    );
  }

  Future<void> setAttendance(
    DateTime date,
    Attendance value,
  ) async {
    attendance[dateKey(date)] = value;
    await save();
    notifyListeners();
  }

  Future<void> deleteAttendance(DateTime date) async {
    attendance.remove(dateKey(date));
    await save();
    notifyListeners();
  }

  Future<void> setSettings(
    int year,
    int month,
    MonthSettings value,
  ) async {
    settings[monthKey(year, month)] = value;
    await save();
    notifyListeners();
  }
}

class WorkerPayApp extends StatelessWidget {
  final LocalStorage storage;

  const WorkerPayApp({
    super.key,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: storage,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Worker Pay',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: bgColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryBlue,
            ),
          ),
          home: MainScreen(storage: storage),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final LocalStorage storage;

  const MainScreen({
    super.key,
    required this.storage,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedTab = 0;

  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  Widget build(BuildContext context) {
    final pages = [
      MonthScreen(
        storage: widget.storage,
        month: selectedMonth,
        onMonthChanged: (month) {
          setState(() {
            selectedMonth = month;
          });
        },
      ),
      YearScreen(
        storage: widget.storage,
        year: selectedMonth.year,
        onMonthSelected: (month) {
          setState(() {
            selectedMonth = month;
            selectedTab = 0;
          });
        },
      ),
      SummaryScreen(
        storage: widget.storage,
        month: selectedMonth,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[selectedTab],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Month',
          ),
          NavigationDestination(
            icon: Icon(Icons.date_range),
            label: 'Year',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_rupee),
            label: 'Summary',
          ),
        ],
      ),
    );
  }
}

class MonthScreen extends StatelessWidget {
  final LocalStorage storage;
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthScreen({
    super.key,
    required this.storage,
    required this.month,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = calculateTotals(storage, month);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            8,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Worker Pay',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  onMonthChanged(
                    DateTime(
                      month.year,
                      month.month - 1,
                    ),
                  );
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${months[month.month - 1]} ${month.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  onMonthChanged(
                    DateTime(
                      month.year,
                      month.month + 1,
                    ),
                  );
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Row(
            children: [
              QuickButton(
                icon: Icons.access_time,
                label: 'Hours',
                color: primaryBlue,
                onTap: () {
                  showMessage(
                    context,
                    'Working Hours',
                    '${fmt(total.hours)} H',
                  );
                },
              ),
              const SizedBox(width: 8),
              QuickButton(
                icon: Icons.more_time,
                label: 'OT',
                color: otColor,
                onTap: () {
                  showMessage(
                    context,
                    'Overtime',
                    '${fmt(total.ot)} H',
                  );
                },
              ),
              const SizedBox(width: 8),
              QuickButton(
                icon: Icons.currency_rupee,
                label: 'Payment',
                color: primaryBlue,
                onTap: () {
                  showMessage(
                    context,
                    'Expected Payment',
                    money(total.expected),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CalendarCard(
                  storage: storage,
                  month: month,
                  onDateTap: (date) {
                    showAttendanceDialog(
                      context,
                      storage,
                      date,
                    );
                  },
                ),
                const SizedBox(height: 12),
                MiniSummary(
                  storage: storage,
                  month: month,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class CalendarCard extends StatelessWidget {
  final LocalStorage storage;
  final DateTime month;
  final ValueChanged<DateTime> onDateTap;

  const CalendarCard({
    super.key,
    required this.storage,
    required this.month,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(
      month.year,
      month.month,
      1,
    );

    final daysInMonth = DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;

    final firstDayIndex = firstDay.weekday % 7;

    final cells =
        ((firstDayIndex + daysInMonth + 6) ~/ 7) * 7;

    const weekdays = [
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
    ];

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: weekdays
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 8),

            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: cells,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: .72,
              ),
              itemBuilder: (context, index) {
                final day =
                    index - firstDayIndex + 1;

                if (day < 1 ||
                    day > daysInMonth) {
                  return const SizedBox();
                }

                final date = DateTime(
                  month.year,
                  month.month,
                  day,
                );

                final attendance =
                    storage.getAttendance(date);

                return InkWell(
                  onTap: () => onDateTap(date),
                  borderRadius:
                      BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding:
                        const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          getCellBackground(
                        attendance,
                      ),
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            getCellBorder(
                          attendance,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                getTextColor(
                              attendance,
                            ),
                          ),
                        ),

                        if (attendance != null &&
                            attendance.hours > 0)
                          Text(
                            '${fmt(attendance.hours)}H',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  getTextColor(
                                attendance,
                              ),
                            ),
                          ),

                        if (attendance != null &&
                            attendance.otHours > 0)
                          const Text(
                            'OT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.bold,
                              color: otColor,
                            ),
                          ),

                        if (attendance != null &&
                            attendance.status ==
                                'holiday')
                          const Text(
                            'Holiday',
                            style: TextStyle(
                              fontSize: 7,
                              color:
                                  secondaryColor,
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
      ),
    );
  }
}

Color getCellBackground(
  Attendance? attendance,
) {
  if (attendance == null) {
    return Colors.white;
  }

  switch (attendance.status) {
    case 'present':
      return presentColor.withOpacity(.08);

    case 'absent':
      return absentColor.withOpacity(.08);

    case 'half':
      return halfDayColor.withOpacity(.10);

    case 'holiday':
      return holidayColor;

    default:
      return Colors.white;
  }
}

Color getCellBorder(
  Attendance? attendance,
) {
  if (attendance == null) {
    return borderColor;
  }

  switch (attendance.status) {
    case 'present':
      return presentColor.withOpacity(.45);

    case 'absent':
      return absentColor.withOpacity(.45);

    case 'half':
      return halfDayColor.withOpacity(.55);

    case 'holiday':
      return const Color(0xFFCBD5E1);

    default:
      return borderColor;
  }
}

Color getTextColor(
  Attendance? attendance,
) {
  if (attendance == null) {
    return textColor;
  }

  switch (attendance.status) {
    case 'present':
      return presentColor;

    case 'absent':
      return absentColor;

    case 'half':
      return halfDayColor;

    default:
      return secondaryColor;
  }
}

class MiniSummary extends StatelessWidget {
  final LocalStorage storage;
  final DateTime month;

  const MiniSummary({
    super.key,
    required this.storage,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final total =
        calculateTotals(storage, month);

    return Card(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              '${months[month.month - 1]} Summary',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatChip(
                  label: 'Present',
                  value: '${total.present}',
                  color: presentColor,
                ),
                StatChip(
                  label: 'Absent',
                  value: '${total.absent}',
                  color: absentColor,
                ),
                StatChip(
                  label: 'Half Day',
                  value: '${total.half}',
                  color: halfDayColor,
                ),
                StatChip(
                  label: 'Holiday',
                  value: '${total.holiday}',
                  color: secondaryColor,
                ),
                StatChip(
                  label: 'Hours',
                  value: '${fmt(total.hours)} H',
                  color: primaryBlue,
                ),
                StatChip(
                  label: 'OT',
                  value: '${fmt(total.ot)} H',
                  color: otColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class YearScreen extends StatelessWidget {
  final LocalStorage storage;
  final int year;
  final ValueChanged<DateTime>
      onMonthSelected;

  const YearScreen({
    super.key,
    required this.storage,
    required this.year,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Year Calendar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding:
                const EdgeInsets.all(12),
            itemCount: 12,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final monthNumber =
                  index + 1;

              return InkWell(
                onTap: () {
                  onMonthSelected(
                    DateTime(
                      year,
                      monthNumber,
                    ),
                  );
                },
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  child: Padding(
                    padding:
                        const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          months[
                              monthNumber - 1],
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: MiniMonth(
                            storage: storage,
                            year: year,
                            month:
                                monthNumber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MiniMonth extends StatelessWidget {
  final LocalStorage storage;
  final int year;
  final int month;

  const MiniMonth({
    super.key,
    required this.storage,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay =
        DateTime(year, month, 1);

    final days =
        DateTime(year, month + 1, 0).day;

    final start =
        firstDay.weekday % 7;

    return GridView.builder(
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemBuilder: (context, index) {
        final day =
            index - start + 1;

        if (day < 1 || day > days) {
          return const SizedBox();
        }

        final attendance =
            storage.getAttendance(
          DateTime(year, month, day),
        );

        Color? color;

        if (attendance != null) {
          color =
              getTextColor(attendance);
        }

        return Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 6,
                  color: color == null
                      ? secondaryColor
                      : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SummaryScreen extends StatelessWidget {
  final LocalStorage storage;
  final DateTime month;

  const SummaryScreen({
    super.key,
    required this.storage,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final total =
        calculateTotals(storage, month);

    final settings =
        storage.getSettings(
      month.year,
      month.month,
    );

    final basicPayment =
        settings.salary > 0
            ? (settings.salary / 30) *
                (total.present +
                    total.half * .5)
            : settings.dailyWage *
                (total.present +
                    total.half * .5);

    final otPayment =
        total.ot * settings.otRate;

    final expected =
        basicPayment +
            otPayment -
            settings.advance -
            settings.deduction;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Payment Summary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  showSettingsDialog(
                    context,
                    storage,
                    month,
                  );
                },
                icon:
                    const Icon(Icons.settings),
              ),
            ],
          ),

          Text(
            '${months[month.month - 1]} ${month.year}',
            style: const TextStyle(
              color: secondaryColor,
            ),
          ),

          const SizedBox(height: 15),

          InfoCard(
            title: 'Attendance',
            children: [
              infoRow(
                'Present',
                '${total.present} Days',
                presentColor,
              ),
              infoRow(
                'Absent',
                '${total.absent} Days',
                absentColor,
              ),
              infoRow(
                'Half Day',
                '${total.half} Days',
                halfDayColor,
              ),
              infoRow(
                'Holiday',
                '${total.holiday} Days',
                secondaryColor,
              ),
            ],
          ),

          const SizedBox(height: 10),

          InfoCard(
            title: 'Working Time',
            children: [
              infoRow(
                'Working Hours',
                '${fmt(total.hours)} H',
                primaryBlue,
              ),
              infoRow(
                'OT Hours',
                '${fmt(total.ot)} H',
                otColor,
              ),
            ],
          ),

          const SizedBox(height: 10),

          InfoCard(
            title: 'Payment',
            children: [
              infoRow(
                'Monthly Salary',
                money(settings.salary),
                primaryBlue,
              ),
              infoRow(
                'Daily Wage',
                money(settings.dailyWage),
                primaryBlue,
              ),
              infoRow(
                'OT Rate',
                '${money(settings.otRate)} / hour',
                otColor,
              ),
              infoRow(
                'Basic Payment',
                money(basicPayment),
                primaryBlue,
              ),
              infoRow(
                'OT Payment',
                money(otPayment),
                otColor,
              ),
              infoRow(
                'Advance',
                money(settings.advance),
                absentColor,
              ),
              infoRow(
                'Deduction',
                money(settings.deduction),
                absentColor,
              ),
              const Divider(),
              infoRow(
                'Expected Payment',
                money(expected),
                primaryBlue,
                big: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () {
              showSettingsDialog(
                context,
                storage,
                month,
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text(
              'Edit Salary / OT Settings',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: primaryBlue,
              minimumSize:
                  const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const InfoCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget infoRow(
  String title,
  String value,
  Color color, {
  bool big = false,
}) {
  return Padding(
    padding:
        const EdgeInsets.symmetric(
      vertical: 5,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: secondaryColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: big ? 21 : 14,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class Totals {
  int present = 0;
  int absent = 0;
  int half = 0;
  int holiday = 0;
  double hours = 0;
  double ot = 0;
  double expected = 0;
}

Totals calculateTotals(
  LocalStorage storage,
  DateTime month,
) {
  final result = Totals();

  final days =
      DateTime(
        month.year,
        month.month + 1,
        0,
      ).day;

  for (int day = 1;
      day <= days;
      day++) {
    final attendance =
        storage.getAttendance(
      DateTime(
        month.year,
        month.month,
        day,
      ),
    );

    if (attendance == null) {
      continue;
    }

    switch (attendance.status) {
      case 'present':
        result.present++;
        break;

      case 'absent':
        result.absent++;
        break;

      case 'half':
        result.half++;
        break;

      case 'holiday':
        result.holiday++;
        break;
    }

    result.hours +=
        attendance.hours;

    result.ot +=
        attendance.otHours;
  }

  final settings =
      storage.getSettings(
    month.year,
    month.month,
  );

  final basic =
      settings.salary > 0
          ? (settings.salary / 30) *
              (result.present +
                  result.half * .5)
          : settings.dailyWage *
              (result.present +
                  result.half * .5);

  result.expected =
      basic +
          result.ot * settings.otRate -
          settings.advance -
          settings.deduction;

  return result;
}

Future<void> showAttendanceDialog(
  BuildContext context,
  LocalStorage storage,
  DateTime date,
) async {
  final old =
      storage.getAttendance(date);

  final settings =
      storage.getSettings(
    date.year,
    date.month,
  );

  String status =
      old?.status ?? 'present';

  final hoursController =
      TextEditingController(
    text: old == null
        ? fmt(settings.normalHours)
        : fmt(old.hours),
  );

  final otController =
      TextEditingController(
    text: old == null
        ? '0'
        : fmt(old.otHours),
  );

  final rateController =
      TextEditingController(
    text: old == null
        ? fmt(settings.otRate)
        : fmt(old.otRate),
  );

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder:
            (context, setState) {
          return AlertDialog(
            title: Text(
              '${date.day} ${months[date.month - 1]}',
            ),
            content:
                SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<
                      String>(
                    value: status,
                    decoration:
                        const InputDecoration(
                      labelText: 'Status',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'present',
                        child: Text(
                          'Full Day / Present',
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'absent',
                        child:
                            Text('Absent'),
                      ),
                      DropdownMenuItem(
                        value: 'half',
                        child:
                            Text('Half Day'),
                      ),
                      DropdownMenuItem(
                        value: 'holiday',
                        child: Text(
                          'Holiday / Leave',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        status =
                            value ??
                                'present';
                      });
                    },
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  TextField(
                    controller:
                        hoursController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Working Hours',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  TextField(
                    controller:
                        otController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'OT Hours',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  TextField(
                    controller:
                        rateController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(
                      labelText:
                          'OT Rate / hour',
                      border:
                          OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (old != null)
                TextButton(
                  onPressed: () async {
                    await storage
                        .deleteAttendance(
                      date,
                    );

                    if (context.mounted) {
                      Navigator.pop(
                        context,
                      );
                    }
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color:
                          absentColor,
                    ),
                  ),
                ),

              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                child:
                    const Text('Cancel'),
              ),

              FilledButton(
                onPressed: () async {
                  final hours =
                      double.tryParse(
                            hoursController
                                .text,
                          ) ??
                          0;

                  final ot =
                      double.tryParse(
                            otController
                                .text,
                          ) ??
                          0;

                  final rate =
                      double.tryParse(
                            rateController
                                .text,
                          ) ??
                          settings.otRate;

                  await storage
                      .setAttendance(
                    date,
                    Attendance(
                      status: status,
                      hours:
                          status == 'absent' ||
                                  status ==
                                      'holiday'
                              ? 0
                              : hours,
                      otHours: ot,
                      otRate: rate,
                    ),
                  );

                  if (context.mounted) {
                    Navigator.pop(
                      context,
                    );
                  }
                },
                child:
                    const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showSettingsDialog(
  BuildContext context,
  LocalStorage storage,
  DateTime month,
) async {
  final settings =
      storage.getSettings(
    month.year,
    month.month,
  );

  final salary =
      TextEditingController(
    text: fmt(settings.salary),
  );

  final daily =
      TextEditingController(
    text: fmt(settings.dailyWage),
  );

  final normal =
      TextEditingController(
    text: fmt(settings.normalHours),
  );

  final ot =
      TextEditingController(
    text: fmt(settings.otRate),
  );

  final advance =
      TextEditingController(
    text: fmt(settings.advance),
  );

  final deduction =
      TextEditingController(
    text: fmt(settings.deduction),
  );

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          '${months[month.month - 1]} ${month.year}',
        ),
        content:
            SingleChildScrollView(
          child: Column(
            children: [
              settingField(
                salary,
                'Monthly Salary',
              ),
              settingField(
                daily,
                'Daily Wage',
              ),
              settingField(
                normal,
                'Normal Working Hours',
              ),
              settingField(
                ot,
                'OT Rate / hour',
              ),
              settingField(
                advance,
                'Advance',
              ),
              settingField(
                deduction,
                'Deduction',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            child:
                const Text('Cancel'),
          ),

          FilledButton(
            onPressed: () async {
              await storage
                  .setSettings(
                month.year,
                month.month,
                MonthSettings(
                  salary:
                      double.tryParse(
                            salary.text,
                          ) ??
                          0,
                  dailyWage:
                      double.tryParse(
                            daily.text,
                          ) ??
                          0,
                  normalHours:
                      double.tryParse(
                            normal.text,
                          ) ??
                          8,
                  otRate:
                      double.tryParse(
                            ot.text,
                          ) ??
                          0,
                  advance:
                      double.tryParse(
                            advance.text,
                          ) ??
                          0,
                  deduction:
                      double.tryParse(
                            deduction.text,
                          ) ??
                          0,
                ),
              );

              if (context.mounted) {
                Navigator.pop(
                  context,
                );
              }
            },
            child:
                const Text('Save'),
          ),
        ],
      );
    },
  );
}

Widget settingField(
  TextEditingController controller,
  String label,
) {
  return Padding(
    padding:
        const EdgeInsets.only(
      bottom: 10,
    ),
    child: TextField(
      controller: controller,
      keyboardType:
          const TextInputType
              .numberWithOptions(
        decimal: true,
      ),
      decoration:
          InputDecoration(
        labelText: label,
        border:
            const OutlineInputBorder(),
      ),
    ),
  );
}

void showMessage(
  BuildContext context,
  String title,
  String message,
) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            child:
                const Text('OK'),
          ),
        ],
      );
    },
  );
}
