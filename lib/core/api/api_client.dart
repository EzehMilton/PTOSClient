import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/public_invite.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _navigatorKey?.currentState
                ?.pushNamedAndRemoveUntil('/login', (_) => false);
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  Future<PublicInvite> getPublicInvite(String token) async {
    final response = await _dio.get(
      '/api/public/invites/${Uri.encodeComponent(token)}',
    );
    final data = response.data as Map<String, dynamic>;
    return PublicInvite.fromJson(data, fallbackToken: token);
  }

  Future<void> uploadProfilePhotos({
    XFile? frontPhoto,
    XFile? sidePhoto,
    XFile? backPhoto,
  }) async {
    Future<MultipartFile> multipartFromXFile(
      XFile file,
      String filenamePrefix,
    ) async {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? MediaType('image', 'png')
          : MediaType('image', 'jpeg');

      return MultipartFile.fromBytes(
        bytes,
        filename: '$filenamePrefix.$ext',
        contentType: mime,
      );
    }

    final formData = FormData();

    if (frontPhoto != null) {
      formData.files.add(
        MapEntry('photoFront', await multipartFromXFile(frontPhoto, 'front')),
      );
    }
    if (sidePhoto != null) {
      formData.files.add(
        MapEntry('photoSide', await multipartFromXFile(sidePhoto, 'side')),
      );
    }
    if (backPhoto != null) {
      formData.files.add(
        MapEntry('photoBack', await multipartFromXFile(backPhoto, 'back')),
      );
    }

    await _dio.post('/api/client/profile/photos', data: formData);
  }

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
}
