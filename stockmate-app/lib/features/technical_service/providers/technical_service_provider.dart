import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../models/technical_service.dart';

// List provider with optional filters
final technicalServicesProvider = FutureProvider.family<List<TechnicalService>, Map<String, String?>>(
  (ref, filters) async {
    final data = await ApiService.instance.getTechnicalServices(
      status: filters['status'],
      deviceType: filters['device_type'],
      search: filters['search'],
    );
    return data.map((e) => TechnicalService.fromJson(e as Map<String, dynamic>)).toList();
  },
);

// Single service provider
final technicalServiceByIdProvider = FutureProvider.family<TechnicalService, int>((ref, id) async {
  final data = await ApiService.instance.getTechnicalServiceById(id);
  return TechnicalService.fromJson(data);
});

// Stats provider
final technicalServiceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ApiService.instance.getTechnicalServiceStats();
});
