import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:wedding_online/models/api_response.dart';
import 'package:wedding_online/models/event_load_model.dart';
import 'package:wedding_online/models/event_model.dart';
import 'package:wedding_online/models/gallery_model.dart';
import 'package:wedding_online/models/invitation_model.dart';
import 'package:wedding_online/models/login_model.dart';
import 'package:wedding_online/models/package_model.dart';
import 'package:wedding_online/models/wish_model.dart';
import 'package:wedding_online/services/storage_service.dart';

class AuthService {
  String defaultInvitationId = '999999999';
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://wedding.playroomzone.pro/api',
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  final StorageService _storageService = StorageService();
  // Add this constant at the top of AuthService class
  static const String _imgBBApiKey = 'eae8e749fc0192f8c363aeecece087c5';
  static const String _imgBBBaseUrl = 'https://api.imgbb.com/1/upload';

  Future<ApiResponse<LoginModel>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      // debugPrint('-----');
      // debugPrint(response.data.toString());
      final Map<String, dynamic> data = response.data;
      final token = data['token'];
      if (token != null) {
        await StorageService().saveToken(token);
      } else {
        throw Exception('Token tidak ditemukan, silakan login ulang');
      }
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

      // Perbaikan: Check if invitations is not empty before accessing last
      if (invitations.isNotEmpty && invitations.last.id != null) {
        _storageService.saveInvitationId(invitations.last.id.toString());
      } else {
        // Save default invitation ID if no invitations found
        _storageService.saveInvitationId(defaultInvitationId);
      }

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

  Future<ApiResponse<InvitationModel>> getInvitationById(
    String token,
    int invitationId,
  ) async {
    try {
      final response = await _dio.get(
        '/invitations/$invitationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- GET INVITATION BY ID ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => InvitationModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('--- GET INVITATION BY ID ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat undangan');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  Future<ApiResponse<InvitationModel>> updateInvitation(
    String token,
    Map<String, dynamic> data,
    String invitationId,
  ) async {
    try {
      final response = await _dio.put(
        '/invitations/$invitationId',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- UPDATE INVITATION RESPONSE ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => InvitationModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('--- UPDATE INVITATION ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal memperbarui undangan',
        );
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  Future<ApiResponse<void>> deleteInvitation(
    String token,
    String invitationId,
  ) async {
    try {
      final response = await _dio.delete(
        '/invitations/$invitationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- DELETE INVITATION RESPONSE ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('--- DELETE INVITATION ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal menghapus undangan',
        );
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  // EVENT METHODS

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

  Future<ApiResponse<List<EventLoadModel>>> getEventsByInvitationId({
    required String token,
    required int invitationId,
  }) async {
    try {
      final response = await _dio.get(
        '/events/invitation/$invitationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- GET EVENTS BY INVITATION ---');
      debugPrint(response.data.toString());

      final dataList = response.data['data'] as List<dynamic>;
      final events = dataList
          .map((json) => EventLoadModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        status: response.data['status'],
        message: response.data['message'],
        data: events,
      );
    } on DioException catch (e) {
      debugPrint('--- GET EVENTS ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat event');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  Future<ApiResponse<EventLoadModel>> getEventById({
    required String token,
    required int eventId,
  }) async {
    try {
      final response = await _dio.get(
        '/events/$eventId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- GET EVENT BY ID ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => EventLoadModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('--- GET EVENT BY ID ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat acara');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  Future<ApiResponse<EventModel>> updateEventById({
    required String token,
    required int eventId,
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
      final response = await _dio.put(
        '/events/$eventId',
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

      debugPrint('--- UPDATE EVENT RESPONSE ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => EventModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('--- UPDATE EVENT ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal memperbarui acara',
        );
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  Future<ApiResponse<void>> deleteEventById({
    required String token,
    required int eventId,
  }) async {
    try {
      final response = await _dio.delete(
        '/events/$eventId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- DELETE EVENT RESPONSE ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('--- DELETE EVENT ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal menghapus acara');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  /// Get all wishes by invitation ID
  Future<ApiResponse<List<WishModel>>> getWishesByInvitationId(
    int invitationId,
  ) async {
    try {
      final response = await _dio.get(
        '/wishes/invitation/$invitationId',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      debugPrint('--- GET WISHES BY INVITATION ---');
      debugPrint(response.data.toString());

      // Handle response dengan struktur yang berbeda
      List<dynamic> dataList;
      if (response.data is Map<String, dynamic>) {
        // Jika response berupa object dengan key 'data'
        if (response.data.containsKey('data')) {
          dataList = response.data['data'] as List<dynamic>;
        } else {
          // Jika tidak ada key 'data', anggap seluruh response adalah array
          dataList = [];
        }
      } else if (response.data is List) {
        // Jika response langsung berupa array
        dataList = response.data as List<dynamic>;
      } else {
        dataList = [];
      }

      debugPrint('Processing ${dataList.length} wishes from API');

      List<WishModel> wishes = [];
      for (var item in dataList) {
        try {
          final wish = WishModel.fromJson(item as Map<String, dynamic>);
          wishes.add(wish);
          debugPrint(
            'Successfully parsed wish: ${wish.guestName} - ${wish.attendanceStatus}',
          );
        } catch (e) {
          debugPrint('Error parsing wish item: $e');
          debugPrint('Item data: $item');
          // Continue processing other items
        }
      }

      return ApiResponse(
        status: response.data is Map ? response.data['status'] : 200,
        message: response.data is Map ? response.data['message'] : 'Success',
        data: wishes,
      );
    } on DioException catch (e) {
      debugPrint('--- GET WISHES ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat ucapan');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    } catch (e) {
      debugPrint('--- GET WISHES PARSING ERROR ---');
      debugPrint('Error: $e');
      throw Exception('Gagal memproses data ucapan: $e');
    }
  }

  /// Create a new wish - dengan error handling yang lebih baik
  Future<ApiResponse<WishModel>> createWish({
    required int invitationId,
    int? guestId,
    required String guestName,
    required String attendanceStatus,
    required String message,
  }) async {
    try {
      final requestData = {
        "invitation_id": invitationId,
        "guest_name": guestName,
        "attendance_status": attendanceStatus.toLowerCase(),
        "message": message,
      };

      // Hanya tambahkan guest_id jika tidak null
      if (guestId != null) {
        requestData["guest_id"] = guestId;
      }

      debugPrint('--- CREATE WISH REQUEST ---');
      debugPrint('Request data: $requestData');

      final response = await _dio.post(
        '/wishes',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- CREATE WISH RESPONSE ---');
      debugPrint(response.data.toString());

      // Parse response dengan aman
      WishModel? createdWish;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;

        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          try {
            createdWish = WishModel.fromJson(
              responseMap['data'] as Map<String, dynamic>,
            );
            debugPrint(
              'Successfully parsed created wish: ${createdWish.guestName}',
            );
          } catch (e) {
            debugPrint('Error parsing created wish: $e');
          }
        }
      }

      return ApiResponse(
        status: response.data is Map
            ? response.data['status']
            : response.statusCode,
        message: response.data is Map ? response.data['message'] : 'Success',
        data: createdWish,
      );
    } on DioException catch (e) {
      debugPrint('--- CREATE WISH ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal mengirim ucapan');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    } catch (e) {
      debugPrint('--- CREATE WISH PARSING ERROR ---');
      debugPrint('Error: $e');
      throw Exception('Gagal memproses response: $e');
    }
  }

  /// Get all packages (admin only)
  Future<ApiResponse<List<PackageModel>>> getAllPackages(String token) async {
    try {
      final response = await _dio.get(
        '/packages',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- GET ALL PACKAGES ---');
      debugPrint(response.data.toString());

      final dataList = response.data['data'] as List<dynamic>;
      final packages = dataList
          .map((json) => PackageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        status: response.data['status'],
        message: response.data['message'],
        data: packages,
      );
    } on DioException catch (e) {
      debugPrint('--- GET ALL PACKAGES ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat paket');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  /// Get active packages (public)
  Future<ApiResponse<List<PackageModel>>> getActivePackages() async {
    try {
      final response = await _dio.get(
        '/packages/active',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      debugPrint('--- GET ACTIVE PACKAGES ---');
      debugPrint(response.data.toString());

      final dataList = response.data['data'] as List<dynamic>;
      final packages = dataList
          .map((json) => PackageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        status: response.data['status'],
        message: response.data['message'],
        data: packages,
      );
    } on DioException catch (e) {
      debugPrint('--- GET ACTIVE PACKAGES ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat paket');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  /// Get package by ID
  Future<ApiResponse<PackageModel>> getPackageById(
    String token,
    int packageId,
  ) async {
    try {
      final response = await _dio.get(
        '/packages/$packageId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- GET PACKAGE BY ID ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => PackageModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('--- GET PACKAGE BY ID ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat paket');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  // GALLERY METHODS - Add these methods to your AuthService class

  /// Upload image to ImgBB
  Future<ImgBBResponse> uploadImageToImgBB(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'key': _imgBBApiKey,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        _imgBBBaseUrl,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      debugPrint('--- IMGBB UPLOAD RESPONSE ---');
      debugPrint(response.data.toString());

      return ImgBBResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('--- IMGBB UPLOAD ERROR ---');
      debugPrint(e.response?.data.toString());
      throw Exception('Gagal mengunggah gambar ke ImgBB');
    }
  }

  /// Get all galleries by invitation ID
  Future<ApiResponse<List<GalleryModel>>> getGalleriesByInvitationId({
    required String token,
    required int invitationId,
  }) async {
    try {
      final response = await _dio.get(
        '/galleries/invitation/$invitationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- GET GALLERIES BY INVITATION ---');
      debugPrint(response.data.toString());

      List<dynamic> dataList = [];
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          dataList = response.data['data'] as List<dynamic>;
        }
      } else if (response.data is List) {
        dataList = response.data as List<dynamic>;
      }

      final galleries = dataList
          .map((json) => GalleryModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse(
        status: response.data is Map ? response.data['status'] : 200,
        message: response.data is Map ? response.data['message'] : 'Success',
        data: galleries,
      );
    } on DioException catch (e) {
      debugPrint('--- GET GALLERIES ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal memuat galeri');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }

  /// Create gallery (upload image) - Updated to store ImgBB ID and delete token
  Future<ApiResponse<GalleryModel>> createGallery({
    required String token,
    required int invitationId,
    required File imageFile,
    required String type,
    String? caption,
    int? orderNumber,
  }) async {
    try {
      // First upload to ImgBB
      debugPrint('--- UPLOADING TO IMGBB ---');
      final imgBBResponse = await uploadImageToImgBB(imageFile);

      if (!imgBBResponse.success || imgBBResponse.data?.url == null) {
        throw Exception('Gagal mengunggah gambar');
      }

      // ubah URL hasil ImgBB
      var imageUrl = imgBBResponse.data!.url!;
      imageUrl = imageUrl.replaceFirst('i.ibb.co', 'i.ibb.co.com');
      debugPrint('Image uploaded to ImgBB: $imageUrl');

      // Extract ID and delete token from ImgBB response
      final imgbbId = imgBBResponse.data!.id;
      final deleteUrl = imgBBResponse.data!.deleteUrl ?? '';

      // Extract delete token from delete URL
      // Delete URL format: https://ibb.co/delete/abc123/xyz789
      String? deleteToken;
      if (deleteUrl.isNotEmpty) {
        final uri = Uri.parse(deleteUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3 && pathSegments[0] == 'delete') {
          deleteToken =
              pathSegments[2]; // The delete token is the third segment
        }
      }

      debugPrint('ImgBB ID: $imgbbId');
      debugPrint('Delete Token: $deleteToken');

      // Then create gallery record
      final formData = FormData.fromMap({
        'invitation_id': invitationId,
        'type': type,
        'file_path': imageUrl, // Use ImgBB URL as file_path
        'imgbb_id': imgbbId, // Store ImgBB image ID
        'delete_token': deleteToken, // Store ImgBB delete token
        'caption': caption ?? '',
        'order_number': orderNumber ?? 1,
      });

      final response = await _dio.post(
        '/galleries',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- CREATE GALLERY RESPONSE ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(
        response.data,
        fromJsonData: (json) => GalleryModel.fromJson(json),
      );
    } on DioException catch (e) {
      debugPrint('--- CREATE GALLERY ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(e.response?.data['message'] ?? 'Gagal membuat galeri');
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    } catch (e) {
      debugPrint('--- CREATE GALLERY GENERAL ERROR ---');
      debugPrint('Error: $e');
      throw Exception('Gagal mengunggah gambar: $e');
    }
  }

  /// Delete image from ImgBB using image ID and delete token
  Future<bool> deleteImageFromImgBB(String imageId, String deleteToken) async {
    try {
      final deleteUrl =
          'https://api.imgbb.com/1/delete/$imageId/$deleteToken?key=$_imgBBApiKey';

      debugPrint('--- DELETING FROM IMGBB ---');
      debugPrint('Delete URL: $deleteUrl');

      final response = await _dio.get(deleteUrl);
      debugPrint('--- IMGBB DELETE RESPONSE ---');
      debugPrint(response.data.toString());

      // Check if deletion was successful
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final success = responseData['success'] ?? false;
        debugPrint('ImgBB deletion success: $success');
        return success;
      }

      return false;
    } catch (e) {
      debugPrint('--- IMGBB DELETE ERROR ---');
      debugPrint('Error deleting from ImgBB: $e');
      // Don't throw error here, just return false
      // We still want to delete from our database even if ImgBB deletion fails
      return false;
    }
  }

  /// Delete gallery - Updated to delete from ImgBB using ID and token
  Future<ApiResponse<void>> deleteGallery({
    required String token,
    required int galleryId,
    String? imgbbId, // ImgBB image ID
    String? deleteToken, // ImgBB delete token
  }) async {
    try {
      // First, try to delete from ImgBB if both ID and token are provided
      if (imgbbId != null &&
          imgbbId.isNotEmpty &&
          deleteToken != null &&
          deleteToken.isNotEmpty) {
        debugPrint('--- DELETING FROM IMGBB ---');
        final imgBBDeleted = await deleteImageFromImgBB(imgbbId, deleteToken);
        if (imgBBDeleted) {
          debugPrint('Successfully deleted from ImgBB');
        } else {
          debugPrint(
            'Failed to delete from ImgBB, but continuing with database deletion',
          );
        }
      } else {
        debugPrint('Missing ImgBB ID or delete token, skipping ImgBB deletion');
      }

      // Then delete from database
      final response = await _dio.delete(
        '/galleries/$galleryId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('--- DELETE GALLERY RESPONSE ---');
      debugPrint(response.data.toString());

      return ApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('--- DELETE GALLERY ERROR ---');
      debugPrint(e.response?.data.toString());

      if (e.response != null && e.response?.data is Map<String, dynamic>) {
        throw Exception(
          e.response?.data['message'] ?? 'Gagal menghapus galeri',
        );
      } else {
        throw Exception('Terjadi kesalahan jaringan');
      }
    }
  }
}
