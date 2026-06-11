import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'screens/splash_screen.dart';
import 'services/notificacao_local_service.dart';
import 'services/consulta_monitor_service.dart';
import 'theme/paciente_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificacaoLocalService.inicializar();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MindFlowApp());
}

class MindFlowApp extends StatefulWidget {
  const MindFlowApp({super.key});

  @override
  State<MindFlowApp> createState() => _MindFlowAppState();
}

class _MindFlowAppState extends State<MindFlowApp>
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
      ConsultaMonitorService.verificarAgora();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindFlow',
      theme: PcT.theme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
