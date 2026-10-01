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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Müşteri, marka, model ara...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            })
                        : null,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: List.generate(_tabLabels.length, (i) {
                  final status = _statuses[i];
                  final info = _statusInfo(status);
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status != null)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: info.color, shape: BoxShape.circle)),
                        Text(_tabLabels[i]),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      body: servicesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.errorGlow, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.error, size: 32)),
              const SizedBox(height: 16),
              Text('Bağlantı Hatası',
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('$e', style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(technicalServicesProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tekrar Dene')),
            ],
          ),
        ),
        data: (services) => services.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.accent.withOpacity(0.2),
                            AppColors.pink.withOpacity(0.1)]),
                        shape: BoxShape.circle),
                      child: const Icon(Icons.build_circle_outlined,
                        color: AppColors.accent, size: 36)),
                    const SizedBox(height: 16),
                    Text('Kayıt bulunamadı',
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('Yeni servis kaydı ekle',
                      style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.surfaceCard,
                onRefresh: () async => ref.invalidate(technicalServicesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: services.length,
                  itemBuilder: (context, index) =>
                      _ServiceCard(service: services[index]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await context.push<bool>('/boss/technical-service/add');
          if (ok == true) ref.invalidate(technicalServicesProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Kayıt'),
      ),
    );
  }

  _StatusInfo _statusInfo(String? s) {
    switch (s) {
      case 'waiting':     return _StatusInfo('⏳ Bekliyor', AppColors.warning);
      case 'in_progress': return _StatusInfo('🔧 İşlemde',  AppColors.accent);
      case 'done':        return _StatusInfo('✅ Tamam',    AppColors.success);
      case 'delivered':   return _StatusInfo('📦 Teslim',   AppColors.success);
      case 'cancelled':   return _StatusInfo('❌ İptal',    AppColors.error);
      default:            return _StatusInfo('Tümü',        AppColors.textSecondary);
    }
  }
}

class _ServiceCard extends ConsumerWidget {
  final TechnicalService service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusInfo = _statusInfo(service.status);
    final deviceIcon = _deviceIcon(service.deviceType);
    final deviceColor = _deviceColor(service.deviceType);

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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Device icon with gradient bg
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [deviceColor.withOpacity(0.25), deviceColor.withOpacity(0.1)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Icon(deviceIcon, color: deviceColor, size: 26),
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
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(label: statusInfo.label, color: statusInfo.color),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.person_outline_rounded,
                        size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(service.customerName,
                        style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 12)),
                    ]),
                    const SizedBox(height: 3),
                    Text(service.faultDescription,
                      style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (service.technicianName != null) ...[
                          const Icon(Icons.engineering_rounded,
                            size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(service.technicianName!,
                            style: const TextStyle(color: AppColors.accent,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                        ],
                        const Spacer(),
                        if (service.price > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successGlow,
                              borderRadius: BorderRadius.circular(6)),
                            child: Text('${service.price.toStringAsFixed(0)} ₺',
                              style: const TextStyle(color: AppColors.success,
                                fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(
        color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
