class ProductModel {
  final int id;
  final String name;
  final String? barcode;
  final String? serialKey;
  final int? categoryId;
  final String? categoryTr;
  final String? categoryEn;
  final int quantity;
  final String unit;
  final double price;
  final String? description;
  final int minStock;
  final String createdAt;
  final String updatedAt;

  const ProductModel({
    required this.id, required this.name, this.barcode, this.serialKey,
    this.categoryId, this.categoryTr, this.categoryEn, required this.quantity,
    required this.unit, required this.price, this.description, required this.minStock,
    required this.createdAt, required this.updatedAt,
  });

  bool get isLowStock => quantity <= minStock;

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
    id: j['id'], name: j['name'], barcode: j['barcode'], serialKey: j['serial_key'],
    categoryId: j['category_id'], categoryTr: j['category_tr'], categoryEn: j['category_en'],
    quantity: j['quantity'] ?? 0, unit: j['unit'] ?? 'adet',
    price: (j['price'] as num).toDouble(), description: j['description'],
    minStock: j['min_stock'] ?? 5,
    createdAt: j['created_at'] ?? '', updatedAt: j['updated_at'] ?? '',
  );
}
