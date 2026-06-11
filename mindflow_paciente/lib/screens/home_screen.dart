import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/paciente_theme.dart';
import '../services/consulta_monitor_service.dart';
import 'login_screen.dart';
import 'psicologos_screen.dart';
import 'minhas_consultas_screen.dart';
import 'perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int    _tab  = 0;
  String _nome = '';

  @override
  void initState() {
    super.initState();
    _carregarNome();
    ConsultaMonitorService.adicionarListener(_onConsultas);
    ConsultaMonitorService.iniciar();
  }

  void _onConsultas(List<Map<String, dynamic>> _) {}

  @override
  void dispose() {
    ConsultaMonitorService.removerListener(_onConsultas);
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
          _DashboardTab(nome: _nome, onTabChange: _irParaTab),
          PsicologosScreen(isTab: true),
          MinhasConsultasScreen(isTab: true),
          PerfilScreen(isTab: true, onNomeAtualizado: _carregarNome),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: PcT.surface,
          border: Border(top: BorderSide(color: PcT.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.search_rounded),
              label: 'Buscar',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Consultas',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Tab ─────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final String nome;
  final ValueChanged<int> onTabChange;

  const _DashboardTab({required this.nome, required this.onTabChange});

  String get _saudacao {
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
                        Text('$_saudacao,',
                            style: const TextStyle(color: PcT.text2, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          nome.isNotEmpty ? firstName : '...',
                          style: const TextStyle(
                            color: PcT.text1,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: PcT.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: PcT.primary.withOpacity(0.25), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: PcT.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Banner wellness
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _WellnessBanner(onBuscar: () => onTabChange(1)),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // Título acesso rápido
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('O que você precisa?',
                  style: TextStyle(
                      color: PcT.text1,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // Grid de ações
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _QuickCard(
                  icon: Icons.search_rounded,
                  label: 'Buscar psicólogo',
                  sub: 'Encontre o profissional ideal',
                  iconBg: PcT.primaryLight,
                  iconColor: PcT.primary,
                  onTap: () => onTabChange(1),
                ),
                _QuickCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Minhas consultas',
                  sub: 'Ver agendamentos',
                  iconBg: PcT.accentLight,
                  iconColor: PcT.accent,
                  onTap: () => onTabChange(2),
                ),
                _QuickCard(
                  icon: Icons.emergency_rounded,
                  label: 'Emergência',
                  sub: 'Atendimento urgente',
                  iconBg: PcT.emergencyLight,
                  iconColor: PcT.emergency,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PsicologosScreen(emergenciaOnly: true),
                    ),
                  ),
                ),
                _QuickCard(
                  icon: Icons.person_rounded,
                  label: 'Meu perfil',
                  sub: 'Editar informações',
                  iconBg: PcT.purpleLight,
                  iconColor: PcT.purple,
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

class _WellnessBanner extends StatelessWidget {
  final VoidCallback onBuscar;
  const _WellnessBanner({required this.onBuscar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PcT.primary.withOpacity(0.3),
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
                const Text(
                  'Cuidar da saúde mental\né um ato de coragem.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onBuscar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Encontrar psicólogo',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
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
          Icon(Icons.self_improvement_rounded,
              size: 68, color: Colors.white.withOpacity(0.15)),
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
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: PcT.card,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                    color: PcT.text1, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub,
                style: const TextStyle(color: PcT.text2, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
