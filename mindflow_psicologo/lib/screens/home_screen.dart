import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/psicologo_theme.dart';
import '../services/consulta_monitor_service.dart';
import 'login_screen.dart';
import 'consultas_screen.dart';
import 'agenda_screen.dart';
import 'perfil_screen.dart';
import 'disponibilidade_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _nome = '';
  int _pendentes = 0;

  @override
  void initState() {
    super.initState();
    _carregarNome();
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

  Future<void> _carregarNome() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _nome = prefs.getString('nome') ?? '');
  }

  void _irParaTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _DashboardTab(
            nome: _nome,
            pendentes: _pendentes,
            onTabChange: _irParaTab,
          ),
          ConsultasScreen(isTab: true),
          AgendaScreen(isTab: true),
          PerfilScreen(isTab: true, onNomeAtualizado: _carregarNome),
        ],
      ),
      bottomNavigationBar: _NavBar(
        index: _tab,
        pendentes: _pendentes,
        onTap: (i) {
          if (i == 1) ConsultaMonitorService.verificarAgora();
          setState(() => _tab = i);
        },
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int index;
  final int pendentes;
  final ValueChanged<int> onTap;

  const _NavBar({
    required this.index,
    required this.pendentes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PT.surface,
        border: Border(top: BorderSide(color: PT.border, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: pendentes > 0
                ? Badge(
                    label: Text('$pendentes'),
                    child: const Icon(Icons.event_note_outlined),
                  )
                : const Icon(Icons.event_note_outlined),
            selectedIcon: pendentes > 0
                ? Badge(
                    label: Text('$pendentes'),
                    child: const Icon(Icons.event_note_rounded),
                  )
                : const Icon(Icons.event_note_rounded),
            label: 'Consultas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final String nome;
  final int pendentes;
  final ValueChanged<int> onTabChange;

  const _DashboardTab({
    required this.nome,
    required this.pendentes,
    required this.onTabChange,
  });

  // Computado uma vez por instância, não em cada build()
  static String get _saudacao {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = nome.split(' ').first;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_saudacao,',
                          style: const TextStyle(
                              color: PT.text2,
                              fontSize: 14,
                              fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nome.isNotEmpty ? 'Dr(a). $firstName' : '...',
                          style: const TextStyle(
                            color: PT.text1,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Avatar(nome: nome),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Card pendentes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _PendentesCard(
                pendentes: pendentes,
                onTap: () => onTabChange(1),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // Acesso rápido
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Acesso rápido',
                style: TextStyle(
                    color: PT.text1,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate.fixed([
                _QuickCard(
                  icon: Icons.pending_actions_rounded,
                  label: 'Solicitações',
                  sub: pendentes > 0
                      ? '$pendentes aguardando'
                      : 'Nenhuma pendente',
                  iconBg: PT.warningLight,
                  iconColor: const Color(0xFFD97706),
                  badge: pendentes,
                  onTap: () => onTabChange(1),
                ),
                _QuickCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Agenda',
                  sub: 'Ver consultas',
                  iconBg: PT.primaryLight,
                  iconColor: PT.primary,
                  onTap: () => onTabChange(2),
                ),
                _QuickCard(
                  icon: Icons.tune_rounded,
                  label: 'Disponibilidade',
                  sub: 'Horários de atendimento',
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: PT.success,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DisponibilidadeScreen()),
                  ),
                ),
                _QuickCard(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  sub: 'Editar informações',
                  iconBg: PT.purpleLight,
                  iconColor: PT.purple,
                  onTap: () => onTabChange(3),
                ),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String nome;
  const _Avatar({required this.nome});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: PT.primaryLight,
        shape: BoxShape.circle,
        border: Border.all(color: PT.primary.withOpacity(0.25), width: 1.5),
      ),
      child: Center(
        child: Text(
          nome.isNotEmpty ? nome[0].toUpperCase() : '?',
          style: const TextStyle(
              color: PT.primary, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
    );
  }
}

class _PendentesCard extends StatelessWidget {
  final int pendentes;
  final VoidCallback onTap;

  const _PendentesCard({required this.pendentes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final temPendente = pendentes > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B4FCC), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PT.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_rounded,
                        color: Colors.white70, size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Solicitações pendentes',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$pendentes',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1),
                ),
                const SizedBox(height: 2),
                Text(
                  temPendente
                      ? 'paciente${pendentes > 1 ? 's aguardam' : ' aguarda'} confirmação'
                      : 'Nenhuma solicitação no momento',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver solicitações',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 13),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            temPendente
                ? Icons.mark_email_unread_rounded
                : Icons.check_circle_outline_rounded,
            size: 68,
            color: Colors.white.withOpacity(0.12),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color iconBg;
  final Color iconColor;
  final int badge;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.iconBg,
    required this.iconColor,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: PT.card,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                          color: PT.error, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                    color: PT.text1,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub,
                style: const TextStyle(color: PT.text2, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
