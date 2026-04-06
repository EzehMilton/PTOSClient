import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'jwt_token';
  static const _keyFullName = 'user_full_name';

  // JWT token
  Future<String?> readToken() => _storage.read(key: _keyToken);

  Future<void> writeToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<void> deleteToken() => _storage.delete(key: _keyToken);

  // User full name
  Future<String?> readFullName() => _storage.read(key: _keyFullName);

  Future<void> writeFullName(String name) =>
      _storage.write(key: _keyFullName, value: name);

  Future<void> deleteFullName() => _storage.delete(key: _keyFullName);

  // Clear all
  Future<void> clearAll() async {
    await deleteToken();
    await deleteFullName();
  }
}
