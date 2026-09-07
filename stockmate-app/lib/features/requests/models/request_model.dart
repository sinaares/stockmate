class RequestModel {
  final int id;
  final int employeeId;
  final String employeeName;
  final String employeeEmail;
  final int productId;
  final String productName;
  final String unit;
  final String actionType;
  final int quantity;
  final String? note;
  final String status; // pending, approved, rejected
  final String? rejectReason;
  final String? resolvedByName;
  final String? resolvedAt;
  final String createdAt;

  const RequestModel({
    required this.id, required this.employeeId, required this.employeeName,
    required this.employeeEmail, required this.productId, required this.productName,
    required this.unit, required this.actionType, required this.quantity,
    this.note, required this.status, this.rejectReason, this.resolvedByName,
    this.resolvedAt, required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory RequestModel.fromJson(Map<String, dynamic> j) => RequestModel(
    id: j['id'], employeeId: j['employee_id'], employeeName: j['employee_name'] ?? '',
    employeeEmail: j['employee_email'] ?? '', productId: j['product_id'],
    productName: j['product_name'] ?? '', unit: j['unit'] ?? 'adet',
    actionType: j['action_type'], quantity: j['quantity'],
    note: j['note'], status: j['status'],
    rejectReason: j['reject_reason'], resolvedByName: j['resolved_by_name'],
    resolvedAt: j['resolved_at'], createdAt: j['created_at'] ?? '',
  );
}
