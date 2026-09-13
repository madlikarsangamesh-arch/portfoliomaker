import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:portfolio_maker/config/theme.dart';
import 'package:portfolio_maker/presentation/screens/auth_screen.dart';
import 'package:portfolio_maker/presentation/screens/dashboard_screen.dart';
import 'package:portfolio_maker/presentation/screens/onboarding_screen.dart';
import 'package:portfolio_maker/presentation/screens/builder_wizard.dart';
import 'package:portfolio_maker/presentation/screens/preview_screen.dart';
import 'package:portfolio_maker/presentation/screens/analytics_screen.dart';
import 'package:portfolio_maker/presentation/screens/admin_screen.dart';
import 'package:portfolio_maker/presentation/screens/settings_screen.dart';
import 'package:portfolio_maker/presentation/screens/editor_screen.dart';
import 'package:portfolio_maker/services/appwrite_service.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppwriteService.instance.initialize();
  await AppwriteService.instance.healthCheck();
  runApp(
    const ProviderScope(
      child: PortfolioMakerApp(),
    ),
  );
}

class PortfolioMakerApp extends ConsumerWidget {
  const PortfolioMakerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Portfolio Maker',
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

