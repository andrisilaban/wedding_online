// ignore_for_file: public_member_api_docs, sort_constructors_first

class LoginResponseModel {
  final int? status;
  final String? message;
  final String? token;
  final UserModel? user;

  LoginResponseModel({
    required this.status,
    required this.message,
    required this.token,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> map) {
    return LoginResponseModel(
      status: map['status'] != null ? map['status'] as int : null,
      message: map['message'] != null ? map['message'] as String : null,
      token: map['token'] != null ? map['token'] as String : null,
      user: map['user'] != null
          ? UserModel.fromJson(map['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserModel {
  final String? id;
  final String? email;
  final String? name;
  final bool? isAdmin;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.isAdmin,
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] != null ? map['id'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      isAdmin: map['isAdmin'] != null ? map['isAdmin'] as bool : null,
    );
  }
}
