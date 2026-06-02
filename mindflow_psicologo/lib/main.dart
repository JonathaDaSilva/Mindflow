import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'screens/splash_screen.dart';
import 'services/notificacao_local_service.dart';
import 'services/consulta_monitor_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await NotificacaoLocalService.inicializar();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MindFlowPsicologoApp());
}

class MindFlowPsicologoApp extends StatefulWidget {
  const MindFlowPsicologoApp({super.key});

  @override
  State<MindFlowPsicologoApp> createState() =>
      _MindFlowPsicologoAppState();
}

class _MindFlowPsicologoAppState extends State<MindFlowPsicologoApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConsultaMonitorService.parar();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App voltou ao foreground — verifica imediatamente
      ConsultaMonitorService.verificarAgora();
    }
  }

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