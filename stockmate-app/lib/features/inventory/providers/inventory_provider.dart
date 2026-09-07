import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../../../shared/services/api_service.dart';

class InventoryState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int? selectedCategory;
  final bool showLowStock;

  const InventoryState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategory,
    this.showLowStock = false,
  });

  InventoryState copyWith({
    List<ProductModel>? products, bool? isLoading, String? error,
    String? searchQuery, int? selectedCategory, bool? showLowStock,
  }) => InventoryState(
    products: products ?? this.products, isLoading: isLoading ?? this.isLoading,
    error: error, searchQuery: searchQuery ?? this.searchQuery,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    showLowStock: showLowStock ?? this.showLowStock,
  );
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState()) { load(); }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await ApiService.instance.getProducts(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        categoryId: state.selectedCategory,
        lowStock: state.showLowStock,
      );
      state = state.copyWith(
        products: data.map((j) => ProductModel.fromJson(j)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearch(String q) { state = state.copyWith(searchQuery: q); load(); }
  void setCategory(int? id) { state = state.copyWith(selectedCategory: id); load(); }
  void toggleLowStock() { state = state.copyWith(showLowStock: !state.showLowStock); load(); }

  Future<ProductModel?> lookupByCode(String code) async {
    try {
      final data = await ApiService.instance.getProductByCode(code);
      return ProductModel.fromJson(data);
    } catch (_) { return null; }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    try {
      await ApiService.instance.createProduct(data);
      await load();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      await ApiService.instance.updateProduct(id, data);
      await load();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await ApiService.instance.deleteProduct(id);
      await load();
      return true;
    } catch (e) { return false; }
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) => InventoryNotifier());
