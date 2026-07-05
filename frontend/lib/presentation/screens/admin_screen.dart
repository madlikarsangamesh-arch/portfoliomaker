import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/providers/admin_provider.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(adminProvider.notifier).loadSystemOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final stats = adminState.globalStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Administration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: adminState.isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI stats cards row
                  _buildStatsGrid(stats),
                  const SizedBox(height: 32),

                  // Users and Portfolios lists split
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 900;
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildUsersList(adminState.users)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildPortfoliosList(adminState.portfolios)),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildUsersList(adminState.users),
                            const SizedBox(height: 24),
                            _buildPortfoliosList(adminState.portfolios),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final list = [
      {'title': 'Total Users', 'val': '${stats["total_users"] ?? 0}', 'color': AppTheme.neonCyan, 'icon': Icons.people},
      {'title': 'Portfolios Created', 'val': '${stats["total_portfolios"] ?? 0}', 'color': AppTheme.neonPurple, 'icon': Icons.folder},
      {'title': 'Vercel Deploys', 'val': '${stats["total_deployments"] ?? 0}', 'color': Colors.greenAccent, 'icon': Icons.cloud_done},
      {'title': 'AI Loops Processed', 'val': '${stats["ai_requests_processed"] ?? 0}', 'color': AppTheme.electricPink, 'icon': Icons.loop},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final color = item['color'] as Color;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['title'] as String, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  Icon(item['icon'] as IconData, color: color, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['val'] as String,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersList(List<dynamic> users) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Registered Users', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length,
            separatorBuilder: (c, i) => const Divider(color: AppTheme.glassBorder, height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white70)),
                title: Text(user['full_name'] ?? 'Google User', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(user['email'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.neonPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(user['role'].toUpperCase(), style: const TextStyle(color: AppTheme.neonPurple, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortfoliosList(List<dynamic> portfolios) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Generated Portfolios', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: portfolios.length,
            separatorBuilder: (c, i) => const Divider(color: AppTheme.glassBorder, height: 1),
            itemBuilder: (context, index) {
              final p = portfolios[index];
              final score = p['recruiter_scorecard']?.containsKey('overall_score') == true ? p['recruiter_scorecard']['overall_score'] : 85;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(p['profile']['full_name'] ?? 'User Portfolio', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  p['deployment_url'] ?? 'Not Deployed',
                  style: TextStyle(color: p['deployment_url'] != null ? AppTheme.neonCyan : Colors.white24, fontSize: 11),
                ),
                trailing: Text('Score: $score', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              );
            },
          ),
        ],
      ),
    );
  }
}
