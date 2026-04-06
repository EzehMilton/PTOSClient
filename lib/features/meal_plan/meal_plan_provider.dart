import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_client.dart';

class MealPlanProvider extends ChangeNotifier {
  Map<String, dynamic>? _plan;
  Map<String, dynamic>? get plan => _plan;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // Today's compliance state
  String? _todayCompliance;
  String? get todayCompliance => _todayCompliance;

  bool _submitting = false;
  bool get submitting => _submitting;

  Future<void> loadPlan() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.dio.get('/api/client/meal-plan');
      _plan = response.data as Map<String, dynamic>?;

      // Check if compliance was already logged today.
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final compliance = _plan?['compliance'] as List<dynamic>?;
      if (compliance != null) {
        for (final entry in compliance) {
          final e = entry as Map<String, dynamic>;
          final date = e['date'] as String? ?? '';
          if (date.startsWith(today)) {
            _todayCompliance = e['level'] as String?;
            break;
          }
        }
      }

      _loading = false;
      notifyListeners();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _plan = null;
        _loading = false;
        notifyListeners();
        return;
      }
      _error = _extractMessage(e) ?? 'Failed to load meal plan';
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submitCompliance(String level, {String? notes}) async {
    _submitting = true;
    notifyListeners();

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await ApiClient.instance.dio.post(
        '/api/client/meal-plan/compliance',
        data: {
          'date': today,
          'level': level,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      _todayCompliance = level;
      _submitting = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _extractMessage(e) ?? 'Failed to submit compliance';
      _submitting = false;
      notifyListeners();
      return false;
    }
  }

  String? _extractMessage(DioException e) {
    if (e.response?.data is Map) {
      return (e.response!.data as Map)['message'] as String?;
    }
    return null;
  }
}
