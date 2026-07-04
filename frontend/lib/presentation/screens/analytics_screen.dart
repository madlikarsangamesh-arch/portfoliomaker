import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/providers/portfolio_provider.dart';
import 'package:portfolio_ai/presentation/providers/analytics_provider.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';
import 'package:portfolio_ai/presentation/widgets/stats_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final portfolio = ref.read(portfolioProvider).activePortfolio;
      if (portfolio != null) {
        ref.read(analyticsProvider.notifier).loadAnalytics(portfolio['id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);
    final summary = analyticsState.summary;

    final countries = Map<String, int>.from(summary['countries'] ?? {});
    final devices = Map<String, int>.from(summary['devices'] ?? {});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: analyticsState.isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Numeric overview
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Visitors',
                          '${summary["visitors"] ?? 0}',
                          Icons.people_outline,
                          AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Page Views',
                          '${summary["views"] ?? 0}',
                          Icons.visibility_outlined,
                          AppTheme.neonPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Resume Downloads',
                          '${summary["resume_downloads"] ?? 0}',
                          Icons.download_done_outlined,
                          AppTheme.electricPink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Charts Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildChartBox('Visitors by Country', AnalyticsSummaryChart(data: countries))),
                            const SizedBox(width: 24),
                            Expanded(child: _buildChartBox('Browsing Devices', AnalyticsSummaryChart(data: devices, isPieChart: true))),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildChartBox('Visitors by Country', AnalyticsSummaryChart(data: countries)),
                            const SizedBox(height: 24),
                            _buildChartBox('Browsing Devices', AnalyticsSummaryChart(data: devices, isPieChart: true)),
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

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 4),
              Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBox(String title, Widget chart) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }
}
