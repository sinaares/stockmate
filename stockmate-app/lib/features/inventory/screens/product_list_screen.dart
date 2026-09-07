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
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final inv = ref.watch(inventoryProvider);
    final user = ref.watch(authProvider).user!;
    final cats = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler / Products'),
        actions: [
          if (user.isBoss)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push('/boss/scanner'),
            ),
          if (user.isBoss)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => context.push('/boss/products/add'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search + filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ürün, barkod ara / Search product, barcode...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(inventoryProvider.notifier).setSearch('');
                          })
                      : null,
                  ),
                  onChanged: (v) => ref.read(inventoryProvider.notifier).setSearch(v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Düşük Stok / Low Stock',
                        selected: inv.showLowStock,
                        color: AppColors.warning,
                        onTap: () => ref.read(inventoryProvider.notifier).toggleLowStock(),
                      ),
                      const SizedBox(width: 8),
                      ...cats.when(
                        data: (cs) => cs.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: c['name_tr'],
                            selected: inv.selectedCategory == c['id'],
                            color: AppColors.accent,
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

          // Product list
          Expanded(
            child: inv.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : inv.products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, color: AppColors.textSecondary, size: 48),
                        const SizedBox(height: 12),
                        Text('Ürün bulunamadı / No products found',
                          style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ))
                : RefreshIndicator(
                    onRefresh: () => ref.read(inventoryProvider.notifier).load(),
                    color: AppColors.accent,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: inv.products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ProductTile(
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? color : AppColors.textSecondary,
          fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final bool isBoss;

  const _ProductTile({required this.product, required this.isBoss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/boss/products/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: product.isLowStock ? AppColors.warning.withOpacity(0.5) : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: product.isLowStock ? AppColors.warningGlow : AppColors.accentGlow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                product.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                color: product.isLowStock ? AppColors.warning : AppColors.accent,
                size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (product.categoryTr != null)
                        Text(product.categoryTr!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                      if (product.barcode != null) ...[
                        const Text(' • ', style: TextStyle(color: AppColors.textHint)),
                        const Icon(Icons.qr_code, size: 12, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(product.barcode!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${product.quantity}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: product.isLowStock ? AppColors.warning : AppColors.textPrimary,
                    fontWeight: FontWeight.w700)),
                Text(product.unit,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
              ],
            ),
            if (isBoss) const SizedBox(width: 8),
            if (isBoss)
              const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
