import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/api_service.dart';
import '../models/technical_service.dart';
import '../providers/technical_service_provider.dart';

class AddEditTechnicalServiceScreen extends ConsumerStatefulWidget {
  final TechnicalService? existing;
  const AddEditTechnicalServiceScreen({super.key, this.existing});

  @override
  ConsumerState<AddEditTechnicalServiceScreen> createState() =>
      _AddEditTechnicalServiceScreenState();
}

class _AddEditTechnicalServiceScreenState
    extends ConsumerState<AddEditTechnicalServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Controllers
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _deviceBrandCtrl = TextEditingController();
  final _deviceModelCtrl = TextEditingController();
  final _serialNoCtrl = TextEditingController();
  final _faultDescCtrl = TextEditingController();
  final _partsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String _deviceType = 'phone';
  String _status = 'waiting';
  int? _technicianId;
  List<dynamic> _employees = [];

  static const _deviceTypes = [
    ('phone',  'Telefon',       Icons.smartphone_rounded),
    ('laptop', 'Laptop',        Icons.laptop_chromebook_rounded),
    ('tablet', 'Tablet',        Icons.tablet_mac_rounded),
    ('tv',     'Televizyon',    Icons.tv_rounded),
    ('other',  'Diğer',         Icons.devices_other_rounded),
  ];

  static const _statuses = [
    ('waiting',     'Bekliyor'),
    ('in_progress', 'İşlemde'),
    ('done',        'Tamamlandı'),
    ('delivered',   'Teslim Edildi'),
    ('cancelled',   'İptal Edildi'),
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    final e = widget.existing;
    if (e != null) {
      _customerNameCtrl.text = e.customerName;
      _customerPhoneCtrl.text = e.customerPhone ?? '';
      _deviceType = e.deviceType;
      _deviceBrandCtrl.text = e.deviceBrand;
      _deviceModelCtrl.text = e.deviceModel ?? '';
      _serialNoCtrl.text = e.serialNo ?? '';
      _faultDescCtrl.text = e.faultDescription;
      _partsCtrl.text = e.partsToReplace ?? '';
      _noteCtrl.text = e.note ?? '';
      _priceCtrl.text = e.price > 0 ? e.price.toString() : '';
      _status = e.status;
      _technicianId = e.technicianId;
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await ApiService.instance.getEmployees();
      if (mounted) setState(() => _employees = data);
    } catch (_) {}
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _deviceBrandCtrl.dispose();
    _deviceModelCtrl.dispose();
    _serialNoCtrl.dispose();
    _faultDescCtrl.dispose();
    _partsCtrl.dispose();
    _noteCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'customer_name': _customerNameCtrl.text.trim(),
        'customer_phone': _customerPhoneCtrl.text.trim().isEmpty ? null : _customerPhoneCtrl.text.trim(),
        'device_type': _deviceType,
        'device_brand': _deviceBrandCtrl.text.trim(),
        'device_model': _deviceModelCtrl.text.trim().isEmpty ? null : _deviceModelCtrl.text.trim(),
        'serial_no': _serialNoCtrl.text.trim().isEmpty ? null : _serialNoCtrl.text.trim(),
        'fault_description': _faultDescCtrl.text.trim(),
        'parts_to_replace': _partsCtrl.text.trim().isEmpty ? null : _partsCtrl.text.trim(),
        'technician_id': _technicianId,
        'status': _status,
        'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
      };

      if (widget.existing != null) {
        await ApiService.instance.updateTechnicalService(widget.existing!.id, data);
      } else {
        await ApiService.instance.createTechnicalService(data);
      }

      ref.invalidate(technicalServicesProvider);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Servis Kaydını Düzenle' : 'Yeni Teknik Servis Kaydı'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Device Type Selection Section
            _buildSection(
              title: 'Cihaz Türü',
              icon: Icons.devices_rounded,
              children: [
                _buildDeviceTypeSelector(),
              ],
            ),
            const SizedBox(height: 18),

            // Customer Info Section
            _buildSection(
              title: 'Müşteri Bilgileri',
              icon: Icons.person_outline_rounded,
              children: [
                TextFormField(
                  controller: _customerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Müşteri Adı Soyadı *',
                    hintText: 'Örn: Ahmet Yılmaz',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Müşteri adı zorunludur' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'İletişim Numarası',
                    hintText: '05XX XXX XX XX',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Device Info Section
            _buildSection(
              title: 'Cihaz Detayları',
              icon: Icons.build_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _deviceBrandCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Marka *',
                          hintText: 'Apple, Samsung vb.',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Marka zorunludur' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _deviceModelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'iPhone 13, ThinkPad vb.',
                          prefixIcon: Icon(Icons.memory_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _serialNoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Seri Numarası / IMEI',
                    hintText: 'SN-9823412',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Fault & Parts Section
            _buildSection(
              title: 'Arıza & Yedek Parça',
              icon: Icons.warning_amber_rounded,
              children: [
                TextFormField(
                  controller: _faultDescCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bildirilen Arıza / Şikayet *',
                    hintText: 'Cihaz açılmıyor, ekranda kırık var...',
                    prefixIcon: Icon(Icons.error_outline_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Arıza açıklaması zorunludur' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _partsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Değişecek Parçalar',
                    hintText: 'Örn: Batarya, ekran paneli...',
                    prefixIcon: Icon(Icons.build_circle_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Service & Financials Section
            _buildSection(
              title: 'Servis Durumu & Ücretlendirme',
              icon: Icons.settings_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Servis Durumu',
                    prefixIcon: Icon(Icons.published_with_changes_rounded),
                  ),
                  items: _statuses
                      .map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2, style: const TextStyle(color: AppColors.textPrimary))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _status = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _technicianId,
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    labelText: 'Atanan Teknisyen',
                    prefixIcon: Icon(Icons.engineering_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('— Henüz Atanmadı —')),
                    ..._employees.map<DropdownMenuItem<int?>>((e) => DropdownMenuItem<int?>(
                          value: e['id'] as int,
                          child: Text('${e['name']}', style: const TextStyle(color: AppColors.textPrimary)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _technicianId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tahmini / Kesinleşen Servis Ücreti (₺)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Dahili Not',
                    hintText: 'Müşteriye bilgi verildi vb.',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Save CTA Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  isEdit ? 'Servis Kaydını Güncelle' : 'Servis İş Emrini Oluştur',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 24),
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

  Widget _buildDeviceTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _deviceTypes.map(((String v, String label, IconData icon) item) {
        final isSelected = _deviceType == item.$1;
        return GestureDetector(
          onTap: () => setState(() => _deviceType = item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$3, size: 16, color: isSelected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
