import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../models/request_model.dart';
import '../../../core/constants/app_colors.dart';

final myRequestsListProvider = FutureProvider<List<RequestModel>>((ref) async {
  final data = await ApiService.instance.getRequests();
  return data.map((j) => RequestModel.fromJson(j)).toList();
});

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myRequestsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('İşlem İsteklerim'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myRequestsListProvider.future),
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
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.textHint, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz bir istek oluşturmadınız',
                        style: TextStyle(color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Barkod tarayarak yaptığınız işlemler burada listelenir.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reqs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _MyRequestTile(request: reqs[i]),
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

class _MyRequestTile extends StatelessWidget {
  final RequestModel request;
  const _MyRequestTile({required this.request});

  Color get _statusColor {
    if (request.isPending) return AppColors.warning;
    if (request.isApproved) return AppColors.teal;
    return AppColors.error;
  }

  String get _statusLabel {
    if (request.isPending) return 'Onay Bekliyor';
    if (request.isApproved) return 'Onaylandı';
    return 'Reddedildi';
  }

  IconData get _statusIcon {
    if (request.isPending) return Icons.schedule_rounded;
    if (request.isApproved) return Icons.check_circle_rounded;
    return Icons.cancel_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${request.actionType.toUpperCase()} • Miktar: ${request.quantity} ${request.unit}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                if (request.isRejected && request.rejectReason != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Red Nedeni: ${request.rejectReason}',
                    style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
