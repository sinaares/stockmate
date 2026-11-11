import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/api_service.dart';

final categoriesProvider = FutureProvider<List<dynamic>>((ref) => ApiService.instance.getCategories());

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});
  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = ref.watch(inventoryProvider);
    final user = ref.watch(authProvider).user!;
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ürün & Stok Yönetimi'),
        actions: [
          if (user.isBoss)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Barkod Tara',
              onPressed: () => context.push('/boss/scanner'),
            ),
          if (user.isBoss)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Yeni Ürün Ekle',
              onPressed: () => context.push('/boss/products/add'),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ürün adı, barkod veya seri no ara...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(inventoryProvider.notifier).setSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (v) => ref.read(inventoryProvider.notifier).setSearch(v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterPill(
                        label: 'Düşük Stok',
                        icon: Icons.warning_amber_rounded,
                        selected: inv.showLowStock,
                        color: AppColors.warning,
                        onTap: () => ref.read(inventoryProvider.notifier).toggleLowStock(),
                      ),
                      const SizedBox(width: 8),
                      ...cats.when(
                        data: (cs) => cs.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterPill(
                            label: c['name_tr'] ?? '',
                            selected: inv.selectedCategory == c['id'],
                            color: AppColors.primary,
                            onTap: () => ref.read(inventoryProvider.notifier).setCategory(
                              inv.selectedCategory == c['id'] ? null : c['id'],
                            ),
                          ),
                        )).toList(),
                        loading: () => [],
                        error: (_, __) => [],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Count & Status Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${inv.products.length} Ürün Listeleniyor',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (inv.showLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningTint,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.warningBorder),
                    ),
                    child: const Text(
                      'Filtre: Kritik Stok',
                      style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: inv.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : inv.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.textHint, size: 36),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Eşleşen ürün bulunamadı',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Arama filtrenizi temizleyin veya yeni ürün ekleyin.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            if (user.isBoss) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: () => context.push('/boss/products/add'),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Yeni Ürün Ekle'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(inventoryProvider.notifier).load(),
                        color: AppColors.primary,
                        backgroundColor: Colors.white,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: inv.products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _ProductCard(
                            product: inv.products[i],
                            isBoss: user.isBoss,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? color : AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isBoss;

  const _ProductCard({required this.product, required this.isBoss});

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.isLowStock;
    final statusColor = isLowStock ? AppColors.warning : AppColors.teal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/boss/products/${product.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLowStock ? AppColors.warningBorder : AppColors.border,
              width: isLowStock ? 1.2 : 1.0,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              // Product Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.categoryTr != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.categoryTr!,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (product.barcode != null) ...[
                          const Icon(Icons.qr_code_2_rounded, size: 13, color: AppColors.textHint),
                          const SizedBox(width: 2),
                          Text(
                            product.barcode!,
                            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Stock & Pricing
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${product.quantity}',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        product.unit,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isBoss) const SizedBox(width: 8),
              if (isBoss)
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
