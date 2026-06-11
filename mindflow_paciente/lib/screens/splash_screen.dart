import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/paciente_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 16, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    _navegar();
  }

  Future<void> _navegar() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final logado = await AuthService.isLogado();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => logado ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PcT.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: AnimatedBuilder(
            animation: _slide,
            builder: (_, child) =>
                Transform.translate(offset: Offset(0, _slide.value), child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: PcT.primaryLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: PcT.primary.withOpacity(0.15), width: 1),
                  ),
                  child: const Icon(Icons.self_improvement_rounded,
                      size: 44, color: PcT.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'MindFlow',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: PcT.text1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: PcT.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Saúde mental ao seu alcance',
                    style: TextStyle(
                        color: PcT.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: PcT.primary.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
