
import 'package:flutter/material.dart';
import 'worker_pay_logic.dart';
import 'admob_config.dart';

const Color primary = Color(0xFF005086);
const Color primaryLight = Color(0xFFE8F4FB);
const Color bg = Color(0xFFF2F8FD);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Store.initialize();

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
        fontFamily: 'sans',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Worker Pay',
            style: TextStyle(
              fontSize: 30,
              color: primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
