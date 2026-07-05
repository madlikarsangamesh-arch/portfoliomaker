import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/providers/auth_provider.dart';
import 'package:portfolio_ai/presentation/providers/portfolio_provider.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final auth = ref.read(authProvider);
      if (auth.userId != null) {
        ref.read(portfolioProvider.notifier).loadUserPortfolios(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final portfolioState = ref.watch(portfolioProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI Portfolio Engineer Studio',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppTheme.neonCyan),
            tooltip: 'Admin Portal',
            onPressed: () => Navigator.pushNamed(context, '/admin'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                _buildWelcomeHeader(authState),
                const SizedBox(height: 32),
                
                // Content Split Layout
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildPortfoliosList(portfolioState)),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _buildTemplatesSidebar()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildPortfoliosList(portfolioState),
                      const SizedBox(height: 24),
                      _buildTemplatesSidebar(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/onboarding'),
        backgroundColor: AppTheme.neonCyan,
        icon: const Icon(Icons.bolt, color: Colors.black),
        label: const Text('Deploy AI Portfolio', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWelcomeHeader(AuthState auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${auth.fullName ?? "Developer"}!',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here is your live analytics deployment and active portfolio status.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfoliosList(PortfolioState state) {
    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan)),
        ),
      );
    }

    if (state.portfolios.isEmpty) {
      return GlassCard(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_open, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              const Text('No portfolios created yet.', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                child: const Text('Build Now'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Portfolios',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.portfolios.length,
          separatorBuilder: (c, i) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final portfolio = state.portfolios[index];
            final scorecard = portfolio['recruiter_scorecard'] ?? {};
            final score = scorecard['overall_score'] ?? 0;
            
            return GlassCard(
              child: ListTile(
                title: Text(
                  portfolio['profile']['professional_title'] ?? 'Developer Portfolio',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        portfolio['deployment_url'] ?? 'Deployment pending',
                        style: TextStyle(color: portfolio['deployment_url'] != null ? AppTheme.neonCyan : Colors.white24),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildScoreBadge(score),
                          const SizedBox(width: 12),
                          const Text('Version: ', style: TextStyle(fontSize: 12)),
                          Text('${portfolio["version"]}', style: const TextStyle(color: AppTheme.neonPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                onTap: () {
                  ref.read(portfolioProvider.notifier).fetchPortfolioDetails(portfolio['id']);
                  Navigator.pushNamed(context, '/preview', arguments: portfolio['id']);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScoreBadge(int score) {
    Color badgeColor = Colors.greenAccent;
    if (score < 50) {
      badgeColor = Colors.redAccent;
    } else if (score < 80) {
      badgeColor = Colors.amberAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: badgeColor, size: 12),
          const SizedBox(width: 4),
          Text(
            'Recruiter Score: $score',
            style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesSidebar() {
    final templates = [
      {'name': 'Developer', 'desc': 'Coding IDE terminal aesthetic', 'icon': Icons.code},
      {'name': 'Minimal', 'desc': 'Ultra clean white grid spacing', 'icon': Icons.space_bar},
      {'name': 'Creative', 'desc': 'Bold colors and bubble cards', 'icon': Icons.brush},
      {'name': 'Glassmorphism', 'desc': 'Backdrop blurs & neon lights', 'icon': Icons.blur_on},
      {'name': 'Cyberpunk', 'desc': 'Glitched elements and dark contrast', 'icon': Icons.flash_on},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premium Presets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: templates.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final t = templates[index];
            return GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(t['icon'] as IconData, color: AppTheme.neonPurple, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(t['desc'] as String, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
