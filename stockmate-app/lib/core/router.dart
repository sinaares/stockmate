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
import '../features/settings/settings_screen.dart';
import '../features/technical_service/screens/technical_service_list_screen.dart';
import '../features/technical_service/screens/technical_service_detail_screen.dart';
import '../features/technical_service/screens/add_edit_technical_service_screen.dart';
import '../features/technical_service/models/technical_service.dart';
import 'constants/app_colors.dart';

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
      GoRoute(path: '/boss/technical-service', builder: (_, __) => const TechnicalServiceListScreen()),
      GoRoute(path: '/boss/technical-service/add', builder: (_, __) => const AddEditTechnicalServiceScreen()),
      GoRoute(path: '/boss/technical-service/:id',
        builder: (c, s) => TechnicalServiceDetailScreen(serviceId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/boss/technical-service/:id/edit',
        builder: (c, s) => AddEditTechnicalServiceScreen(existing: s.extra as TechnicalService?)),

      // Employee routes
      GoRoute(path: '/employee/home', builder: (_, __) => const EmployeeHomeScreen()),
      GoRoute(path: '/employee/scanner', builder: (c, s) => ScannerScreen(role: 'employee', presetAction: s.extra as String?)),
      GoRoute(path: '/employee/requests', builder: (_, __) => const MyRequestsScreen()),
      GoRoute(path: '/employee/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil & Hesap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.navy,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.isBoss ? AppColors.primaryTint : AppColors.tealTint,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user.isBoss ? AppColors.primary.withOpacity(0.3) : AppColors.teal.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      user.role == 'boss' ? 'Yönetici / Manager' : 'Saha Operatörü / Employee',
                      style: TextStyle(
                        color: user.isBoss ? AppColors.primary : AppColors.teal,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  'Oturumu Kapat',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.errorBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.errorTint,
                ),
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
