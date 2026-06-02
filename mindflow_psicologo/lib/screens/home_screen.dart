import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'agenda_screen.dart';
import 'consultas_screen.dart';
import 'disponibilidade_screen.dart';
import 'perfil_screen.dart';
import '../services/consulta_monitor_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _nome   = '';
  String _email  = '';
  int    _pendentes = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();

    // Inicia o monitor MOM e registra listener para badge
    ConsultaMonitorService.adicionarListener(_onPendentes);
    ConsultaMonitorService.iniciar();
  }

  void _onPendentes(int total) {
    if (mounted) setState(() => _pendentes = total);
  }

  @override
  void dispose() {
    ConsultaMonitorService.removerListener(_onPendentes);
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nome  = prefs.getString('nome')  ?? '';
      _email = prefs.getString('email') ?? '';
    });
  }

  Future<void> _logout() async {
    ConsultaMonitorService.parar();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _abrirPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilScreen()),
    ).then((_) => _carregarDados());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Olá, Dr(a). ${_nome.split(' ').first} 👋',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Gerencie sua agenda hoje',
                            style:
                                TextStyle(color: AppTheme.textSecond)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _abrirPerfil,
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _nome.isNotEmpty
                              ? _nome[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.secondary),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Card pendentes com badge dinâmico
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF03DAC6), Color(0xFF00897B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Text('Solicitações pendentes',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            if (_pendentes > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_pendentes',
                                  style: const TextStyle(
                                      color: Color(0xFF00897B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            _pendentes == 0
                                ? 'Nenhuma solicitação no momento'
                                : '$_pendentes paciente${_pendentes > 1 ? 's aguardam' : ' aguarda'} sua confirmação',
                            style: const TextStyle(
                                color: Colors.white70,
                                height: 1.5)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ConsultasScreen()),
                            ).then((_) =>
                                ConsultaMonitorService.verificarAgora()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  const Color(0xFF00897B),
                              minimumSize: const Size(140, 42),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            child: const Text('Ver pendentes',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      children: [
                        const Icon(Icons.pending_actions_rounded,
                            size: 80, color: Colors.white24),
                        if (_pendentes > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_pendentes',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text('Acesso rápido',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  // Badge no card de solicitações
                  _ActionCardBadge(
                    icon: Icons.pending_actions_rounded,
                    label: 'Solicitações',
                    color: const Color(0xFF03DAC6),
                    badge: _pendentes,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ConsultasScreen()),
                    ).then((_) =>
                        ConsultaMonitorService.verificarAgora()),
                  ),
                  _ActionCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Minha agenda',
                    color: const Color(0xFF6C63FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AgendaScreen()),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.schedule_rounded,
                    label: 'Disponibilidade',
                    color: const Color(0xFFFFB347),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const DisponibilidadeScreen()),
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Meu perfil',
                    color: const Color(0xFFCF6679),
                    onTap: _abrirPerfil,
                  ),
                ]),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// Card com badge de contagem
class _ActionCardBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badge;
  final VoidCallback? onTap;

  const _ActionCardBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (badge > 0)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ]),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}