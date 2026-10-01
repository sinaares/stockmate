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
    ('laptop', 'Laptop',        Icons.laptop_rounded),
    ('tablet', 'Tablet',        Icons.tablet_rounded),
    ('tv',     'Televizyon',    Icons.tv_rounded),
    ('other',  'Diğer',         Icons.devices_other_rounded),
  ];

  static const _statuses = [
    ('waiting',     '⏳ Bekliyor'),
    ('in_progress', '🔧 İşlemde'),
    ('done',        '✅ Tamam'),
    ('delivered',   '📦 Teslim'),
    ('cancelled',   '❌ İptal'),
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
      setState(() => _employees = data);
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
      appBar: AppBar(
        title: Text(isEdit ? 'Kaydı Düzenle' : 'Yeni Servis Kaydı'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Kaydet'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Device Type selector
            _buildSectionHeader('📱 Cihaz Türü'),
            const SizedBox(height: 10),
            _buildDeviceTypeSelector(),
            const SizedBox(height: 20),

            // Customer info
            _buildSectionHeader('👤 Müşteri Bilgileri'),
            const SizedBox(height: 10),
            _buildField(_customerNameCtrl, 'Ad Soyad *', Icons.person_outline,
              validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null),
            const SizedBox(height: 12),
            _buildField(_customerPhoneCtrl, 'Telefon', Icons.phone_outlined,
              keyboardType: TextInputType.phone),
            const SizedBox(height: 20),

            // Device info
            _buildSectionHeader('🔧 Cihaz Bilgileri'),
            const SizedBox(height: 10),
            _buildField(_deviceBrandCtrl, 'Marka *', Icons.label_outline,
              validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null),
            const SizedBox(height: 12),
            _buildField(_deviceModelCtrl, 'Model', Icons.memory_outlined),
            const SizedBox(height: 12),
            _buildField(_serialNoCtrl, 'Seri No', Icons.qr_code_outlined),
            const SizedBox(height: 20),

            // Fault & parts
            _buildSectionHeader('⚠️ Arıza & Değişecek Parçalar'),
            const SizedBox(height: 10),
            _buildField(_faultDescCtrl, 'Arıza Açıklaması *', Icons.bug_report_outlined,
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null),
            const SizedBox(height: 12),
            _buildField(_partsCtrl, 'Değişecek Parçalar', Icons.build_circle_outlined,
              maxLines: 3,
              hint: 'Örn: Ekran, batarya, şarj portu...'),
            const SizedBox(height: 20),

            // Service info
            _buildSectionHeader('⚙️ Servis Bilgileri'),
            const SizedBox(height: 10),
            _buildStatusDropdown(),
            const SizedBox(height: 12),
            _buildTechnicianDropdown(),
            const SizedBox(height: 12),
            _buildField(_priceCtrl, 'Ücret (₺)', Icons.payments_outlined,
              keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildField(_noteCtrl, 'Not', Icons.notes_outlined, maxLines: 2),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(isEdit ? 'Güncelle' : 'Kayıt Oluştur',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(
      color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600));
  }

  Widget _buildDeviceTypeSelector() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _deviceTypes.map(((String v, String label, IconData icon) item) {
        final isSelected = _deviceType == item.$1;
        return GestureDetector(
          onTap: () => setState(() => _deviceType = item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$3, size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(item.$2, style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: InputDecoration(
        labelText: 'Durum',
        prefixIcon: const Icon(Icons.flag_outlined, size: 20),
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownColor: AppColors.surfaceCard,
      items: _statuses.map(((String v, String label) item) =>
        DropdownMenuItem(value: item.$1, child: Text(item.$2))).toList(),
      onChanged: (v) { if (v != null) setState(() => _status = v); },
    );
  }

  Widget _buildTechnicianDropdown() {
    return DropdownButtonFormField<int?>(
      value: _technicianId,
      decoration: InputDecoration(
        labelText: 'Teknisyen',
        prefixIcon: const Icon(Icons.engineering_outlined, size: 20),
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dropdownColor: AppColors.surfaceCard,
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('— Atanmadı —')),
        ..._employees.map<DropdownMenuItem<int?>>((e) =>
          DropdownMenuItem<int?>(
            value: e['id'] as int,
            child: Text('${e['name']}'),
          )),
      ],
      onChanged: (v) => setState(() => _technicianId = v),
    );
  }
}
