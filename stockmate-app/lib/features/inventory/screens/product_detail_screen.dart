import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(inventoryProvider);
    final product = inv.products.where((p) => p.id == productId).firstOrNull;

    if (product == null) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator(color: AppColors.accent)));

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/boss/products/${product.id}/edit')),
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surfaceCard,
                  title: const Text('Sil / Delete', style: TextStyle(color: AppColors.textPrimary)),
                  content: Text('${product.name} silinecek. Emin misiniz?\nAre you sure?',
                    style: const TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sil')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await ref.read(inventoryProvider.notifier).deleteProduct(product.id);
                context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: product.isLowStock ? AppColors.warning.withOpacity(0.5) : AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: product.isLowStock ? AppColors.warningGlow : AppColors.accentGlow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                    color: product.isLowStock ? AppColors.warning : AppColors.accent, size: 36),
                ),
                const SizedBox(height: 16),
                Text(product.name, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                if (product.categoryTr != null) ...[
                  const SizedBox(height: 4),
                  Text(product.categoryTr!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoPill(label: 'Stok / Stock', value: '${product.quantity} ${product.unit}',
                      color: product.isLowStock ? AppColors.warning : AppColors.success),
                    _InfoPill(label: 'Fiyat / Price', value: '${product.price.toStringAsFixed(2)} ₺', color: AppColors.accent),
                    _InfoPill(label: 'Min Stok', value: '${product.minStock}', color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.barcode != null) _DetailRow('Barkod / Barcode', product.barcode!, Icons.qr_code),
                if (product.serialKey != null) _DetailRow('Seri No / Serial', product.serialKey!, Icons.tag),
                if (product.description != null && product.description!.isNotEmpty)
                  _DetailRow('Açıklama / Description', product.description!, Icons.description),
                _DetailRow('Eklenme / Created', product.createdAt.substring(0, 10), Icons.calendar_today),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick actions
          Text('Hızlı İşlem / Quick Action', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle / Add'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.restock),
                onPressed: () => context.push('/boss/scanner'),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.point_of_sale, size: 18),
                label: const Text('Sat / Sell'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.sell),
                onPressed: () => context.push('/boss/scanner'),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
      Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10)),
    ],
  );
}

Widget _DetailRow(String label, String value, IconData icon) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        overflow: TextOverflow.ellipsis)),
    ],
  ),
);
