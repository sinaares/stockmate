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
      appBar: AppBar(title: const Text('İsteklerim / My Requests')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myRequestsListProvider.future),
        color: AppColors.accent,
        child: requests.when(
          data: (reqs) => reqs.isEmpty
            ? Center(child: Text('Henüz istek yok / No requests yet',
                style: Theme.of(context).textTheme.bodyLarge))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _MyRequestTile(request: reqs[i]),
              ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}

class _MyRequestTile extends StatelessWidget {
  final RequestModel request;
  const _MyRequestTile({required this.request});

  Color get _statusColor {
    if (request.isPending) return AppColors.pending;
    if (request.isApproved) return AppColors.success;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              request.isPending ? Icons.schedule
                : request.isApproved ? Icons.check_circle : Icons.cancel,
              color: _statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.productName, style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${request.actionType} • ×${request.quantity} ${request.unit}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                if (request.isRejected && request.rejectReason != null)
                  Text('Red: ${request.rejectReason}',
                    style: const TextStyle(color: AppColors.error, fontSize: 11)),
              ],
            ),
          ),
          Chip(
            label: Text(
              request.isPending ? 'Bekliyor' : request.isApproved ? 'Onaylandı' : 'Reddedildi',
              style: TextStyle(color: _statusColor, fontSize: 11)),
            side: BorderSide(color: _statusColor.withOpacity(0.4)),
            backgroundColor: _statusColor.withOpacity(0.1),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
