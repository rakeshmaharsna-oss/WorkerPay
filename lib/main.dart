import 'package:flutter/material.dart';
import 'worker_pay_logic.dart';
import 'admob_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        fontFamily: 'sans',
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
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, Attendance> attendance = {};
  Settings settings = Settings();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    attendance = await Store.loadAttendance();
    settings = await Store.loadSettings();
    if (mounted) setState(() {});
  }

  String keyFor(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Attendance? getDay(DateTime d) => attendance[keyFor(d)];

  Future<void> editDay(DateTime d) async {
    final result = await showDialog<Attendance>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AttendanceDialog(
        date: d,
        initial: getDay(d) ??
            Attendance(
              status: DayStatus.present,
              hours: settings.normalHours,
            ),
        defaultHours: settings.normalHours,
      ),
    );

    if (result != null) {
      attendance[keyFor(d)] = result;
      await Store.saveAttendance(attendance);
      setState(() {});
    }
  }

  void changeMonth(int delta) {
    setState(() => month = DateTime(month.year, month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
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
              onPrev: () => changeMonth(-1),
              onNext: () => changeMonth(1),
              onOpenHours: () => _openSettings(),
              onOpenOt: () => _openSettings(),
              onOpenPayment: () => _openSettings(),
            ),
            YearScreen(
              year: month.year,
              attendance: attendance,
              onDayTap: editDay,
              onPrev: () => setState(
                () => month = DateTime(month.year - 1, month.month),
              ),
              onNext: () => setState(
                () => month = DateTime(month.year + 1, month.month),
              ),
            ),
            SummaryScreen(
              month: month,
              attendance: attendance,
              settings: settings,
              onPrev: () => changeMonth(-1),
              onNext: () => changeMonth(1),
              onEditRates: _openSettings,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 78,
        backgroundColor: const Color(0xFFEFF1F6),
        indicatorColor: const Color(0xFFD6E8FB),
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
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

  Future<void> _openSettings() async {
    final s = await showModalBottomSheet<Settings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsSheet(initial: settings, month: month),
    );

    if (s != null) {
      settings = s;
      await Store.saveSettings(settings);
      setState(() {});
    }
  }
}

class MonthScreen extends StatelessWidget {
  final DateTime month;
  final Map<String, Attendance> attendance;
  final Settings settings;
  final Future<void> Function(DateTime) onDayTap;
  final VoidCallback onPrev, onNext, onOpenHours, onOpenOt, onOpenPayment;

  const MonthScreen({
    super.key,
    required this.month,
    required this.attendance,
    required this.settings,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
    required this.onOpenHours,
    required this.onOpenOt,
    required this.onOpenPayment,
  });

  Attendance? day(DateTime d) =>
      attendance['${d.year}-${d.month}-${d.day}'];

  @override
  Widget build(BuildContext context) {
    final counts = monthCounts(month, attendance);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
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
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left, size: 34),
              ),
              Text(
                monthName(month),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w400,
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right, size: 34),
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
                  onTap: onOpenHours,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionPill(
                  icon: Icons.more_time,
                  label: 'OT',
                  color: otGreen,
                  onTap: onOpenOt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionPill(
                  icon: Icons.currency_rupee,
                  label: 'Payment',
                  color: primary,
                  onTap: onOpenPayment,
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
          SummaryMiniCard(month: month, counts: counts),
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
      icon: Icon(icon, color: color, size: 28),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 18),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        side: const BorderSide(color: Color(0xFF8D969E), width: 1.5),
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

  Attendance? day(DateTime d) =>
      attendance['${d.year}-${d.month}-${d.day}'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final start = first.weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;

    final cells = List<DateTime?>.filled(start, null) +
        List.generate(
          days,
          (i) => DateTime(month.year, month.month, i + 1),
        );

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'
            ].map(
              (e) => Expanded(
                child: Center(
                  child: Text(
                    e,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ).toList(),
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
            itemBuilder: (_, i) {
              final d = cells[i];
              if (d == null) return const SizedBox();

              final a = day(d);
              final selected = a != null && a.status != DayStatus.none;

              return InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () => onDayTap(d),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: selected ? dayFill(a!.status) : Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: selected ? dayBorder(a!.status) : border,
                      width: selected ? 1.6 : 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 17,
                          color: d.weekday == DateTime.sunday
                              ? absentRed
                              : textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (a != null && a.hours > 0)
                        Text(
                          '${fmt(a.hours)}H',
                          style: const TextStyle(
                            color: primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (a != null && a.ot > 0)
                        Text(
                          'OT ${fmt(a.ot)}H',
                          style: const TextStyle(
                            color: otGreen,
                            fontSize: 11,
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
      padding: const EdgeInsets.fromLTRB(24, 25, 24, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${monthName(month)} Summary',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
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
  final Color bg;
  final Color fg;

  const StatChip(this.text, this.bg, this.fg, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: fg,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

class SummaryScreen extends StatelessWidget {
  final DateTime month;
  final Map<String, Attendance> attendance;
  final Settings settings;
  final VoidCallback onPrev, onNext, onEditRates;

  const SummaryScreen({
    super.key,
    required this.month,
    required this.attendance,
    required this.settings,
    required this.onPrev,
    required this.onNext,
    required this.onEditRates,
  });

  @override
  Widget build(BuildContext context) {
    final c = monthCounts(month, attendance);

    final days = c['present']! +
        c['half']! * .5 +
        c['leave']! +
        c['paidLeave']!;

    final daily = settings.mode == 'daily'
        ? settings.dailyWage
        : settings.monthlySalary /
            (settings.workingDays <= 0 ? 26 : settings.workingDays);

    final basic = days * daily;
    final ot = c['ot']! * settings.otRate;
    final total = basic + ot - settings.advance - settings.deduction;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Attendance & Payment Summary',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left, size: 32),
              ),
              Text(monthName(month), style: const TextStyle(fontSize: 18)),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right, size: 32),
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
                        '${c['present']!.toInt()} Days',
                        'Present',
                        primaryLight,
                        primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BigStat(
                        '${c['absent']!.toInt()} Days',
                        'Absent',
                        const Color(0xFFFFEEEE),
                        absentRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BigStat(
                        '${c['half']!.toInt()} Days',
                        'Half Day',
                        const Color(0xFFFFF7D9),
                        halfOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BigStat(
                        '${(c['leave']! + c['holiday']!).toInt()} Days',
                        'Leave / Holiday',
                        const Color(0xFFFFF7CC),
                        const Color(0xFF9A7B00),
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
                        '${fmt(c['hours']!)} H',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoBox(
                        'Overtime (OT) Hours',
                        '${fmt(c['ot']!)} H',
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
              onPressed: onEditRates,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Rates'),
            ),
            child: Column(
              children: [
                PaymentRow(
                  'Monthly Salary Base',
                  money(settings.monthlySalary),
                ),
                Text(
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
                const SizedBox(height: 20),
                PaymentRow('Basic Payment', money(basic), bold: true),
                Text(
                  'Present + Half Day + Paid Leave = ${days.toStringAsFixed(1)} paid days',
                  style: const TextStyle(
                    color: Color(0xFFB0B5BA),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                PaymentRow(
                  'OT Rate',
                  '${money(settings.otRate)} / Hour',
                  bold: true,
                ),
                const SizedBox(height: 12),
                PaymentRow(
                  'OT Amount',
                  '+ ${money(ot)}',
                  green: true,
                  bold: true,
                ),
                Text(
                  '${money(settings.otRate)} × ${fmt(c['ot']!)} H',
                  style: const TextStyle(
                    color: Color(0xFFB0B5BA),
                    fontSize: 13,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expected Total Payment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
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
  final String value, label;
  final Color bg, fg;

  const BigStat(this.value, this.label, this.bg, this.fg, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontSize: 12),
            ),
          ],
        ),
      );
}

class InfoBox extends StatelessWidget {
  final String title, value;
  final bool green;

  const InfoBox(this.title, this.value, {super.key, this.green = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: green ? const Color(0xFFE9FAF0) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: green ? otGreen : textGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class PaymentRow extends StatelessWidget {
  final String label, value;
  final bool green, red, bold;

  const PaymentRow(
    this.label,
    this.value, {
    super.key,
    this.green = false,
    this.red = false,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textGrey,
                fontSize: 16,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
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
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primary, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .7,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
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
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  late DayStatus status;
  late TextEditingController hours, ot, note;
  late bool paidLeave;

  @override
  void initState() {
    super.initState();

    status = widget.initial.status == DayStatus.none
        ? DayStatus.present
        : widget.initial.status;

    hours = TextEditingController(
      text: fmt(
        widget.initial.hours == 0
            ? widget.defaultHours
            : widget.initial.hours,
      ),
    );

    ot = TextEditingController(text: fmt(widget.initial.ot));
    note = TextEditingController(text: widget.initial.note);
    paidLeave = widget.initial.paidLeave;
  }

  @override
  void dispose() {
    hours.dispose();
    ot.dispose();
    note.dispose();
    super.dispose();
  }

  void setHours(double value) {
    hours.text = fmt(value);
  }

  void setOt(double value) {
    ot.text = fmt(value);
  }

  Widget quick(String label, VoidCallback action, Color color) =>
      Padding(
        padding: const EdgeInsets.only(right: 7, top: 7),
        child: OutlinedButton(
          onPressed: action,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withOpacity(.45)),
          ),
          child: Text(label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  onPressed: () => Navigator.pop(context),
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

            const SizedBox(height: 18),

            const Text(
              'SELECT STATUS',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 9),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                StatusButton(
                  'PRESENT',
                  DayStatus.present,
                  status,
                  () => setState(() {
                    status = DayStatus.present;
                    paidLeave = false;
                  }),
                ),

                StatusButton(
                  'HALF DAY',
                  DayStatus.half,
                  status,
                  () => setState(() {
                    status = DayStatus.half;
                    paidLeave = false;
                  }),
                ),

                StatusButton(
                  'ABSENT',
                  DayStatus.absent,
                  status,
                  () => setState(() {
                    status = DayStatus.absent;
                    paidLeave = false;
                  }),
                ),

                StatusButton(
                  'LEAVE',
                  DayStatus.leave,
                  status,
                  () => setState(() {
                    status = DayStatus.leave;
                    paidLeave = false;
                    setHours(8);
                  }),
                ),

                StatusButton(
                  'HOLIDAY',
                  DayStatus.holiday,
                  status,
                  () => setState(() {
                    status = DayStatus.holiday;
                    paidLeave = false;
                  }),
                ),
              ],
            ),

            if (status == DayStatus.absent) ...[
              const SizedBox(height: 12),

              const Text(
                'ABSENT TYPE',
                style: TextStyle(
                  color: textGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),

              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Unpaid Absent'),
                    selected: !paidLeave,
                    onSelected: (_) {
                      setState(() => paidLeave = false);
                    },
                  ),

                  ChoiceChip(
                    label: const Text('Paid Leave'),
                    selected: paidLeave,
                    onSelected: (_) {
                      setState(() {
                        paidLeave = true;
                        setHours(8);
                      });
                    },
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            const Text(
              'NORMAL WORKING HOURS',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            TextField(
              controller: hours,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Hours',
                prefixIcon: Icon(Icons.access_time),
              ),
            ),

            Wrap(
              children: [
                quick('4H', () => setHours(4), halfOrange),
                quick('8H', () => setHours(8), otGreen),
                quick('10H', () => setHours(10), otGreen),
              ],
            ),

            const SizedBox(height: 17),

            const Text(
              'OVERTIME (OT) HOURS',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            TextField(
              controller: ot,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'OT Hours',
                prefixIcon: Icon(Icons.more_time),
              ),
            ),

            Wrap(
              children: [
                quick('0H', () => setOt(0), textGrey),
                quick('4H', () => setOt(4), halfOrange),
                quick('8H', () => setOt(8), otGreen),
              ],
            ),

            const SizedBox(height: 17),

            const Text(
              'NOTE (OPTIONAL)',
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add a note...',
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context, Attendance());
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: absentRed,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: absentRed),
                  ),
                ),

                const Spacer(),

                FilledButton.icon(
                  onPressed: () {
                    final h = double.tryParse(hours.text.trim()) ?? 0;
                    final o = double.tryParse(ot.text.trim()) ?? 0;

                    Navigator.pop(
                      context,
                      Attendance(
                        status: status,
                        hours: h,
                        ot: o,
                        note: note.text.trim(),
                        paidLeave:
                            status == DayStatus.absent && paidLeave,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Save Attendance'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
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
}

class StatusButton extends StatelessWidget {
  final String label;
  final DayStatus value, selected;
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: active ? dayFill(value) : Colors.white,
          border: Border.all(
            color: active ? dayBorder(value) : border,
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? dayText(value) : textDark,
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
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late String mode;

  late TextEditingController
      salary, days, hours, ot, daily, advance, deduction;

  @override
  void initState() {
    super.initState();

    final s = widget.initial;

    mode = s.mode;

    salary = TextEditingController(text: fmt(s.monthlySalary));
    days = TextEditingController(text: fmt(s.workingDays));
    hours = TextEditingController(text: fmt(s.normalHours));
    ot = TextEditingController(text: fmt(s.otRate));
    daily = TextEditingController(text: fmt(s.dailyWage));
    advance = TextEditingController(text: fmt(s.advance));
    deduction = TextEditingController(text: fmt(s.deduction));
  }

  @override
  void dispose() {
    for (final c in [
      salary,
      days,
      hours,
      ot,
      daily,
      advance,
      deduction,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * .92,
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Salary & OT Configuration',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
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
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
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
                ModeButton(
                  'Fixed Days',
                  'fixed',
                  'Monthly / 26 days',
                  mode,
                  () => setState(() => mode = 'fixed'),
                ),

                ModeButton(
                  'Month Days',
                  'month',
                  'Monthly / 30–31 days',
                  mode,
                  () => setState(() => mode = 'month'),
                ),

                ModeButton(
                  'Daily Wage',
                  'daily',
                  'Direct per day',
                  mode,
                  () => setState(() => mode = 'daily'),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (mode != 'daily') ...[
              field('MONTHLY SALARY (₹)', salary, '₹ / Month'),

              if (mode == 'fixed')
                field(
                  'STANDARD WORKING DAYS PER MONTH',
                  days,
                  'Days (default 26)',
                ),
            ],

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
              field('DAILY WAGE (₹)', daily, '₹ / Day'),

            field(
              'OPTIONAL ADVANCE (₹)',
              advance,
              'Advance taken (subtracted from salary)',
            ),

            field(
              'OPTIONAL DEDUCTION (₹)',
              deduction,
              'Other deductions (subtracted from salary)',
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final s = Settings(
                    mode: mode,
                    monthlySalary: numVal(salary),
                    workingDays: numVal(days, 26),
                    normalHours: numVal(hours, 8),
                    otRate: numVal(ot, 0),
                    dailyWage: numVal(daily),
                    advance: numVal(advance),
                    deduction: numVal(deduction),
                  );

                  Navigator.pop(context, s);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(
    String label,
    TextEditingController c,
    String suffix,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: .7,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: c,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: label.contains('₹') ? '₹ ' : null,
                suffixText: suffix,
                filled: true,
                fillColor: const Color(0xFFFCFDFE),
              ),
            ),
          ],
        ),
      );
}

class ModeButton extends StatelessWidget {
  final String title, value, sub, selected;
  final VoidCallback onTap;

  const ModeButton(
    this.title,
    this.value,
    this.sub,
    this.selected,
    this.onTap, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == selected;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? primaryLight : Colors.white,
            border: Border.all(
              color: active ? primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? primary : textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YearScreen extends StatelessWidget {
  final int year;
  final Map<String, Attendance> attendance;
  final Future<void> Function(DateTime) onDayTap;
  final VoidCallback onPrev, onNext;

  const YearScreen({
    super.key,
    required this.year,
    required this.attendance,
    required this.onDayTap,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
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
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left, size: 32),
              ),

              Text(
                '$year',
                style: const TextStyle(fontSize: 21),
              ),

              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right, size: 32),
              ),
            ],
          ),

          const SizedBox(height: 12),

          for (int m = 1; m <= 12; m++) ...[
            _YearMonth(
              year: year,
              month: m,
              attendance: attendance,
              onDayTap: onDayTap,
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _YearMonth extends StatelessWidget {
  final int year, month;
  final Map<String, Attendance> attendance;
  final Future<void> Function(DateTime) onDayTap;

  const _YearMonth({
    required this.year,
    required this.month,
    required this.attendance,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    final start = first.weekday % 7;
    final days = DateTime(year, month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (e) => Expanded(
                    child: Center(
                      child: Text(
                        e,
                        style: const TextStyle(
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
            physics: const NeverScrollableScrollPhysics(),
            itemCount: start + days,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (_, i) {
              if (i < start) return const SizedBox();

              final d = DateTime(year, month, i - start + 1);
              final a = attendance['${d.year}-${d.month}-${d.day}'];

              return InkWell(
                onTap: () => onDayTap(d),
                child: Center(
                  child: Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: a != null &&
                              a.status != DayStatus.none
                          ? FontWeight.w800
                          : FontWeight.w400,
                      color: a == null
                          ? (d.weekday == 7 ? absentRed : textDark)
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
