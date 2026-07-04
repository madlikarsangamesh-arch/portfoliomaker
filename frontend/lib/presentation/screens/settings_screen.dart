import 'package:flutter/material.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuration',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Light Mode'),
                      subtitle: const Text('Toggle light background themes'),
                      trailing: Switch(value: false, onChanged: (v) {}),
                    ),
                    const Divider(color: AppTheme.glassBorder),
                    ListTile(
                      title: const Text('Auto Deployment'),
                      subtitle: const Text('Deploy automatically to Vercel on edits'),
                      trailing: Switch(value: true, onChanged: (v) {}),
                    ),
                    const Divider(color: AppTheme.glassBorder),
                    ListTile(
                      title: const Text('LLM Engine selection'),
                      subtitle: const Text('Gemini-1.5-flash (active)'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Account Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
                    const ListTile(
                      title: Text('API Keys Integration'),
                      subtitle: Text('Manage your Gemini & Vercel API credentials'),
                      trailing: Icon(Icons.vpn_key_outlined, color: AppTheme.neonCyan),
                    ),
                    const Divider(color: AppTheme.glassBorder),
                    ListTile(
                      title: const Text('Developer Sandbox Mode'),
                      subtitle: const Text('Logs mock queries locally offline'),
                      trailing: Switch(value: true, onChanged: (v) {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
