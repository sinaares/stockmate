import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

final myRequestsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ApiService.instance.getRequests(status: 'pending');
});

class EmployeeHomeScreen extends ConsumerStatefulWidget {
  const EmployeeHomeScreen({super.key});
  @override
  ConsumerState<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends ConsumerState<EmployeeHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final requests = ref.watch(myRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDark]),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('StockMate'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myRequestsProvider.future),
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceCard,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Merhaba, ${user.name} 👷',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text('Stok işlemi yapmak için tara / Scan to perform stock action',
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 40),

            // Main scan button
            Center(
              child: ScaleTransition(
                scale: _pulseAnim,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/employee/scanner');
                  },
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.success.withOpacity(0.4),
                          blurRadius: 40, spreadRadius: 8),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 60),
                        const SizedBox(height: 8),
                        Text('TARA / SCAN', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white, letterSpacing: 2, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Quick actions
            Text('Hızlı İşlem / Quick Action', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _QuickActionCard(
                  label: 'Sat\nSell',
                  icon: Icons.point_of_sale_rounded,
                  color: AppColors.sell,
                  onTap: () => context.push('/employee/scanner', extra: 'sell'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuickActionCard(
                  label: 'Kullan\nUse',
                  icon: Icons.build_rounded,
                  color: AppColors.use,
                  onTap: () => context.push('/employee/scanner', extra: 'use'),
                )),
                const SizedBox(width: 12),
                Expanded(child: _QuickActionCard(
                  label: 'Yenile\nRestock',
                  icon: Icons.add_box_rounded,
                  color: AppColors.restock,
                  onTap: () => context.push('/employee/scanner', extra: 'restock'),
                )),
              ],
            ),
            const SizedBox(height: 32),

            // Pending requests
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bekleyen İsteklerim / My Pending Requests',
                  style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/employee/requests'),
                  child: const Text('Tümü / All', style: TextStyle(color: AppColors.accent))),
              ],
            ),
            const SizedBox(height: 12),
            requests.when(
              data: (reqs) => reqs.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(child: Text('Bekleyen istek yok / No pending requests',
                      style: Theme.of(context).textTheme.bodyMedium)))
                : Wrap(
                    spacing: 8, runSpacing: 8,
                    children: reqs.take(5).map((r) => _RequestChip(request: r)).toList(),
                  ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 0: break;
            case 1: context.push('/employee/scanner'); break;
            case 2: context.push('/employee/requests'); break;
            case 3: context.push('/employee/profile'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Tara'),
          NavigationDestination(icon: Icon(Icons.pending_actions_outlined), selectedIcon: Icon(Icons.pending_actions), label: 'İstekler'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 12)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11, height: 1.4, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _RequestChip extends StatelessWidget {
  final Map<String, dynamic> request;
  const _RequestChip({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warningGlow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, color: AppColors.pending, size: 14),
          const SizedBox(width: 4),
          Text('#${request['id']} • ${request['product_name']}',
            style: const TextStyle(color: AppColors.pending, fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
