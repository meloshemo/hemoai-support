import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/analysis/analysis_screen.dart';
import '../screens/hemogram/hemogram_entry_screen.dart';
import '../screens/diet/diet_program_screen.dart';
import '../screens/family/family_panel_screen.dart';
import '../screens/notifications/notification_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/export/export_screen.dart';
import '../screens/analytics/advanced_analytics_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.hasValue && authState.value!.isAuthenticated;
      final isOnSplash = state.uri.path == '/splash';
      final isOnAuth = state.uri.path.startsWith('/auth');
      
      // Show splash while loading
      if (isLoading && !isOnSplash) {
        return '/splash';
      }
      
      // Redirect to auth if not authenticated
      if (!isLoading && !isAuthenticated && !isOnAuth && !isOnSplash) {
        return '/auth/login';
      }
      
      // Redirect to dashboard if authenticated and on auth pages
      if (!isLoading && isAuthenticated && isOnAuth) {
        return '/dashboard';
      }
      
      // Redirect to dashboard if authenticated and on splash
      if (!isLoading && isAuthenticated && isOnSplash) {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      // Splash Route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),
      
      // Main App Routes
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Analysis Routes
      GoRoute(
        path: '/analysis',
        name: 'analysis',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return AnalysisScreen(
            hemogramValues: args?['hemogramValues'] ?? {},
          );
        },
      ),
      
      // Hemogram Entry
      GoRoute(
        path: '/hemogram/entry',
        name: 'hemogramEntry',
        builder: (context, state) => const HemogramEntryScreen(),
      ),
      
      // Diet Program
      GoRoute(
        path: '/diet',
        name: 'dietProgram',
        builder: (context, state) => const DietProgramScreen(),
      ),
      
      // Family Panel
      GoRoute(
        path: '/family',
        name: 'familyPanel',
        builder: (context, state) => const FamilyPanelScreen(),
      ),
      
      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      
      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Export
      GoRoute(
        path: '/export',
        name: 'export',
        builder: (context, state) => const ExportScreen(),
      ),
      
      // Advanced Analytics
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AdvancedAnalyticsScreen(),
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
