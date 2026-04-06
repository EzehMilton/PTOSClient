import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> get profile => _profile;

  bool _loading = false;
  bool get loading => _loading;

  bool _saving = false;
  bool get saving => _saving;

  String? _error;
  String? get error => _error;

  // Convenience getters
  String get fullName => _profile['fullName'] as String? ?? '';
  String get email => _profile['email'] as String? ?? '';
  String? get ptName => _readString(const [
        'ptName',
        'trainerName',
        'personalTrainerName',
        'coachName',
        'inviterName',
      ]);

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> loadProfile() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.dio.get('/api/client/profile');
      _profile = response.data as Map<String, dynamic>;
      _loading = false;
      notifyListeners();
    } on DioException catch (e) {
      _error = _extractMessage(e) ?? 'Failed to load profile';
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(Map<String, dynamic> updates) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.dio.put(
        '/api/client/profile',
        data: updates,
      );
      _profile = response.data as Map<String, dynamic>;
      _saving = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _extractMessage(e) ?? 'Failed to update profile';
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeOnboarding() {
    return saveProfile({
      'onboardingComplete': true,
    });
  }

  String? _extractMessage(DioException e) {
    if (e.response?.data is Map) {
      return (e.response!.data as Map)['message'] as String?;
    }
    return null;
  }

  String? _readString(List<String> keys) {
    for (final key in keys) {
      final value = _profile[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
