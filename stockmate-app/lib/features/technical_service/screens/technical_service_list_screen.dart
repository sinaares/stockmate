import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/technical_service.dart';
import '../providers/technical_service_provider.dart';

class TechnicalServiceListScreen extends ConsumerStatefulWidget {
  const TechnicalServiceListScreen({super.key});

  @override
  ConsumerState<TechnicalServiceListScreen> createState() =>
      _TechnicalServiceListScreenState();
}

class _TechnicalServiceListScreenState
    extends ConsumerState<TechnicalServiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _search = '';

  static const _statuses = [
    null, 'waiting', 'in_progress', 'done', 'delivered', 'cancelled'
  ];
  static const _tabLabels = [
    'Tümü', 'Bekliyor', 'İşlemde', 'Tamam', 'Teslim', 'İptal'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = _statuses[_tabController.index];
    final filters = <String, String?>{
      'status': currentStatus,
      'search': _search.isEmpty ? null : _search,
    };
    final servicesAsync = ref.watch(technicalServicesProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teknik Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Yeni kayıt ekle',
            onPressed: () async {
              final ok = await context.push<bool>('/boss/technical-service/add');
              if (ok == true) {
                ref.invalidate(technicalServicesProvider);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Müşteri, marka, model ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        })
                    : null,
                filled: true,
                fillColor: AppColors.surfaceCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          // List
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: AppColors.textSecondary, size: 48),
                    const SizedBox(height: 12),
                    Text('Bağlantı hatası\n$e',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(technicalServicesProvider),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
              data: (services) => services.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.build_circle_outlined,
                            color: AppColors.textHint, size: 64),
                          const SizedBox(height: 16),
                          Text('Kayıt bulunamadı',
                            style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.accent,
                      backgroundColor: AppColors.surfaceCard,
                      onRefresh: () async => ref.invalidate(technicalServicesProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: services.length,
                        itemBuilder: (context, index) =>
                            _ServiceCard(service: services[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await context.push<bool>('/boss/technical-service/add');
          if (ok == true) ref.invalidate(technicalServicesProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Kayıt'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final TechnicalService service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusInfo = _statusInfo(service.status);
    final deviceIcon = _deviceIcon(service.deviceType);

    return GestureDetector(
      onTap: () async {
        final changed = await context.push<bool>(
          '/boss/technical-service/${service.id}');
        if (changed == true) ref.invalidate(technicalServicesProvider);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusInfo.color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: statusInfo.color.withOpacity(0.06), blurRadius: 12)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Device icon
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(deviceIcon, color: AppColors.accent, size: 26),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${service.deviceBrand}${service.deviceModel != null ? ' ${service.deviceModel}' : ''}',
                            style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusInfo.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusInfo.label,
                            style: TextStyle(
                              color: statusInfo.color,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('👤 ${service.customerName}',
                      style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(service.faultDescription,
                      style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (service.technicianName != null) ...[
                          const Icon(Icons.engineering, size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(service.technicianName!,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(width: 12),
                        ],
                        const Icon(Icons.calendar_today, size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(_formatDate(service.createdAt),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        const Spacer(),
                        if (service.price > 0)
                          Text('${service.price.toStringAsFixed(0)} ₺',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dt) {
    try {
      final d = DateTime.parse(dt);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
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
