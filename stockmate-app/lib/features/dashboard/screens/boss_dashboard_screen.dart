import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dashboardStatsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authProvider).user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'StockMate',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textSecondary),
            tooltip: 'Barkod Tara',
            onPressed: () => context.push('/boss/scanner'),
          ),
          stats.when(
            data: (data) {
              final pending = (data['pendingRequests'] ?? 0) as int;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      pending > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                      color: pending > 0 ? AppColors.warning : AppColors.textSecondary,
                    ),
                    tooltip: 'Onay İstekleri',
                    onPressed: () => context.push('/boss/approvals'),
                  ),
                  if (pending > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Center(
                          child: Text(
                            '$pending',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const SizedBox(width: 48),
            error: (_, __) => const SizedBox(width: 48),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardStatsProvider.future),
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: stats.when(
          data: (data) => _buildDashboard(context, data, user.name),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) {
            final isAuthError = e.toString().contains('401');
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.errorTint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAuthError ? Icons.lock_clock_rounded : Icons.wifi_off_rounded,
                          color: AppColors.error,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isAuthError ? 'Oturum Süresi Doldu' : 'Sunucuya Bağlanılamadı',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAuthError
                            ? 'Güvenliğiniz için lütfen yeniden oturum açın.'
                            : 'Sunucu bağlantınızı ve ayarlarınızı kontrol edin.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (isAuthError)
                        ElevatedButton.icon(
                          onPressed: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) context.go('/login');
                          },
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: const Text('Yeniden Giriş Yap'),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => ref.refresh(dashboardStatsProvider),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Tekrar Dene'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) context.go('/login');
                              },
                              icon: const Icon(Icons.logout_rounded, size: 18),
                              label: const Text('Çıkış'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Panel',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Ürünler',
            ),
            NavigationDestination(
              icon: Icon(Icons.task_alt_outlined),
              selectedIcon: Icon(Icons.task_alt_rounded),
              label: 'Onaylar',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_circle_outlined),
              selectedIcon: Icon(Icons.build_circle_rounded),
              label: 'Servis',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group_rounded),
              label: 'Personel',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data, String userName) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;
            final isTablet = constraints.maxWidth > 580 && !isDesktop;
            final crossCount = isDesktop ? 4 : (isTablet ? 2 : 2);
            final ratio = isDesktop ? 1.65 : (isTablet ? 1.85 : 1.35);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Manager Greeting & Enterprise Status Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.navy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.navy, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba, $userName',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Envanter, onaylar ve teknik servis genel durumu',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.tealTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.teal.withOpacity(0.2)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: AppColors.teal, size: 7),
                            SizedBox(width: 6),
                            Text(
                              'Sistem Çevrimiçi',
                              style: TextStyle(
                                color: AppColors.teal,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4 Executive KPI Stat Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: ratio,
                  children: [
                    _ExecutiveStatCard(
                      label: 'Toplam Ürün Çeşidi',
                      value: '${data['totalProducts'] ?? 0}',
                      badgeText: '${data['totalStock'] ?? 0} Adet Stok',
                      badgeColor: AppColors.primary,
                      icon: Icons.inventory_2_rounded,
                      accentColor: AppColors.primary,
                      onTap: () => context.push('/boss/products'),
                    ),
                    _ExecutiveStatCard(
                      label: 'Kritik Düşük Stok',
                      value: '${data['lowStock'] ?? 0}',
                      badgeText: (data['lowStock'] ?? 0) > 0 ? 'Acil Sipariş' : 'Stoklar İyi',
                      badgeColor: (data['lowStock'] ?? 0) > 0 ? AppColors.warning : AppColors.teal,
                      icon: Icons.warning_amber_rounded,
                      accentColor: (data['lowStock'] ?? 0) > 0 ? AppColors.warning : AppColors.teal,
                      onTap: () => context.push('/boss/products'),
                    ),
                    _ExecutiveStatCard(
                      label: 'Bekleyen Onay',
                      value: '${data['pendingRequests'] ?? 0}',
                      badgeText: (data['pendingRequests'] ?? 0) > 0 ? 'İncele →' : 'Tümü Onaylı',
                      badgeColor: (data['pendingRequests'] ?? 0) > 0 ? AppColors.error : AppColors.textSecondary,
                      icon: Icons.pending_actions_rounded,
                      accentColor: (data['pendingRequests'] ?? 0) > 0 ? AppColors.error : AppColors.navy,
                      onTap: () => context.push('/boss/approvals'),
                    ),
                    _ExecutiveStatCard(
                      label: '7 Günlük Satış',
                      value: '${data['totalSold'] ?? 0}',
                      badgeText: 'Haftalık Hareket',
                      badgeColor: AppColors.teal,
                      icon: Icons.trending_up_rounded,
                      accentColor: AppColors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Quick Actions Bar
                _buildQuickActions(context),
                const SizedBox(height: 22),

                // Chart & Category Distribution (Side-by-side on desktop)
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildChart(context, data['dailyTransactions'] ?? []),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildCategoryBreakdown(context, data['categoryStats'] ?? []),
                      ),
                    ],
                  ),
                ] else ...[
                  _buildChart(context, data['dailyTransactions'] ?? []),
                  const SizedBox(height: 16),
                  _buildCategoryBreakdown(context, data['categoryStats'] ?? []),
                ],
                const SizedBox(height: 22),

                // Recent Activity Table / List
                _buildRecentActivity(context, data['recentActivity'] ?? []),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Hızlı İşlemler',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Tek Tıkla Erişim',
              style: TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _QuickActionTile(
              icon: Icons.add_box_rounded,
              label: 'Ürün Ekle',
              color: AppColors.primary,
              onTap: () => context.push('/boss/products/add'),
            ),
            const SizedBox(width: 10),
            _QuickActionTile(
              icon: Icons.build_circle_rounded,
              label: 'Yeni Servis',
              color: AppColors.teal,
              onTap: () => context.push('/boss/technical-service/add'),
            ),
            const SizedBox(width: 10),
            _QuickActionTile(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Barkod Tara',
              color: AppColors.navy,
              onTap: () => context.push('/boss/scanner'),
            ),
            const SizedBox(width: 10),
            _QuickActionTile(
              icon: Icons.group_add_rounded,
              label: 'Personel',
              color: AppColors.textSecondary,
              onTap: () => context.push('/boss/employees'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, List<dynamic> categories) {
    final topCats = categories.take(5).toList();
    final maxQty = topCats.fold<num>(1, (max, c) => (c['total_qty'] as num) > max ? (c['total_qty'] as num) : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.tealTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_outline_rounded, color: AppColors.teal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Kategori Dağılımı',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${categories.length} Kategori',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (topCats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Kategori verisi bulunamadı', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...topCats.map((cat) {
              final qty = (cat['total_qty'] as num).toDouble();
              final ratio = maxQty > 0 ? (qty / maxQty).clamp(0.06, 1.0) : 0.06;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat['name_tr'] ?? '',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${cat['count']} ürün • ${cat['total_qty']} adet',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<dynamic> daily) {
    final addData = <FlSpot>[];
    final sellData = <FlSpot>[];
    final days = daily.map((d) => d['day'].toString()).toSet().toList()..sort();

    for (int i = 0; i < days.length && i < 7; i++) {
      final day = days[i];
      final addRow = daily.firstWhere(
        (d) => d['day'] == day && d['action_type'] == 'add',
        orElse: () => {'total': 0},
      );
      final sellRow = daily.firstWhere(
        (d) => d['day'] == day && d['action_type'] == 'sell',
        orElse: () => {'total': 0},
      );
      addData.add(FlSpot(i.toDouble(), (addRow['total'] as num).toDouble()));
      sellData.add(FlSpot(i.toDouble(), (sellRow['total'] as num).toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Haftalık Stok Aktivitesi',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: const [
                  _LegendPill(color: AppColors.primary, label: 'Ekleme'),
                  SizedBox(width: 8),
                  _LegendPill(color: AppColors.error, label: 'Satış'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 180,
            child: addData.isEmpty && sellData.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz haftalık işlem grafiği verisi yok',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.borderLight,
                          strokeWidth: 1,
                        ),
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
                          spots: addData.isEmpty ? [const FlSpot(0, 0)] : addData,
                          isCurved: true,
                          barWidth: 2.5,
                          color: AppColors.primary,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.14),
                                Colors.white.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        if (sellData.isNotEmpty)
                          LineChartBarData(
                            spots: sellData,
                            isCurved: true,
                            barWidth: 2.5,
                            color: AppColors.error,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.error.withOpacity(0.12),
                                  Colors.white.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<dynamic> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.navy, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Son Stok Hareketleri',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Text(
                'Canlı Güncelleme',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: const [
                    Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 36),
                    SizedBox(height: 8),
                    Text('Henüz stok işlem kaydı yok', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.borderLight, height: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                final actionType = item['action_type'] as String;
                final color = _actionColor(actionType);
                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_actionIcon(actionType), color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['product_name'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['user_name']} • ${_actionLabel(actionType)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '×${item['quantity']}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Color _actionColor(String t) {
    switch (t) {
      case 'sell': return AppColors.error;
      case 'use': return AppColors.warning;
      case 'restock': case 'add': return AppColors.teal;
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
      case 'restock': return 'Stok Yenileme';
      case 'add': return 'Yeni Ürün';
      case 'remove': return 'Stoktan Çıkar';
      default: return t;
    }
  }
}

class _ExecutiveStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ExecutiveStatCard({
    required this.label,
    required this.value,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
