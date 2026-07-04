import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portfolio_ai/config/theme.dart';
import 'package:portfolio_ai/presentation/screens/auth_screen.dart';
import 'package:portfolio_ai/presentation/screens/dashboard_screen.dart';
import 'package:portfolio_ai/presentation/screens/onboarding_screen.dart';
import 'package:portfolio_ai/presentation/screens/builder_wizard.dart';
import 'package:portfolio_ai/presentation/screens/preview_screen.dart';
import 'package:portfolio_ai/presentation/screens/analytics_screen.dart';
import 'package:portfolio_ai/presentation/screens/admin_screen.dart';
import 'package:portfolio_ai/presentation/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PortfolioAIApp(),
    ),
  );
}

class PortfolioAIApp extends StatelessWidget {
  const PortfolioAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Portfolio Engineer',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/wizard': (context) => const BuilderWizardScreen(),
        '/preview': (context) => const PreviewScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/admin': (context) => const AdminScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
