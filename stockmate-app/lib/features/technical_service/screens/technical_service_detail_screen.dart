import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/api_service.dart';
import '../models/technical_service.dart';
import '../providers/technical_service_provider.dart';

class TechnicalServiceDetailScreen extends ConsumerWidget {
  final int serviceId;
  const TechnicalServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(technicalServiceByIdProvider(serviceId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teknik Servis Detayı'),
        actions: [
          serviceAsync.when(
            data: (svc) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Düzenle', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Kaydı Sil', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              onSelected: (v) async {
                if (v == 'edit') {
                  final ok = await context.push<bool>(
                    '/boss/technical-service/${svc.id}/edit',
                    extra: svc,
                  );
                  if (ok == true) ref.invalidate(technicalServiceByIdProvider(serviceId));
                } else if (v == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text(
                        'Servis Kaydını Sil',
                        style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                      content: Text(
                        '${svc.customerName} - ${svc.deviceBrand} cihazına ait iş emri kalıcı olarak silinecek. Emin misiniz?',
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
                  if (confirm == true && context.mounted) {
                    await ApiService.instance.deleteTechnicalService(serviceId);
                    if (context.mounted) context.pop(true);
                  }
                }
              },
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: serviceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Hata: $e', style: const TextStyle(color: AppColors.error)),
        ),
        data: (svc) => _buildBody(context, ref, svc),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TechnicalService svc) {
    final statusInfo = _statusInfo(svc.status);
    final deviceIcon = _deviceIcon(svc.deviceType);
    final deviceColor = _deviceColor(svc.deviceType);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // Header Overview Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: deviceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(deviceIcon, color: deviceColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${svc.deviceBrand}${svc.deviceModel != null ? ' ${svc.deviceModel}' : ''}',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _deviceTypeLabel(svc.deviceType),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusInfo.color.withOpacity(0.25)),
                      ),
                      child: Text(
                        statusInfo.label,
                        style: TextStyle(
                          color: statusInfo.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Status Switcher
        _buildStatusSwitcher(context, ref, svc),
        const SizedBox(height: 16),

        // Customer Info Card
        _SectionCard(
          icon: Icons.person_rounded,
          iconColor: AppColors.primary,
          title: 'Müşteri Bilgileri',
          children: [
            _InfoRow(label: 'Müşteri Adı', value: svc.customerName),
            if (svc.customerPhone != null && svc.customerPhone!.isNotEmpty)
              _InfoRow(label: 'Telefon Numarası', value: svc.customerPhone!),
          ],
        ),
        const SizedBox(height: 12),

        // Device Info Card
        _SectionCard(
          icon: Icons.devices_rounded,
          iconColor: AppColors.navy,
          title: 'Cihaz Detayları',
          children: [
            _InfoRow(label: 'Cihaz Türü', value: _deviceTypeLabel(svc.deviceType)),
            _InfoRow(label: 'Marka', value: svc.deviceBrand),
            if (svc.deviceModel != null && svc.deviceModel!.isNotEmpty)
              _InfoRow(label: 'Model', value: svc.deviceModel!),
            if (svc.serialNo != null && svc.serialNo!.isNotEmpty)
              _InfoRow(label: 'Seri Numarası', value: svc.serialNo!),
          ],
        ),
        const SizedBox(height: 12),

        // Fault & Parts Card
        _SectionCard(
          icon: Icons.build_rounded,
          iconColor: AppColors.warning,
          title: 'Arıza & Değişecek Parçalar',
          children: [
            _InfoRow(label: 'Bildirilen Arıza', value: svc.faultDescription, multiline: true),
            if (svc.partsToReplace != null && svc.partsToReplace!.isNotEmpty)
              _InfoRow(label: 'Değişecek / Kullanılan Parçalar', value: svc.partsToReplace!, multiline: true),
          ],
        ),
        const SizedBox(height: 12),

        // Service & Financials Card
        _SectionCard(
          icon: Icons.payments_rounded,
          iconColor: AppColors.teal,
          title: 'Servis Bilgisi & Ücret',
          children: [
            if (svc.technicianName != null)
              _InfoRow(label: 'Atanan Teknisyen', value: svc.technicianName!),
            _InfoRow(
              label: 'Toplam Servis Ücreti',
              value: '${svc.price.toStringAsFixed(2)} ₺',
              valueColor: AppColors.teal,
            ),
            if (svc.note != null && svc.note!.isNotEmpty)
              _InfoRow(label: 'Teknisyen Notu', value: svc.note!, multiline: true),
            _InfoRow(label: 'Kayıt Tarihi', value: _formatDate(svc.createdAt)),
            _InfoRow(label: 'Son Güncelleme', value: _formatDate(svc.updatedAt)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSwitcher(BuildContext context, WidgetRef ref, TechnicalService svc) {
    const statuses = [
      ('waiting',     'Bekliyor',     AppColors.warning),
      ('in_progress', 'İşlemde',      AppColors.primary),
      ('done',        'Tamamlandı',   AppColors.teal),
      ('delivered',   'Teslim Edildi', AppColors.teal),
      ('cancelled',   'İptal Edildi', AppColors.error),
    ];

    return Container(
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
          Row(
            children: const [
              Icon(Icons.published_with_changes_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Durum Güncelle',
                style: TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses.map(((String v, String label, Color c) item) {
              final isSelected = svc.status == item.$1;
              return GestureDetector(
                onTap: isSelected
                    ? null
                    : () async {
                        try {
                          await ApiService.instance.updateTechnicalServiceStatus(svc.id, item.$1);
                          ref.invalidate(technicalServiceByIdProvider(serviceId));
                          ref.invalidate(technicalServicesProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Servis durumu güncellendi: ${item.$2}'),
                                backgroundColor: item.$3,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? item.$3 : item.$3.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.$3.withOpacity(isSelected ? 1.0 : 0.3),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      color: isSelected ? Colors.white : item.$3,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'laptop': return Icons.laptop_chromebook_rounded;
      case 'phone': return Icons.smartphone_rounded;
      case 'tablet': return Icons.tablet_mac_rounded;
      case 'tv': return Icons.tv_rounded;
      default: return Icons.devices_other_rounded;
    }
  }

  Color _deviceColor(String type) {
    switch (type) {
      case 'laptop': return AppColors.navy;
      case 'phone': return AppColors.primary;
      case 'tablet': return AppColors.teal;
      case 'tv': return const Color(0xFF6366F1);
      default: return AppColors.textSecondary;
    }
  }

  String _deviceTypeLabel(String type) {
    switch (type) {
      case 'laptop': return 'Laptop / Masaüstü';
      case 'phone': return 'Akıllı Telefon';
      case 'tablet': return 'Tablet';
      case 'tv': return 'Televizyon / Monitör';
      default: return 'Diğer Elektronik Cihaz';
    }
  }

  _StatusInfo _statusInfo(String s) {
    switch (s) {
      case 'waiting':     return _StatusInfo('Bekliyor', AppColors.warning);
      case 'in_progress': return _StatusInfo('İşlemde',  AppColors.primary);
      case 'done':        return _StatusInfo('Tamamlandı', AppColors.teal);
      case 'delivered':   return _StatusInfo('Teslim Edildi', AppColors.teal);
      case 'cancelled':   return _StatusInfo('İptal Edildi', AppColors.error);
      default:            return _StatusInfo(s, AppColors.textSecondary);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;
  final Color? valueColor;
  const _InfoRow({
    required this.label,
    required this.value,
    this.multiline = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: multiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor ?? AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
    );
  }
}
