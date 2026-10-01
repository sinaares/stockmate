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
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Düzenle'),
                ])),
                const PopupMenuItem(value: 'delete', child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  SizedBox(width: 8), Text('Sil', style: TextStyle(color: AppColors.error)),
                ])),
              ],
              onSelected: (v) async {
                if (v == 'edit') {
                  final ok = await context.push<bool>(
                    '/boss/technical-service/${svc.id}/edit',
                    extra: svc);
                  if (ok == true) ref.invalidate(technicalServiceByIdProvider(serviceId));
                } else if (v == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surfaceCard,
                      title: const Text('Kaydı Sil'),
                      content: Text('${svc.customerName} - ${svc.deviceBrand} kaydı silinecek. Emin misiniz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
        ],
      ),
      body: serviceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (svc) => _buildBody(context, ref, svc),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TechnicalService svc) {
    final statusInfo = _statusInfo(svc.status);
    final deviceIcon = _deviceIcon(svc.deviceType);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.accent.withOpacity(0.2), AppColors.surfaceCard],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(deviceIcon, color: AppColors.accent, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${svc.deviceBrand}${svc.deviceModel != null ? ' ${svc.deviceModel}' : ''}',
                      style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(_deviceTypeLabel(svc.deviceType),
                      style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(statusInfo.label,
                        style: TextStyle(color: statusInfo.color, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick status change
        _buildStatusSwitcher(context, ref, svc),
        const SizedBox(height: 20),

        // Details
        _SectionCard(
          title: '👤 Müşteri Bilgileri',
          children: [
            _InfoRow(label: 'Ad Soyad', value: svc.customerName),
            if (svc.customerPhone != null)
              _InfoRow(label: 'Telefon', value: svc.customerPhone!),
          ],
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: '📱 Cihaz Bilgileri',
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
          title: '🔧 Arıza & Yapılacaklar',
          children: [
            _InfoRow(label: 'Arıza Açıklaması', value: svc.faultDescription, multiline: true),
            if (svc.partsToReplace != null && svc.partsToReplace!.isNotEmpty)
              _InfoRow(label: 'Değişecek Parçalar', value: svc.partsToReplace!, multiline: true),
          ],
        ),
        const SizedBox(height: 12),

        _SectionCard(
          title: '⚙️ Servis Bilgileri',
          children: [
            if (svc.technicianName != null)
              _InfoRow(label: 'Teknisyen', value: svc.technicianName!),
            _InfoRow(label: 'Ücret', value: '${svc.price.toStringAsFixed(2)} ₺'),
            if (svc.note != null && svc.note!.isNotEmpty)
              _InfoRow(label: 'Not', value: svc.note!, multiline: true),
            _InfoRow(label: 'Giriş Tarihi', value: _formatDate(svc.createdAt)),
            _InfoRow(label: 'Güncelleme', value: _formatDate(svc.updatedAt)),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatusSwitcher(BuildContext context, WidgetRef ref, TechnicalService svc) {
    const statuses = [
      ('waiting',     '⏳ Bekliyor',  AppColors.warning),
      ('in_progress', '🔧 İşlemde',   AppColors.accent),
      ('done',        '✅ Tamam',     AppColors.success),
      ('delivered',   '📦 Teslim',    AppColors.restock),
      ('cancelled',   '❌ İptal',     AppColors.error),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Durum Değiştir', style: Theme.of(context).textTheme.titleSmall),
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
                        content: Text('Durum güncellendi: ${item.$2}'),
                        backgroundColor: item.$3,
                        behavior: SnackBarBehavior.floating,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? item.$3 : item.$3.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: item.$3.withOpacity(isSelected ? 1 : 0.4)),
                  ),
                  child: Text(item.$2,
                    style: TextStyle(
                      color: isSelected ? Colors.white : item.$3,
                      fontSize: 12, fontWeight: FontWeight.w600)),
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
      case 'waiting':     return _StatusInfo('⏳ Bekliyor',  AppColors.warning);
      case 'in_progress': return _StatusInfo('🔧 İşlemde',   AppColors.accent);
      case 'done':        return _StatusInfo('✅ Tamam',     AppColors.success);
      case 'delivered':   return _StatusInfo('📦 Teslim',    AppColors.restock);
      case 'cancelled':   return _StatusInfo('❌ İptal',     AppColors.error);
      default:            return _StatusInfo(s,               AppColors.textSecondary);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700)),
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
  const _InfoRow({required this.label, required this.value, this.multiline = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: multiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            )
          : Row(
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Spacer(),
                Flexible(
                  child: Text(value,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.end),
                ),
              ],
            ),
    );
  }
}
