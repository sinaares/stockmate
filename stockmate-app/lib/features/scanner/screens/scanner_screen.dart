import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../inventory/providers/inventory_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final String role;
  final String? presetAction;

  const ScannerScreen({super.key, required this.role, this.presetAction});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _scanned = false;
  bool _flashOn = false;
  final _manualCtrl = TextEditingController();

  @override
  void dispose() {
    _scanner.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCodeDetected(String code) async {
    if (_scanned) return;
    setState(() => _scanned = true);
    HapticFeedback.heavyImpact();
    await _scanner.stop();

    try {
      final product = await ApiService.instance.getProductByCode(code);
      if (mounted) {
        _showProductFoundSheet(product);
      }
    } catch (_) {
      if (mounted) {
        _showNotFoundSheet(code);
      }
    }
  }

  void _showProductFoundSheet(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductActionSheet(
        product: product,
        role: widget.role,
        presetAction: widget.presetAction,
        onClose: () {
          Navigator.pop(context);
          setState(() => _scanned = false);
          _scanner.start();
        },
      ),
    );
  }

  void _showNotFoundSheet(String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.errorBorder),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ürün Bulunamadı',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Barkod: $code',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            if (widget.role == 'boss') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Yeni Ürün Olarak Ekle'),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/boss/products/add');
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _scanned = false);
                  _scanner.start();
                },
                child: const Text('Tekrar Tara'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _manualSearch() {
    final code = _manualCtrl.text.trim();
    if (code.isNotEmpty) _onCodeDetected(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Barkod & QR Tarayıcı',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _flashOn ? AppColors.warning : Colors.white,
            ),
            tooltip: 'Feneri Aç / Kapat',
            onPressed: () {
              setState(() => _flashOn = !_flashOn);
              _scanner.toggleTorch();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _scanner,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) _onCodeDetected(barcode!.rawValue!);
            },
          ),

          // Transparent Targeting Window
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Modern Viewport Box with Electric Blue Corners
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 2.5),
              ),
            ),
          ),

          // Manual Entry Bottom Bar in Clean White Surface
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manuel Barkod Girişi',
                    style: TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Barkod veya seri no girin...',
                            prefixIcon: Icon(Icons.keyboard_outlined, size: 20),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _manualSearch(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: _manualSearch,
                        icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_scanned)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductActionSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  final String role;
  final String? presetAction;
  final VoidCallback onClose;

  const _ProductActionSheet({
    required this.product,
    required this.role,
    this.presetAction,
    required this.onClose,
  });

  @override
  ConsumerState<_ProductActionSheet> createState() => _ProductActionSheetState();
}

class _ProductActionSheetState extends ConsumerState<_ProductActionSheet> {
  String? _selectedAction;
  final _qtyCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAction = widget.presetAction ?? 'sell';
  }

  void _adjustQty(int delta) {
    final current = int.tryParse(_qtyCtrl.text) ?? 1;
    final next = (current + delta).clamp(1, 9999);
    _qtyCtrl.text = '$next';
    setState(() {});
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyCtrl.text);
    if (_selectedAction == null || qty == null || qty <= 0) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.instance.submitRequest({
        'product_id': widget.product['id'],
        'action_type': _selectedAction,
        'quantity': qty,
        'note': _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      });

      ref.invalidate(inventoryProvider);
      if (mounted) {
        widget.onClose();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.role == 'boss'
                  ? 'Stok hareketi başarıyla işlendi'
                  : 'Onay isteğiniz yöneticiye iletildi',
            ),
            backgroundColor: AppColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qty = widget.product['quantity'] as int;
    final minStock = widget.product['min_stock'] as int? ?? 5;
    final isLow = qty <= minStock;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Info Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isLow ? AppColors.warningTint : AppColors.tealTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isLow ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
                  color: isLow ? AppColors.warning : AppColors.teal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product['name'] ?? '',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product['category_tr'] ?? widget.product['category_en'] ?? 'Genel Kategori',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isLow ? AppColors.warningTint : AppColors.tealTint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLow ? AppColors.warningBorder : AppColors.teal.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$qty ${widget.product['unit']}',
                  style: TextStyle(
                    color: isLow ? AppColors.warning : AppColors.teal,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Type Selection Chips
          const Text(
            'İşlem Türü Seçin',
            style: TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ActionChip('sell', 'Satış Yap', Icons.point_of_sale_rounded, AppColors.error)),
              const SizedBox(width: 8),
              Expanded(child: _ActionChip('use', 'Kullanım', Icons.build_rounded, AppColors.warning)),
              const SizedBox(width: 8),
              Expanded(child: _ActionChip('restock', 'Stok Ekle', Icons.add_box_rounded, AppColors.teal)),
            ],
          ),
          const SizedBox(height: 18),

          // Quantity Stepper & Note
          Row(
            children: [
              // Quantity stepper
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      onPressed: () => _adjustQty(-1),
                    ),
                    SizedBox(
                      width: 44,
                      child: TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      onPressed: () => _adjustQty(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Not (İsteğe bağlı)',
                    hintText: 'Açıklama...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (widget.role == 'employee')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem yöneticinizin onayına iletilecektir.',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),

          // Submit & Cancel
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClose,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                  child: const Text('Vazgeç', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: _isLoading || _selectedAction == null ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.role == 'boss' ? 'İşlemi Onayla' : 'Onaya Gönder',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ActionChip(String action, String label, IconData icon, Color color) {
    final isSelected = _selectedAction == action;
    return GestureDetector(
      onTap: () => setState(() => _selectedAction = action),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);
    final center = Offset(size.width / 2, size.height / 2);
    const scanSize = 250.0;
    final scanRect = Rect.fromCenter(center: center, width: scanSize, height: scanSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
