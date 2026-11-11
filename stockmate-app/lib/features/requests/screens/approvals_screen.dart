import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../models/request_model.dart';
import '../../../core/constants/app_colors.dart';

final pendingRequestsProvider = FutureProvider<List<RequestModel>>((ref) async {
  final data = await ApiService.instance.getRequests(status: 'pending');
  return data.map((j) => RequestModel.fromJson(j)).toList();
});

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});
  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  Future<void> _approve(RequestModel req) async {
    try {
      await ApiService.instance.approveRequest(req.id);
      ref.invalidate(pendingRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem başarıyla onaylandı'),
            backgroundColor: AppColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _reject(RequestModel req) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'İsteği Reddet',
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${req.employeeName} tarafından iletilen "${req.productName}" isteği reddedilecek.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Red Gerekçesi (Opsiyonel)',
                hintText: 'Stok yetersiz, hatalı işlem vb.',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await ApiService.instance.rejectRequest(req.id, reason.isEmpty ? 'Yönetici tarafından reddedildi' : reason);
        ref.invalidate(pendingRequestsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İstek reddedildi'), backgroundColor: AppColors.warning),
          );
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(pendingRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Onay İstekleri'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pendingRequestsProvider.future),
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: requests.when(
          data: (reqs) => reqs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.tealTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bekleyen Onay Yok',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Personelden gelen tüm stok işlem istekleri onaylandı.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _RequestCard(
                    request: reqs[i],
                    onApprove: () => _approve(reqs[i]),
                    onReject: () => _reject(reqs[i]),
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Text('$e', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  Color get _actionColor {
    switch (request.actionType) {
      case 'sell': return AppColors.error;
      case 'use': return AppColors.warning;
      case 'restock': case 'add': return AppColors.teal;
      default: return AppColors.primary;
    }
  }

  String get _actionLabel {
    switch (request.actionType) {
      case 'sell': return 'Satış';
      case 'use': return 'Kullanım';
      case 'restock': return 'Stok Yenileme';
      case 'add': return 'Yeni Ekleme';
      case 'remove': return 'Çıkarma';
      default: return request.actionType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _actionColor;

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
          // Header with action type and date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _actionLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
              const Spacer(),
              const Icon(Icons.access_time_rounded, color: AppColors.textHint, size: 14),
              const SizedBox(width: 4),
              Text(
                request.createdAt.length > 10 ? request.createdAt.substring(0, 10) : request.createdAt,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Name
          Text(
            request.productName,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Employee info and quantity
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.surfaceMuted,
                child: Text(
                  request.employeeName.isNotEmpty ? request.employeeName[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 11, color: AppColors.navy, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                request.employeeName,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'Miktar: ',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                '×${request.quantity} ${request.unit}',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),

          if (request.note != null && request.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Not: ${request.note}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                  label: const Text('Reddet', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorBorder),
                    backgroundColor: AppColors.errorTint,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
