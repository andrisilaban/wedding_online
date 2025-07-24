class UserModel {
  final String? id;
  final String? email;
  final String? name;
  final bool? isAdmin;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    this.id,
    this.email,
    this.name,
    this.isAdmin,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      email: json['email'],
      name: json['name'],
      isAdmin: json['is_admin'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
