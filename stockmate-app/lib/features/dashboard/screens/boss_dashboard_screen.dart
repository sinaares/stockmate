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
              width: 34, height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: AppColors.primaryGradient,
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 12)],
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
              child: const Text('StockMate',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ),
          ],
        ),
        actions: [
          stats.when(
            data: (data) => data['pendingRequests'] > 0
              ? Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded),
                      onPressed: () => context.push('/boss/approvals'),
                    ),
                    Positioned(right: 8, top: 8,
                      child: Container(
                        width: 17, height: 17,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.pinkGlow, blurRadius: 8)],
                        ),
                        child: Center(
                          child: Text('${data['pendingRequests']}',
                            style: const TextStyle(fontSize: 9, color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.errorGlow, shape: BoxShape.circle),
                  child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 36)),
                const SizedBox(height: 16),
                Text('Sunucuya bağlanılamadı',
                  style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Bağlantı ayarlarını kontrol edin',
                  style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(dashboardStatsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tekrar Dene')),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) {
            setState(() => _navIndex = i);
            switch (i) {
              case 0: break;
              case 1: context.push('/boss/products'); break;
              case 2: context.push('/boss/approvals'); break;
              case 3: context.push('/boss/technical-service'); break;
              case 4: context.push('/boss/employees'); break;
              case 5: context.push('/boss/settings'); break;
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Panel'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Ürünler'),
            NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt_rounded), label: 'Onaylar'),
            NavigationDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle_rounded), label: 'Servis'),
            NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group_rounded), label: 'Personel'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Ayarlar'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data, String userName) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        // Greeting
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Merhaba, $userName 👋',
                    style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text('Bugünkü genel bakış',
                    style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Stat cards 2x2
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              label: 'Toplam Ürün',
              value: '${data['totalProducts']}',
              icon: Icons.inventory_2_rounded,
              gradientColors: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            ),
            _StatCard(
              label: 'Düşük Stok',
              value: '${data['lowStock']}',
              icon: Icons.warning_amber_rounded,
              gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
            _StatCard(
              label: 'Bekleyen Onay',
              value: '${data['pendingRequests']}',
              icon: Icons.pending_actions_rounded,
              gradientColors: data['pendingRequests'] > 0
                ? const [Color(0xFFEC4899), Color(0xFFBE185D)]
                : const [Color(0xFF34D399), Color(0xFF059669)],
              onTap: () => context.push('/boss/approvals'),
            ),
            _StatCard(
              label: 'Toplam Satış',
              value: '${data['totalSold']}',
              icon: Icons.trending_up_rounded,
              gradientColors: const [Color(0xFF34D399), Color(0xFF059669)],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick actions
        _buildQuickActions(context),
        const SizedBox(height: 24),

        // Chart
        _buildChart(context, data['dailyTransactions'] ?? []),
        const SizedBox(height: 20),

        // Recent activity
        _buildRecentActivity(context, data['recentActivity'] ?? []),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hızlı Erişim', style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(icon: Icons.add_box_rounded, label: 'Ürün Ekle',
              color: AppColors.accent, onTap: () => context.push('/boss/products/add')),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.build_circle_rounded, label: 'Yeni Servis',
              color: AppColors.pink, onTap: () => context.push('/boss/technical-service/add')),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.qr_code_scanner_rounded, label: 'Barkod',
              color: AppColors.success, onTap: () => context.push('/boss/scanner')),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.group_add_rounded, label: 'Personel',
              color: AppColors.warning, onTap: () => context.push('/boss/employees')),
          ],
        ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: AppColors.primaryGradient),
              ),
              const SizedBox(width: 10),
              Text('Haftalık Aktivite',
                style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Row(children: [
                _LegendDot(color: AppColors.accent, label: 'Ekle'),
                const SizedBox(width: 12),
                _LegendDot(color: AppColors.pink, label: 'Satış'),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: addData.isEmpty
              ? Center(child: Text('Henüz veri yok',
                  style: Theme.of(context).textTheme.bodyMedium))
              : LineChart(LineChartData(
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
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
                      spots: addData, isCurved: true, barWidth: 3,
                      color: AppColors.accent,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true,
                        gradient: LinearGradient(
                          colors: [AppColors.accent.withOpacity(0.2), Colors.transparent],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    ),
                    if (sellData.isNotEmpty) LineChartBarData(
                      spots: sellData, isCurved: true, barWidth: 3,
                      color: AppColors.pink,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true,
                        gradient: LinearGradient(
                          colors: [AppColors.pink.withOpacity(0.2), Colors.transparent],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    ),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: AppColors.primaryGradient),
              ),
              const SizedBox(width: 10),
              Text('Son İşlemler', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(children: [
                  const Icon(Icons.history_rounded, color: AppColors.textHint, size: 36),
                  const SizedBox(height: 8),
                  Text('Henüz işlem yok', style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ),
          ...items.map((item) {
            final actionType = item['action_type'] as String;
            final color = _actionColor(actionType);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_actionIcon(actionType), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['product_name'] ?? '',
                          style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${item['user_name']} • ${_actionLabel(actionType)}',
                          style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('×${item['quantity']}',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
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
      case 'sell': return AppColors.pink;
      case 'use': return AppColors.warning;
      case 'restock': case 'add': return AppColors.success;
      case 'remove': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  IconData _actionIcon(String t) {
    switch (t) {
      case 'sell': return Icons.point_of_sale_rounded;
      case 'use': return Icons.build_rounded;
      case 'restock': case 'add': return Icons.add_box_rounded;
      case 'remove': return Icons.remove_circle_rounded;
      default: return Icons.swap_horiz_rounded;
    }
  }

  String _actionLabel(String t) {
    switch (t) {
      case 'sell': return 'Satış';
      case 'use': return 'Kullanım';
      case 'restock': return 'Yenileme';
      case 'add': return 'Ekleme';
      case 'remove': return 'Çıkarma';
      default: return t;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.value, required this.icon,
    required this.gradientColors, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gradientColors[0].withOpacity(0.25)),
          boxShadow: [BoxShadow(color: gradientColors[0].withOpacity(0.08),
            blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(colors: gradientColors),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
            Text(value, style: TextStyle(
              color: gradientColors[0], fontSize: 26,
              fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: color,
                fontSize: 10, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            ],
          ),
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
        Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
