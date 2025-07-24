import 'user_model.dart';

class LoginModel {
  final String? token;
  final UserModel? user;

  LoginModel({required this.token, required this.user});

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      token: json['token'],
      user: json.containsKey('id') ? UserModel.fromJson(json) : null,
    );
  }
}
