import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';

class MessagesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  bool _loading = false;
  bool get loading => _loading;

  bool _sending = false;
  bool get sending => _sending;

  String? _error;
  String? get error => _error;

  Future<void> loadMessages() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.dio.get('/api/client/messages');
      final list = response.data as List<dynamic>;
      _messages = list.cast<Map<String, dynamic>>();
      _loading = false;
      notifyListeners();
    } on DioException catch (e) {
      _error = _extractMessage(e) ?? 'Failed to load messages';
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String content) async {
    _sending = true;
    notifyListeners();

    try {
      await ApiClient.instance.dio.post(
        '/api/client/messages',
        data: {'content': content},
      );
      _sending = false;
      notifyListeners();

      // Reload the thread so the new message appears.
      await loadMessages();
      return true;
    } on DioException catch (e) {
      _error = _extractMessage(e) ?? 'Failed to send message';
      _sending = false;
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
