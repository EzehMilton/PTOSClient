import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/models/client_goal.dart';

class HomeProvider extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String _fullName = '';
  String get fullName => _fullName;
  String get firstName => _fullName.split(' ').first;

  double _currentWeight = 0;
  double get currentWeight => _currentWeight;

  double _targetWeight = 0;
  double get targetWeight => _targetWeight;

  String _goal = '';
  String get goal => _goal;

  String get goalFormatted => clientGoalLabel(_goal);

  Future<void> loadProfile() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.dio.get('/api/client/profile');
      final data = response.data as Map<String, dynamic>;

      _fullName = data['fullName'] as String? ?? '';
      _currentWeight =
          _readPositiveDouble(data, const ['currentWeight', 'currentWeightKg']) ??
              _readDouble(data, const ['currentWeight', 'currentWeightKg']) ??
              0;
      _targetWeight =
          _readPositiveDouble(data, const ['targetWeight', 'targetWeightKg']) ??
              _readDouble(data, const ['targetWeight', 'targetWeightKg']) ??
              0;
      _goal = _readString(data, const ['goalType', 'goal']) ?? '';

      _loading = false;
      notifyListeners();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['message'] as String?
          : null;
      _error = message ?? 'Failed to load profile';
      _loading = false;
      notifyListeners();
    }
  }

  double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) {
        return value.toDouble();
      }
    }
    return null;
  }

  double? _readPositiveDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num && value.toDouble() > 0) {
        return value.toDouble();
      }
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
