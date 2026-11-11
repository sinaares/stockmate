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

class _EmployeeHomeScreenState extends ConsumerState<EmployeeHomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final requests = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
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
        onRefresh: () => ref.refresh(myRequestsProvider.future),
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Employee Identity Card
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryTint,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'E',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba, ${user.name}',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Saha & Depo Operasyon Paneli',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.tealTint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.teal.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'Aktif',
                      style: TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Barcode Scanner Action Card (Commercial ERP Hero Button)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22142D4E),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x332563EB),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Barkod & QR Tarayıcı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kamera ile ürün barkodu tarayarak anında satış, kullanım veya stok girişi yapın.',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        context.push('/employee/scanner');
                      },
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text(
                        'Kamerayı Başlat',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Operational Action Buttons
            const Text(
              'Hızlı İşlem Seçimi',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _EmployeeActionTile(
                    label: 'Satış Yap',
                    sublabel: 'Barkod tara & düş',
                    icon: Icons.point_of_sale_rounded,
                    color: AppColors.error,
                    onTap: () => context.push('/employee/scanner', extra: 'sell'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EmployeeActionTile(
                    label: 'Kullanım',
                    sublabel: 'İç sarfiyat kaydı',
                    icon: Icons.build_rounded,
                    color: AppColors.warning,
                    onTap: () => context.push('/employee/scanner', extra: 'use'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EmployeeActionTile(
                    label: 'Stok Ekle',
                    sublabel: 'Depoya giriş',
                    icon: Icons.add_box_rounded,
                    color: AppColors.teal,
                    onTap: () => context.push('/employee/scanner', extra: 'restock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Pending Requests Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bekleyen Onay İsteklerim',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/employee/requests'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Tümünü Gör →', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            requests.when(
              data: (reqs) => reqs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.check_circle_outline_rounded, color: AppColors.teal, size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Bekleyen onay isteğiniz yok',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reqs.take(4).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final r = reqs[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.warningTint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.hourglass_empty_rounded, color: AppColors.warning, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['product_name'] ?? 'Ürün',
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
                                      'Miktar: ${r['quantity']} • ${r['action_type']}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warningTint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.warningBorder),
                                ),
                                child: const Text(
                                  'Yönetici Onayı',
                                  style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ],
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
              case 1: context.push('/employee/scanner'); break;
              case 2: context.push('/employee/requests'); break;
              case 3: context.push('/employee/profile'); break;
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_rounded),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Barkod Tara',
            ),
            NavigationDestination(
              icon: Icon(Icons.pending_actions_outlined),
              selectedIcon: Icon(Icons.pending_actions_rounded),
              label: 'İsteklerim',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeActionTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EmployeeActionTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
