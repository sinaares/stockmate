import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/api_service.dart';
import '../models/technical_service.dart';
import '../providers/technical_service_provider.dart';
import 'add_edit_technical_service_screen.dart';

class TechnicalServiceDetailScreen extends ConsumerWidget {
  final int serviceId;
  const TechnicalServiceDetailScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(technicalServiceByIdProvider(serviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servis Detayı'),
        actions: [
          serviceAsync.when(
            data: (svc) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              color: AppColors.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: AppColors.accentLight),
                  const SizedBox(width: 10),
                  const Text('Düzenle'),
                ])),
                PopupMenuItem(value: 'delete', child: Row(children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  const Text('Sil', style: TextStyle(color: AppColors.error)),
                ])),
              ],
              onSelected: (v) async {
                if (v == 'edit') {
                  final ok = await context.push<bool>(
                    '/boss/technical-service/${svc.id}/edit', extra: svc);
                  if (ok == true) ref.invalidate(technicalServiceByIdProvider(serviceId));
                } else if (v == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surfaceCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Kaydı Sil'),
                      content: Text(
                        '${svc.customerName} - ${svc.deviceBrand} kaydı silinecek.\nBu işlem geri alınamaz.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Vazgeç')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sil')),
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
        ],
      ),
      body: serviceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Hata: $e')),
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
        // Header card with gradient
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent.withOpacity(0.15),
                AppColors.pink.withOpacity(0.05), AppColors.surfaceCard],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [deviceColor.withOpacity(0.3), deviceColor.withOpacity(0.1)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Icon(deviceIcon, color: deviceColor, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${svc.deviceBrand}${svc.deviceModel != null ? ' ${svc.deviceModel}' : ''}',
                          style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(_deviceTypeLabel(svc.deviceType),
                          style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 10),
                        _buildStatusBadge(statusInfo),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick status change
        _buildStatusSwitcher(context, ref, svc),
        const SizedBox(height: 16),

        // Customer info
        _SectionCard(
          icon: Icons.person_rounded,
          iconColor: AppColors.pink,
          title: 'Müşteri Bilgileri',
          children: [
            _InfoRow(label: 'Ad Soyad', value: svc.customerName),
            if (svc.customerPhone != null)
              _InfoRow(label: 'Telefon', value: svc.customerPhone!),
          ],
        ),
        const SizedBox(height: 12),

        _SectionCard(
          icon: Icons.devices_rounded,
          iconColor: AppColors.accent,
          title: 'Cihaz Bilgileri',
          children: [
            _InfoRow(label: 'Tür', value: _deviceTypeLabel(svc.deviceType)),
            _InfoRow(label: 'Marka', value: svc.deviceBrand),
            if (svc.deviceModel != null)
              _InfoRow(label: 'Model', value: svc.deviceModel!),
            if (svc.serialNo != null)
              _InfoRow(label: 'Seri No', value: svc.serialNo!),
          ],
        ),
        const SizedBox(height: 12),

        _SectionCard(
          icon: Icons.build_rounded,
          iconColor: AppColors.warning,
          title: 'Arıza & Değişecek Parçalar',
          children: [
            _InfoRow(label: 'Arıza', value: svc.faultDescription, multiline: true),
            if (svc.partsToReplace != null && svc.partsToReplace!.isNotEmpty)
              _InfoRow(label: 'Parçalar', value: svc.partsToReplace!, multiline: true),
          ],
        ),
        const SizedBox(height: 12),

        _SectionCard(
          icon: Icons.settings_rounded,
          iconColor: AppColors.success,
          title: 'Servis Bilgileri',
          children: [
            if (svc.technicianName != null)
              _InfoRow(label: 'Teknisyen', value: svc.technicianName!),
            _InfoRow(label: 'Ücret',
              value: '${svc.price.toStringAsFixed(2)} ₺',
              valueColor: AppColors.success),
            if (svc.note != null && svc.note!.isNotEmpty)
              _InfoRow(label: 'Not', value: svc.note!, multiline: true),
            _InfoRow(label: 'Giriş', value: _formatDate(svc.createdAt)),
            _InfoRow(label: 'Güncelleme', value: _formatDate(svc.updatedAt)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(_StatusInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: info.color.withOpacity(0.3)),
      ),
      child: Text(info.label,
        style: TextStyle(color: info.color,
          fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _buildStatusSwitcher(BuildContext context, WidgetRef ref, TechnicalService svc) {
    const statuses = [
      ('waiting',     '⏳ Bekliyor',  AppColors.warning),
      ('in_progress', '🔧 İşlemde',   AppColors.accent),
      ('done',        '✅ Tamam',     AppColors.success),
      ('delivered',   '📦 Teslim',    AppColors.success),
      ('cancelled',   '❌ İptal',     AppColors.error),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.flag_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('Durum Değiştir',
              style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: statuses.map(((String v, String label, Color c) item) {
              final isSelected = svc.status == item.$1;
              return GestureDetector(
                onTap: isSelected ? null : () async {
                  try {
                    await ApiService.instance.updateTechnicalServiceStatus(svc.id, item.$1);
                    ref.invalidate(technicalServiceByIdProvider(serviceId));
                    ref.invalidate(technicalServicesProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Durum → ${item.$2}'),
                        backgroundColor: item.$3,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: AppColors.error,
                      ));
                    }
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? item.$3 : item.$3.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.$3.withOpacity(isSelected ? 1 : 0.3), width: 1.5),
                    boxShadow: isSelected ? [BoxShadow(
                      color: item.$3.withOpacity(0.3), blurRadius: 10)] : null,
                  ),
                  child: Text(item.$2,
                    style: TextStyle(
                      color: isSelected ? Colors.white : item.$3,
                      fontSize: 12, fontWeight: FontWeight.w700)),
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
    } catch (_) { return dt; }
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'laptop': return Icons.laptop_rounded;
      case 'phone': return Icons.smartphone_rounded;
      case 'tablet': return Icons.tablet_rounded;
      case 'tv': return Icons.tv_rounded;
      default: return Icons.devices_other_rounded;
    }
  }

  Color _deviceColor(String type) {
    switch (type) {
      case 'laptop': return AppColors.accent;
      case 'phone': return AppColors.pink;
      case 'tablet': return AppColors.warning;
      case 'tv': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  String _deviceTypeLabel(String type) {
    switch (type) {
      case 'laptop': return 'Laptop / Bilgisayar';
      case 'phone': return 'Telefon';
      case 'tablet': return 'Tablet';
      case 'tv': return 'Televizyon';
      default: return 'Diğer Elektronik';
    }
  }

  _StatusInfo _statusInfo(String s) {
    switch (s) {
      case 'waiting':     return _StatusInfo('⏳ Bekliyor', AppColors.warning);
      case 'in_progress': return _StatusInfo('🔧 İşlemde',  AppColors.accent);
      case 'done':        return _StatusInfo('✅ Tamam',    AppColors.success);
      case 'delivered':   return _StatusInfo('📦 Teslim',   AppColors.success);
      case 'cancelled':   return _StatusInfo('❌ İptal',    AppColors.error);
      default:            return _StatusInfo(s,              AppColors.textSecondary);
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
  const _SectionCard({required this.icon, required this.iconColor,
    required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 16)),
            const SizedBox(width: 10),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
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
  const _InfoRow({required this.label, required this.value,
    this.multiline = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: multiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 5),
                Text(value, style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 14, height: 1.5)),
              ],
            )
          : Row(
              children: [
                Text(label, style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
                const Spacer(),
                Flexible(
                  child: Text(value,
                    style: TextStyle(
                      color: valueColor ?? AppColors.textPrimary,
                      fontSize: 13, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.end),
                ),
              ],
            ),
    );
  }
}
