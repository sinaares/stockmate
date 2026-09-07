import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/boss_dashboard_screen.dart';
import '../features/dashboard/screens/employee_home_screen.dart';
import '../features/inventory/screens/product_list_screen.dart';
import '../features/inventory/screens/product_detail_screen.dart';
import '../features/inventory/screens/add_edit_product_screen.dart';
import '../features/scanner/screens/scanner_screen.dart';
import '../features/requests/screens/approvals_screen.dart';
import '../features/requests/screens/my_requests_screen.dart';
import '../features/employees/screens/employees_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = auth.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) {
        return auth.user!.isBoss ? '/boss/dashboard' : '/employee/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // Boss routes
      GoRoute(path: '/boss/dashboard', builder: (_, __) => const BossDashboardScreen()),
      GoRoute(path: '/boss/products', builder: (_, __) => const ProductListScreen()),
      GoRoute(path: '/boss/products/add', builder: (_, __) => const AddEditProductScreen()),
      GoRoute(path: '/boss/products/:id', builder: (c, s) => ProductDetailScreen(productId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/boss/products/:id/edit', builder: (c, s) => AddEditProductScreen(productId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/boss/approvals', builder: (_, __) => const ApprovalsScreen()),
      GoRoute(path: '/boss/employees', builder: (_, __) => const EmployeesScreen()),
      GoRoute(path: '/boss/scanner', builder: (_, __) => const ScannerScreen(role: 'boss')),
      GoRoute(path: '/boss/settings', builder: (_, __) => const SettingsScreen()),

      // Employee routes
      GoRoute(path: '/employee/home', builder: (_, __) => const EmployeeHomeScreen()),
      GoRoute(path: '/employee/scanner', builder: (c, s) => ScannerScreen(role: 'employee', presetAction: s.extra as String?)),
      GoRoute(path: '/employee/requests', builder: (_, __) => const MyRequestsScreen()),
      GoRoute(path: '/employee/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

// Placeholder screens (will be replaced)
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Ayarlar / Settings')),
    body: Center(child: Text('Settings coming soon', style: Theme.of(context).textTheme.bodyLarge)),
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil / Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(radius: 40, backgroundColor: const Color(0xFF4F8EF7),
              child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 32, color: Colors.white))),
            const SizedBox(height: 16),
            Text(user.name, style: Theme.of(context).textTheme.titleLarge),
            Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Chip(label: Text(user.role == 'boss' ? '👑 Boss' : '👷 Çalışan / Employee')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap / Sign Out'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C)),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
