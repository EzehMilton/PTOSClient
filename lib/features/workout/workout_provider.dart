import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';

class WorkoutProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _workouts = [];

  Map<String, dynamic>? get currentWorkout {
    for (final w in _workouts) {
      final s = (w['status'] as String? ?? '').toUpperCase();
      if (s == 'ASSIGNED' || s == 'IN_PROGRESS') return w;
    }
    return null;
  }

  List<Map<String, dynamic>> get previousWorkouts {
    final current = currentWorkout;
    final currentId = current?['id'] ?? current?['_id'];
    return _workouts.where((w) {
      final id = w['id'] ?? w['_id'];
      return id != currentId || currentId == null;
    }).toList();
  }

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool _updating = false;
  bool get updating => _updating;

  Future<void> loadWorkouts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.dio.get('/api/client/workouts');
      final list = response.data as List<dynamic>;
      _workouts = list.cast<Map<String, dynamic>>();
      _loading = false;
      notifyListeners();
    } on DioException catch (e) {
      _error = _extractMessage(e) ?? 'Failed to load workouts';
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    _updating = true;
    notifyListeners();

    try {
      await ApiClient.instance.dio.put(
        '/api/client/workouts/$id/status',
        data: {'status': status},
      );

      // Update local state so the UI reflects the change immediately.
      for (final w in _workouts) {
        final wId = '${w['id'] ?? w['_id'] ?? ''}';
        if (wId == id) {
          w['status'] = status;
          break;
        }
      }

      _updating = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _extractMessage(e) ?? 'Failed to update workout';
      _updating = false;
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
