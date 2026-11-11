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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Teknik Servis Yönetimi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Müşteri, marka, model veya arıza ara...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              // Filter Tabs
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
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(color: info.color, shape: BoxShape.circle),
                          ),
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
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.errorTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bağlantı Hatası',
                  style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text('$e', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(technicalServicesProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
        data: (services) => services.isEmpty
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
                      child: const Icon(Icons.build_circle_outlined, color: AppColors.textHint, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Teknik servis kaydı bulunamadı',
                      style: TextStyle(color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Seçili filtreye ait cihaz veya iş emri yok.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () async => ref.invalidate(technicalServicesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ServiceCard(service: services[index]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await context.push<bool>('/boss/technical-service/add');
          if (ok == true) ref.invalidate(technicalServicesProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yeni Servis Kaydı', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  _StatusInfo _statusInfo(String? s) {
    switch (s) {
      case 'waiting':     return _StatusInfo('Bekliyor', AppColors.warning);
      case 'in_progress': return _StatusInfo('İşlemde',  AppColors.primary);
      case 'done':        return _StatusInfo('Tamamlandı', AppColors.teal);
      case 'delivered':   return _StatusInfo('Teslim Edildi', AppColors.teal);
      case 'cancelled':   return _StatusInfo('İptal',    AppColors.error);
      default:            return _StatusInfo('Tümü',     AppColors.textSecondary);
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final changed = await context.push<bool>('/boss/technical-service/${service.id}');
          if (changed == true) ref.invalidate(technicalServicesProvider);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: deviceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(deviceIcon, color: deviceColor, size: 24),
              ),
              const SizedBox(width: 14),

              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${service.deviceBrand}${service.deviceModel != null ? ' ${service.deviceModel}' : ''}',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(label: statusInfo.label, color: statusInfo.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          service.customerName,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Arıza: ${service.faultDescription}',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (service.technicianName != null) ...[
                          const Icon(Icons.engineering_outlined, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            service.technicianName!,
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                        const Spacer(),
                        if (service.price > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tealTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${service.price.toStringAsFixed(0)} ₺',
                              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
            ],
          ),
        ),
      ),
    );
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  const _StatusInfo(this.label, this.color);
}
