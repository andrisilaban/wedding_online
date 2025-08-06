import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wedding_online/models/api_response.dart';
import 'package:wedding_online/models/event_model.dart';
import 'package:wedding_online/models/invitation_model.dart';
import 'package:wedding_online/models/login_model.dart';

class AuthService {
  static const _key = 'token';
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

  Future<ApiResponse<InvitationModel>> createInvitation(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/invitations',
        // data: data,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- CREATE INVITATION RESPONSE ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => InvitationModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('--- CREATE INVITATION ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal membuat undangan',
        );
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  Future<ApiResponse<List<InvitationModel>>> getInvitations(
    String token,
  ) async {
    try {
      final response = await _dio.get(
        '/invitations',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- GET INVITATIONS ---');
      debugPrint(response.data.toString());

      final dataList = response.data['data'] as List<dynamic>;
      final invitations = dataList
          .map((json) => InvitationModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        status: response.data['status'],
        message: response.data['message'],
        data: invitations,
      );
    } on DioException catch (e) {
      debugPrint('--- GET INVITATION ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat undangan');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  Future<ApiResponse<EventModel>> createEvent({
    required String token,
    required int invitationId,
    required String name,
    required String venueName,
    required String venueAddress,
    required String date,
    required String startTime,
    required String endTime,
    required String description,
    required int orderNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/events',
        data: {
          "invitation_id": invitationId,
          "name": name,
          "venue_name": venueName,
          "venue_address": venueAddress,
          "date": date,
          "start_time": startTime,
          "end_time": endTime,
          "description": description,
          "order_number": orderNumber,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- CREATE EVENT RESPONSE ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => EventModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('--- CREATE EVENT ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal membuat acara');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }
}
