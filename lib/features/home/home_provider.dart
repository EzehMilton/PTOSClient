import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';

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

  String get goalFormatted {
    return _goal
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  Future<void> loadProfile() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.dio.get('/api/client/profile');
      final data = response.data as Map<String, dynamic>;

      _fullName = data['fullName'] as String? ?? '';
      _currentWeight = (data['currentWeight'] as num?)?.toDouble() ?? 0;
      _targetWeight = (data['targetWeight'] as num?)?.toDouble() ?? 0;
      _goal = data['goal'] as String? ?? '';

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
}
