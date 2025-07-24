import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wedding_online/models/api_response.dart';
import 'package:wedding_online/models/login_model.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://wedding.playroomzone.pro/api',
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<ApiResponse<LoginModel>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      debugPrint('-----');
      debugPrint(response.data.toString());
      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => LoginModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('-----');
      debugPrint(e.response?.data.toString());
      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Login gagal');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  Future<ApiResponse<void>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      return ApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      return ApiResponse.fromJson(
        e.response?.data ??
            {
              'status': e.response?.statusCode ?? 500,
              'message': e.message ?? 'Terjadi Kesalahan',
            },
      );
    }
  }

  // Future<LoginResponseModel> login(String email, String password) async {
  //   try {
  //     final response = await _dio.post(
  //       '/login',
  //       data: {'email': email, 'password': password},
  //     );
  //     // debugPrint(response.data.toString());
  //     return LoginResponseModel.fromJson(response.data);
  //   } on DioException catch (e) {
  //     debugPrint('-----');
  //     debugPrint(e.response?.data.toString());
  //     if (e.response != null && e.response?.data is Map<String, dynamic>) {
  //       throw Exception(e.response?.data['message'] ?? 'Login gagal');
  //     } else {
  //       throw Exception('Terjadi kesalahan jaringan');
  //     }
  //   }
  // }
}
