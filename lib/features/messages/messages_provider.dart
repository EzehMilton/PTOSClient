import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';

class MessagesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  int get unreadCount =>
      _messages.where((message) => _isIncomingUnread(message)).length;

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

  bool _isIncomingUnread(Map<String, dynamic> message) {
    final senderRole = (message['senderRole'] as String? ?? '').toUpperCase();
    if (senderRole == 'CLIENT') return false;

    final bool? read = _readBool(message, const [
      'isRead',
      'read',
      'isSeen',
      'seen',
      'viewed',
      'isViewed',
    ]);
    if (read != null) return !read;

    final readAt = message['readAt'] ?? message['seenAt'] ?? message['viewedAt'];
    if (readAt is String && readAt.trim().isNotEmpty) return false;

    // If the backend does not expose unread state, do not show a misleading badge.
    return false;
  }

  bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
    }
    return null;
  }
}
