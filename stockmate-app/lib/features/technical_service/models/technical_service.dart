class TechnicalService {
  final int id;
  final String customerName;
  final String? customerPhone;
  final String deviceType;
  final String deviceBrand;
  final String? deviceModel;
  final String? serialNo;
  final String faultDescription;
  final String? partsToReplace;
  final int? technicianId;
  final String? technicianName;
  final String status;
  final String? note;
  final double price;
  final String createdAt;
  final String updatedAt;

  const TechnicalService({
    required this.id,
    required this.customerName,
    this.customerPhone,
    required this.deviceType,
    required this.deviceBrand,
    this.deviceModel,
    this.serialNo,
    required this.faultDescription,
    this.partsToReplace,
    this.technicianId,
    this.technicianName,
    required this.status,
    this.note,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TechnicalService.fromJson(Map<String, dynamic> json) {
    return TechnicalService(
      id: json['id'] as int,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      deviceType: json['device_type'] as String,
      deviceBrand: json['device_brand'] as String,
      deviceModel: json['device_model'] as String?,
      serialNo: json['serial_no'] as String?,
      faultDescription: json['fault_description'] as String,
      partsToReplace: json['parts_to_replace'] as String?,
      technicianId: json['technician_id'] as int?,
      technicianName: json['technician_name'] as String?,
      status: json['status'] as String,
      note: json['note'] as String?,
      price: (json['price'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'device_type': deviceType,
    'device_brand': deviceBrand,
    'device_model': deviceModel,
    'serial_no': serialNo,
    'fault_description': faultDescription,
    'parts_to_replace': partsToReplace,
    'technician_id': technicianId,
    'status': status,
    'note': note,
    'price': price,
  };

  TechnicalService copyWith({
    String? status,
    String? technicianName,
    int? technicianId,
    String? partsToReplace,
    String? note,
    double? price,
  }) {
    return TechnicalService(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      deviceType: deviceType,
      deviceBrand: deviceBrand,
      deviceModel: deviceModel,
      serialNo: serialNo,
      faultDescription: faultDescription,
      partsToReplace: partsToReplace ?? this.partsToReplace,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      status: status ?? this.status,
      note: note ?? this.note,
      price: price ?? this.price,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
