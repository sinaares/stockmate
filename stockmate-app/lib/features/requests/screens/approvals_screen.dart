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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onaylandı / Approved ✅'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _reject(RequestModel req) async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Reddet / Reject', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Red nedeni / Rejection reason'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Reddet')),
        ],
      ),
    );

    if (reason != null) {
      try {
        await ApiService.instance.rejectRequest(req.id, reason);
        ref.invalidate(pendingRequestsProvider);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reddedildi / Rejected ❌'), backgroundColor: AppColors.warning));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(pendingRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bekleyen Onaylar / Pending Approvals')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(pendingRequestsProvider.future),
        color: AppColors.accent,
        child: requests.when(
          data: (reqs) => reqs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 64),
                    const SizedBox(height: 16),
                    Text('Bekleyen onay yok!\nNo pending approvals!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
                  ],
                ))
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
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({required this.request, required this.onApprove, required this.onReject});

  Color get _actionColor {
    switch (request.actionType) {
      case 'sell': return AppColors.sell;
      case 'use': return AppColors.use;
      case 'restock': case 'add': return AppColors.restock;
      default: return AppColors.textSecondary;
    }
  }

  String get _actionLabel {
    switch (request.actionType) {
      case 'sell': return 'Satış / Sell';
      case 'use': return 'Kullanım / Use';
      case 'restock': return 'Yenileme / Restock';
      case 'add': return 'Ekleme / Add';
      case 'remove': return 'Çıkarma / Remove';
      default: return request.actionType;
    }
  }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _actionColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_actionLabel,
                  style: TextStyle(color: _actionColor, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              const Spacer(),
              const Icon(Icons.access_time, color: AppColors.textHint, size: 14),
              const SizedBox(width: 4),
              Text(request.createdAt.length > 10 ? request.createdAt.substring(0, 10) : request.createdAt,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(request.productName,
            style: Theme.of(context).textTheme.titleMedium, maxLines: 1),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 4),
              Text(request.employeeName,
                style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text('Miktar / Qty: ',
                style: Theme.of(context).textTheme.bodyMedium),
              Text('${request.quantity} ${request.unit}',
                style: TextStyle(color: _actionColor, fontWeight: FontWeight.w700)),
            ],
          ),
          if (request.note != null && request.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Not: ${request.note}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                  label: const Text('Reddet / Reject', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Onayla / Approve'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
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
