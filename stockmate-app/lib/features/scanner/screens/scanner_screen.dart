import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../auth/providers/auth_provider.dart';
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Ürün Bulunamadı / Product Not Found',
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Barkod: $code', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            if (widget.role == 'boss')
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Yeni Ürün Ekle / Add New Product'),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/boss/products/add');
                },
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _scanned = false);
                _scanner.start();
              },
              child: const Text('Tekrar Tara / Scan Again'),
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
        title: const Text('Barkod Tara / Scan Barcode',
          style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? AppColors.pending : Colors.white),
            onPressed: () {
              setState(() => _flashOn = !_flashOn);
              _scanner.toggleTorch();
            },
          ),
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

          // Overlay with transparent targeting window
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Targeting corners
          Center(
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.success, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Bottom: manual entry
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.95), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('veya manuel gir / or enter manually',
                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Barkod veya seri no / Barcode or serial',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _manualSearch(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _manualSearch,
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scanning indicator
          if (_scanned)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.success)),
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
    required this.product, required this.role,
    this.presetAction, required this.onClose});

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
    _selectedAction = widget.presetAction;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.role == 'boss'
            ? 'İşlem tamamlandı / Done!'
            : 'İstek gönderildi, onay bekleniyor / Request sent, awaiting approval'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata / Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qty = widget.product['quantity'] as int;
    final isLow = qty <= (widget.product['min_stock'] as int? ?? 5);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: AppColors.accentGlow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2, color: AppColors.accent, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.product['name'] ?? '',
                      style: Theme.of(context).textTheme.titleLarge, maxLines: 2),
                    Text(widget.product['category_tr'] ?? widget.product['category_en'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLow ? AppColors.errorGlow : AppColors.successGlow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$qty ${widget.product['unit']}',
                  style: TextStyle(
                    color: isLow ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action selection
          Text('İşlem Seç / Select Action', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _ActionChip('sell', 'Sat / Sell', Icons.point_of_sale_rounded, AppColors.sell),
              _ActionChip('use', 'Kullan / Use', Icons.build_rounded, AppColors.use),
              _ActionChip('restock', 'Yenile / Restock', Icons.add_box_rounded, AppColors.restock),
            ],
          ),
          const SizedBox(height: 16),

          // Quantity
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Miktar / Quantity',
                    prefixIcon: Icon(Icons.numbers, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Not / Note (opsiyonel)',
                    prefixIcon: Icon(Icons.note_outlined, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Info for employees
          if (widget.role == 'employee')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningGlow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Bu istek yöneticinizin onayına gönderilecek.\nThis request will be sent for manager approval.',
                      style: TextStyle(color: AppColors.warning, fontSize: 11)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.onClose,
                  child: const Text('İptal / Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading || _selectedAction == null ? null : _submit,
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.role == 'boss'
                      ? 'İşlemi Uygula / Apply'
                      : 'Onay İste / Request Approval'),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: isSelected ? color : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13)),
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
    const scanSize = 240.0;
    final scanRect = Rect.fromCenter(center: center, width: scanSize, height: scanSize);

    // Draw dark overlay with transparent hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
