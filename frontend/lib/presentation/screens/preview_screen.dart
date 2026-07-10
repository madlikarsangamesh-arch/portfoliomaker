import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:portfolio_ai/config/constants.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/providers/portfolio_provider.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';

class PreviewScreen extends ConsumerWidget {
  const PreviewScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioState = ref.watch(portfolioProvider);
    final scorecard = portfolioState.recruiterScorecard ?? {};
    final score = scorecard['overall_score'] ?? 80;
    final strengths = scorecard['strengths'] as List<dynamic>? ?? [];
    final weaknesses = scorecard['weaknesses'] as List<dynamic>? ?? [];
    final suggestions = scorecard['suggestions'] as List<dynamic>? ?? [];

    final liveUrl = portfolioState.generatedUrl ?? 'https://vercel.app';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your AI Portfolio Live!'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.neonCyan),
            onPressed: () => Navigator.pushNamed(context, '/analytics'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success Card
            _buildSuccessCard(context, liveUrl),
            const SizedBox(height: 24),

            // Main layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildScorecardReport(context, score, strengths, weaknesses, suggestions)),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildSharingCard(context, liveUrl)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildScorecardReport(context, score, strengths, weaknesses, suggestions),
                      const SizedBox(height: 24),
                      _buildSharingCard(context, liveUrl),
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

  Widget _buildSuccessCard(BuildContext context, String url) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.celebration, color: AppTheme.neonCyan, size: 48),
          const SizedBox(height: 16),
          Text(
            'Deployment Successful!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.neonCyan),
          ),
          const SizedBox(height: 8),
          SelectableText(
            url,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _launchUrl(url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Website'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Dashboard'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardReport(
    BuildContext context,
    int score,
    List<dynamic> strengths,
    List<dynamic> weaknesses,
    List<dynamic> suggestions,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recruiter Scorecard',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neonCyan),
                ),
                child: Text(
                  '$score / 100',
                  style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Strengths:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          const SizedBox(height: 8),
          ...strengths.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s.toString(), style: const TextStyle(color: Colors.white70))),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          const Text('Areas for Improvement:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
          const SizedBox(height: 8),
          ...weaknesses.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amberAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w.toString(), style: const TextStyle(color: Colors.white70))),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          const Text('Recruiter Suggestions:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonPurple)),
          const SizedBox(height: 8),
          ...suggestions.map((su) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppTheme.neonPurple, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(su.toString(), style: const TextStyle(color: Colors.white70))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSharingCard(BuildContext context, String url) {
    return GlassCard(
      child: Column(
        children: [
          const Text('Share Portfolio', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // QR Code rendering using qr_flutter library
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 160.0,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final portId = portfolioState.portfolioId;
              if (portId != null) {
                final downloadUrl = '${AppConstants.baseApiUrl}/portfolios/download-source/$portId';
                launchUrl(Uri.parse(downloadUrl));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No active portfolio ID found to download source code.')),
                );
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Source code'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
          ),
        ],
      ),
    );
  }
}
