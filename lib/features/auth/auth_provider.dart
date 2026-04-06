import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      await _persistSession(data);

      _loading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String inviteToken,
    required String fullName,
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.post(
        '/api/auth/register',
        data: {
          'inviteToken': inviteToken,
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      await _persistSession(data, fallbackFullName: fullName);

      _loading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _extractRegisterError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistSession(
    Map<String, dynamic> data, {
    String? fallbackFullName,
  }) async {
    final token = _readString(data, const [
      'token',
      'accessToken',
      'jwt',
    ]);
    final fullName = _readString(data, const [
          'fullName',
          'name',
        ]) ??
        fallbackFullName;

    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/register'),
        error: 'Missing auth token in response',
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/register'),
          statusCode: 500,
          data: const {
            'message': 'Account created but no session was returned.',
          },
        ),
      );
    }

    await TokenStorage.instance.writeToken(token);
    if (fullName != null && fullName.isNotEmpty) {
      await TokenStorage.instance.writeFullName(fullName);
    }
  }

  String _extractError(DioException e) {
    final message = _extractMessage(e);
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 400 || statusCode == 401) {
      return 'Invalid email or password';
    }

    if (statusCode != null) {
      return 'Login failed (HTTP $statusCode)';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection to the server timed out';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return kIsWeb
            ? 'Browser could not reach the API. Check backend availability and CORS settings.'
            : 'Could not connect to the server';
      case DioExceptionType.badCertificate:
        return 'Could not verify the server certificate';
      case DioExceptionType.cancel:
        return 'Login request was cancelled';
      case DioExceptionType.badResponse:
        return 'Login failed';
    }
  }

  String _extractRegisterError(DioException e) {
    final message = _extractMessage(e);
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 400 || statusCode == 409) {
      return 'Could not create your account';
    }

    if (statusCode != null) {
      return 'Account creation failed (HTTP $statusCode)';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection to the server timed out';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return kIsWeb
            ? 'Browser could not reach the API. Check backend availability and CORS settings.'
            : 'Could not connect to the server';
      case DioExceptionType.badCertificate:
        return 'Could not verify the server certificate';
      case DioExceptionType.cancel:
        return 'Account creation request was cancelled';
      case DioExceptionType.badResponse:
        return 'Account creation failed';
    }
  }

  String? _extractMessage(DioException e) {
    if (e.response?.data is Map) {
      return (e.response!.data as Map)['message'] as String?;
    }
    return null;
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
