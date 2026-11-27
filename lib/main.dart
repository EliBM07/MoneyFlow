import 'presentation/screens/expenses/expenses_screen.dart';
import 'package:flutter/material.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.inicializar();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A085),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const ExpensesScreen(),
    );
  }
}
