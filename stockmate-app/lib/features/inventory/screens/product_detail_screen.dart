import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/inventory_provider.dart';
import '../../../core/constants/app_colors.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inv = ref.watch(inventoryProvider);
    final product = inv.products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isLow = product.isLowStock;
    final statusColor = isLow ? AppColors.warning : AppColors.teal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Düzenle',
            onPressed: () => context.push('/boss/products/${product.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Sil',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text(
                    'Ürünü Sil',
                    style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  content: Text(
                    '${product.name} envanterden kalıcı olarak silinecek. Emin misiniz?',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Vazgeç', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await ref.read(inventoryProvider.notifier).deleteProduct(product.id);
                context.pop();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero Overview Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLow ? AppColors.warningBorder : AppColors.border,
                width: isLow ? 1.5 : 1.0,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isLow ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLow ? AppColors.warningTint : AppColors.tealTint,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLow ? AppColors.warningBorder : AppColors.teal.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isLow ? 'Kritik Stok Uyarısı' : 'Stok Seviyesi Yeterli',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (product.categoryTr != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.categoryTr!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Divider(color: AppColors.borderLight, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoBlock(
                      label: 'Mevcut Stok',
                      value: '${product.quantity} ${product.unit}',
                      valueColor: statusColor,
                    ),
                    Container(width: 1, height: 36, color: AppColors.borderLight),
                    _InfoBlock(
                      label: 'Birim Fiyat',
                      value: '${product.price.toStringAsFixed(2)} ₺',
                      valueColor: AppColors.navy,
                    ),
                    Container(width: 1, height: 36, color: AppColors.borderLight),
                    _InfoBlock(
                      label: 'Min. Eşik',
                      value: '${product.minStock} ${product.unit}',
                      valueColor: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Metadata Details Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ürün Detayları',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                if (product.barcode != null)
                  _DetailItem(label: 'Barkod / Barcode', value: product.barcode!, icon: Icons.qr_code_2_rounded),
                if (product.serialKey != null)
                  _DetailItem(label: 'Seri Numarası', value: product.serialKey!, icon: Icons.tag_rounded),
                if (product.description != null && product.description!.isNotEmpty)
                  _DetailItem(label: 'Açıklama', value: product.description!, icon: Icons.description_outlined),
                _DetailItem(
                  label: 'Kayıt Tarihi',
                  value: product.createdAt.length >= 10 ? product.createdAt.substring(0, 10) : product.createdAt,
                  icon: Icons.calendar_today_outlined,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Operational Actions
          const Text(
            'Hızlı İşlem Gerçekleştir',
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
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_box_rounded, size: 18),
                  label: const Text('Stok Girişi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => context.push('/boss/scanner', extra: 'restock'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                  label: const Text('Satış Yap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => context.push('/boss/scanner', extra: 'sell'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _InfoBlock({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
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
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isLast;

  const _DetailItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
