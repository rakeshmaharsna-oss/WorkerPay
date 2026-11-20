# Worker Pay

Worker Pay is a Flutter application for managing worker attendance, overtime, and salary payments.

## Features

- Monthly Attendance Calendar
- Yearly Attendance Calendar
- Present Attendance
- Half Day Attendance
- Absent Attendance
- Paid Leave
- Unpaid Absent
- Holiday Management
- Daily Working Hours
- Overtime (OT) Tracking
- Custom Overtime Hours
- Attendance Notes
- Salary Calculation
- Daily Wage Calculation
- Monthly Salary Calculation
- Advance Payment Management
- Salary Deduction Management
- Monthly Payment Summary
- Local Data Storage

## Attendance Status

| Status | Description |
|---|---|
| Present | Worker is present |
| Half Day | Worker works half day |
| Absent | Unpaid absence or paid leave |
| Leave | Paid leave entry |
| Holiday | Holiday entry |

## Salary Calculation

Worker Pay supports:

- Monthly Salary
- Daily Wage
- Basic Payment
- Overtime Payment
- Advance Deduction
- Other Deductions
- Net Payment Calculation

## Technologies Used

- Flutter
- Dart
- Shared Preferences
- Google Mobile Ads

## Project Structure

```text
WorkerPay/
│
├── lib/
│   ├── main.dart
│   ├── worker_pay_logic.dart
│   └── admob_config.dart
│
├── README.md
├── icon.png
├── pubspec.yaml
│
└── android/
