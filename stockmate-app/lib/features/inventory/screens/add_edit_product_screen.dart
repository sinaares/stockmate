import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/inventory_provider.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/constants/app_colors.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final int? productId;
  const AddEditProductScreen({super.key, this.productId});
  bool get isEditing => productId != null;

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _priceCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '5');
  final _descCtrl = TextEditingController();
  String _unit = 'adet';
  int? _categoryId;
  List<dynamic> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.isEditing) _loadProduct();
  }

  Future<void> _loadCategories() async {
    final cats = await ApiService.instance.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _loadProduct() async {
    final inv = ref.read(inventoryProvider);
    final product = inv.products.where((p) => p.id == widget.productId).firstOrNull;
    if (product != null) {
      _nameCtrl.text = product.name;
      _barcodeCtrl.text = product.barcode ?? '';
      _serialCtrl.text = product.serialKey ?? '';
      _qtyCtrl.text = '${product.quantity}';
      _priceCtrl.text = '${product.price}';
      _minStockCtrl.text = '${product.minStock}';
      _descCtrl.text = product.description ?? '';
      _unit = product.unit;
      _categoryId = product.categoryId;
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'barcode': _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      'serial_key': _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
      'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      'unit': _unit,
      'min_stock': int.tryParse(_minStockCtrl.text) ?? 5,
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'category_id': _categoryId,
    };

    bool ok;
    if (widget.isEditing) {
      ok = await ref.read(inventoryProvider.notifier).updateProduct(widget.productId!, data);
    } else {
      ok = await ref.read(inventoryProvider.notifier).createProduct(data);
    }

    setState(() => _isLoading = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Ürün başarıyla güncellendi' : 'Yeni ürün başarıyla envantere eklendi'),
          backgroundColor: AppColors.teal,
        ),
      );
      context.pop();
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _BarcodeScanDialog()),
    );
    if (result != null) setState(() => _barcodeCtrl.text = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Ürünü Düzenle' : 'Yeni Ürün Kaydı'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              title: 'Temel Ürün Bilgileri',
              icon: Icons.inventory_2_outlined,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ürün Adı *',
                    hintText: 'Örn: NYA 2.5 mm² Bakır Kablo',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ürün adı zorunludur' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Barkod / EAN / UPC',
                          hintText: '869000000000',
                          prefixIcon: Icon(Icons.qr_code_2_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                      onPressed: _scanBarcode,
                      tooltip: 'Barkod Tara',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _serialCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Seri Numarası / SKU Kodu',
                    hintText: 'SKU-ELK-1024',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Seçimi',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name_tr'], style: const TextStyle(color: AppColors.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ürün Açıklaması / Not',
                    hintText: 'Teknik detaylar, kullanım alanı vb.',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Stok & Fiyatlandırma',
              icon: Icons.price_change_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Başlangıç Stok',
                          prefixIcon: Icon(Icons.format_list_numbered_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _unit,
                        dropdownColor: Colors.white,
                        decoration: const InputDecoration(labelText: 'Birim'),
                        items: ['adet', 'metre', 'kg', 'litre', 'kutu', 'paket', 'rulo', 'set']
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u, style: const TextStyle(color: AppColors.textPrimary)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Birim Satış Fiyatı (₺)',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kritik Stok Uyarısı',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        widget.isEditing ? 'Değişiklikleri Kaydet' : 'Ürünü Envantere Ekle',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }
}

class _BarcodeScanDialog extends StatefulWidget {
  @override
  State<_BarcodeScanDialog> createState() => _BarcodeScanDialogState();
}

class _BarcodeScanDialogState extends State<_BarcodeScanDialog> {
  final ctrl = MobileScannerController();
  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Barkod Tara', style: TextStyle(color: Colors.white)),
        ),
        body: MobileScanner(
          controller: ctrl,
          onDetect: (c) {
            final v = c.barcodes.firstOrNull?.rawValue;
            if (v != null) Navigator.pop(context, v);
          },
        ),
      );
}
