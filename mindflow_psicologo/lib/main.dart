import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MindFlowPsicologoApp());
}

class MindFlowPsicologoApp extends StatelessWidget {
  const MindFlowPsicologoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindFlow — Psicólogo',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}