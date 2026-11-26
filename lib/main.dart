
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/login/login_screen.dart';

void main() {
  runApp(const MoneyFlowApp());
}

class MoneyFlowApp extends StatelessWidget {
  const MoneyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoneyFlow',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
