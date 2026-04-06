import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import 'messages_provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<MessagesProvider>();
    provider.loadMessages().then((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<MessagesProvider>();
    _inputController.clear();

    final ok = await provider.sendMessage(text);
    if (ok) {
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to send')),
      );
    }
  }

  Future<void> _refresh() async {
    await context.read<MessagesProvider>().loadMessages();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: Consumer<MessagesProvider>(
              builder: (context, provider, _) {
                if (provider.loading && provider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(provider.error!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: provider.loadMessages,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.messages.isEmpty) {
                  return const _EmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFF7B5CF6),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(
                          message: provider.messages[index]);
                    },
                  ),
                );
              },
            ),
          ),

          // Input bar
          const Divider(height: 1, color: Color(0xFF2A2B3D)),
          _InputBar(
            controller: _inputController,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet.\nSend your PT a message!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final senderRole =
        (message['senderRole'] as String? ?? '').toUpperCase();
    final isClient = senderRole == 'CLIENT';
    final content = message['content'] as String? ?? '';
    final timestamp = message['createdAt'] as String? ??
        message['date'] as String? ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isClient ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isClient) const Spacer(flex: 2),
          Flexible(
            flex: 5,
            child: Column(
              crossAxisAlignment: isClient
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isClient
                        ? const Color(0xFF7B5CF6)
                        : const Color(0xFF1E1F2E),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isClient ? 16 : 4),
                      bottomRight:
                          Radius.circular(isClient ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
                if (timestamp.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                    child: Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isClient) const Spacer(flex: 2),
        ],
      ),
    );
  }

  String _formatTimestamp(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF171826),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1F2E),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: provider.sending ? null : onSend,
                  icon: provider.sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF7B5CF6),
                          ),
                        )
                      : const Icon(Icons.send, color: Color(0xFF7B5CF6)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
