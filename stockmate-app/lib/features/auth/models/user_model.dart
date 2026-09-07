class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // 'boss' or 'employee'

  const UserModel({required this.id, required this.name, required this.email, required this.role});

  bool get isBoss => role == 'boss';
  bool get isEmployee => role == 'employee';

  factory UserModel.fromJson(Map<String, dynamic> j) =>
      UserModel(id: j['id'], name: j['name'], email: j['email'], role: j['role']);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'email': email, 'role': role};
}
