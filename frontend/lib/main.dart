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
import 'package:portfolio_ai/presentation/screens/editor_screen.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PortfolioAIApp(),
    ),
  );
}

class PortfolioAIApp extends ConsumerWidget {
  const PortfolioAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AI Portfolio Engineer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
        '/editor': (context) => const EditorScreen(),
      },
    );
  }
}

