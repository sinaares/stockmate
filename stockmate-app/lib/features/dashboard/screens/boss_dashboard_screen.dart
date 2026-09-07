import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ApiService.instance.getStats();
});

class BossDashboardScreen extends ConsumerStatefulWidget {
  const BossDashboardScreen({super.key});
  @override
  ConsumerState<BossDashboardScreen> createState() => _BossDashboardScreenState();
}

class _BossDashboardScreenState extends ConsumerState<BossDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authProvider).user!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark]),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('StockMate'),
          ],
        ),
        actions: [
          stats.when(
            data: (data) => data['pendingRequests'] > 0
              ? Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => context.push('/boss/approvals'),
                    ),
                    Positioned(
                      right: 8, top: 8,
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.errorGlow, blurRadius: 6)],
                        ),
                        child: Center(
                          child: Text('${data['pendingRequests']}',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/boss/approvals')),
            loading: () => const SizedBox(width: 48),
            error: (_, __) => const SizedBox(width: 48),
          ),
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
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        color: AppColors.accent,
        backgroundColor: AppColors.surfaceCard,
        child: stats.when(
          data: (data) => _buildDashboard(context, data, user.name),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: AppColors.textSecondary, size: 48),
                const SizedBox(height: 16),
                Text('Sunucuya bağlanılamadı\nCannot reach server',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardStatsProvider),
                  child: const Text('Tekrar Dene / Retry')),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 0: break;
            case 1: context.push('/boss/products'); break;
            case 2: context.push('/boss/approvals'); break;
            case 3: context.push('/boss/employees'); break;
            case 4: context.push('/boss/settings'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Panel'),
          NavigationDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: 'Ürünler'),
          NavigationDestination(icon: Icon(Icons.approval_outlined), selectedIcon: Icon(Icons.approval), label: 'Onaylar'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Personel'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data, String userName) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Greeting
        Text('Merhaba, $userName 👋',
          style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Genel Bakış / Overview',
          style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),

        // Stat cards
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              label: 'Toplam Ürün\nTotal Products',
              value: '${data['totalProducts']}',
              icon: Icons.inventory_2_outlined,
              color: AppColors.accent,
            ),
            _StatCard(
              label: 'Düşük Stok\nLow Stock',
              value: '${data['lowStock']}',
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
            ),
            _StatCard(
              label: 'Bekleyen Onay\nPending Approvals',
              value: '${data['pendingRequests']}',
              icon: Icons.pending_actions_outlined,
              color: data['pendingRequests'] > 0 ? AppColors.error : AppColors.success,
              onTap: () => context.push('/boss/approvals'),
            ),
            _StatCard(
              label: 'Toplam Satış\nTotal Sold',
              value: '${data['totalSold']}',
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Chart
        _buildChart(context, data['dailyTransactions'] ?? []),
        const SizedBox(height: 28),

        // Category stats
        _buildCategoryStats(context, data['categoryStats'] ?? []),
        const SizedBox(height: 28),

        // Recent activity
        _buildRecentActivity(context, data['recentActivity'] ?? []),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChart(BuildContext context, List<dynamic> daily) {
    final addData = <FlSpot>[];
    final sellData = <FlSpot>[];
    final days = daily.map((d) => d['day'].toString()).toSet().toList()..sort();

    for (int i = 0; i < days.length && i < 7; i++) {
      final day = days[i];
      final addRow = daily.firstWhere(
        (d) => d['day'] == day && d['action_type'] == 'add', orElse: () => {'total': 0});
      final sellRow = daily.firstWhere(
        (d) => d['day'] == day && d['action_type'] == 'sell', orElse: () => {'total': 0});
      addData.add(FlSpot(i.toDouble(), (addRow['total'] as num).toDouble()));
      sellData.add(FlSpot(i.toDouble(), (sellRow['total'] as num).toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Haftalık Aktivite / Weekly Activity',
            style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              _LegendDot(color: AppColors.accent, label: 'Ekleme/Add'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.error, label: 'Satış/Sell'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: addData.isEmpty
              ? Center(child: Text('Henüz veri yok / No data yet',
                  style: Theme.of(context).textTheme.bodyMedium))
              : LineChart(LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                  ),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: addData,
                      isCurved: true, color: AppColors.accent, barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true, color: AppColors.accentGlow),
                    ),
                    if (sellData.isNotEmpty) LineChartBarData(
                      spots: sellData,
                      isCurved: true, color: AppColors.error, barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true, color: AppColors.errorGlow),
                    ),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(BuildContext context, List<dynamic> cats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kategoriler / Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...cats.take(5).map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: Text(c['name_tr'] ?? '', style: Theme.of(context).textTheme.bodyLarge)),
                Text('${c['count']} ürün', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGlow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${c['total_qty']} adet',
                    style: const TextStyle(color: AppColors.accentLight, fontSize: 12)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Son İşlemler / Recent Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text('Henüz işlem yok / No transactions yet',
              style: Theme.of(context).textTheme.bodyMedium),
          ...items.map((item) {
            final actionType = item['action_type'] as String;
            final color = _actionColor(actionType);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_actionIcon(actionType), color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['product_name'] ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${item['user_name']} • ${_actionLabel(actionType)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('×${item['quantity']}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _actionColor(String t) {
    switch (t) {
      case 'sell': return AppColors.sell;
      case 'use': return AppColors.use;
      case 'restock': case 'add': return AppColors.restock;
      case 'remove': return AppColors.remove;
      default: return AppColors.textSecondary;
    }
  }

  IconData _actionIcon(String t) {
    switch (t) {
      case 'sell': return Icons.point_of_sale_rounded;
      case 'use': return Icons.build_rounded;
      case 'restock': case 'add': return Icons.add_box_rounded;
      case 'remove': return Icons.remove_circle_outline;
      default: return Icons.swap_horiz;
    }
  }

  String _actionLabel(String t) {
    switch (t) {
      case 'sell': return 'Satış / Sold';
      case 'use': return 'Kullanım / Used';
      case 'restock': return 'Yenileme / Restocked';
      case 'add': return 'Ekleme / Added';
      case 'remove': return 'Çıkarma / Removed';
      default: return t;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.value, required this.icon,
    required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
              maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
      ],
    );
  }
}
