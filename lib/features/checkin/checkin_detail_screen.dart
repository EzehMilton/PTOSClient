import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import 'checkin_provider.dart';

class CheckInDetailScreen extends StatefulWidget {
  const CheckInDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<CheckInDetailScreen> createState() => _CheckInDetailScreenState();
}

class _CheckInDetailScreenState extends State<CheckInDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CheckInProvider>().loadCheckinDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Check-in Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.checkinHistory),
        ),
      ),
      body: Consumer<CheckInProvider>(
        builder: (context, provider, _) {
          if (provider.loadingDetail) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.detailError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.detailError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        provider.loadCheckinDetail(widget.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = provider.selectedCheckin;
          if (data == null) {
            return const Center(child: Text('Check-in not found'));
          }

          return _DetailBody(data: data);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail body
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.data});

  final Map<String, dynamic> data;

  static const _moodEmojis = ['😔', '😐', '🙂', '😊', '😄'];
  static const _energyLabels = [
    'Very Low',
    'Low',
    'Medium',
    'High',
    'Very High'
  ];
  static const _sleepLabels = [
    'Poor',
    'Fair',
    'Average',
    'Good',
    'Excellent'
  ];

  @override
  Widget build(BuildContext context) {
    final dateStr =
        data['date'] as String? ?? data['createdAt'] as String? ?? '';
    final weight = data['weight'];
    final mood = _toInt(data['mood']);
    final energy = _toInt(data['energy']);
    final sleep = _toInt(data['sleep']);
    final notes = data['notes'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final reviewed = status.toLowerCase() == 'reviewed';
    final feedback = data['feedback'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Date & status ---
          Row(
            children: [
              Text(
                _formatDate(dateStr),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _StatusBadge(reviewed: reviewed),
            ],
          ),
          const SizedBox(height: 24),

          // --- Metrics grid ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1F2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Weight',
                        value: '${_formatWeight(weight)} kg',
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Mood',
                        value: mood >= 1 && mood <= 5
                            ? _moodEmojis[mood - 1]
                            : '-',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Energy',
                        value: energy >= 1 && energy <= 5
                            ? _energyLabels[energy - 1]
                            : '-',
                      ),
                    ),
                    Expanded(
                      child: _MetricTile(
                        label: 'Sleep',
                        value: sleep >= 1 && sleep <= 5
                            ? _sleepLabels[sleep - 1]
                            : '-',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Notes ---
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ),
          ],

          // --- PT Feedback ---
          if (reviewed && feedback != null) ...[
            const SizedBox(height: 24),
            _FeedbackSection(feedback: feedback),
          ],
        ],
      ),
    );
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatWeight(dynamic w) {
    if (w is num) return w.toStringAsFixed(1);
    if (w is String) {
      final parsed = double.tryParse(w);
      if (parsed != null) return parsed.toStringAsFixed(1);
    }
    return '$w';
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.reviewed});

  final bool reviewed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: reviewed
            ? const Color(0xFF34D399).withValues(alpha: 0.15)
            : const Color(0xFFFBBF24).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        reviewed ? 'Reviewed' : 'Awaiting feedback',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color:
              reviewed ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric tile
// ---------------------------------------------------------------------------

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PT Feedback section
// ---------------------------------------------------------------------------

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({required this.feedback});

  final Map<String, dynamic> feedback;

  @override
  Widget build(BuildContext context) {
    final text = feedback['text'] as String? ?? '';
    final dateStr =
        feedback['date'] as String? ?? feedback['createdAt'] as String? ?? '';
    final formattedDate = _formatDate(dateStr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.comment_outlined,
              size: 18,
              color: Color(0xFF34D399),
            ),
            const SizedBox(width: 6),
            const Text(
              'PT Feedback',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF34D399),
              ),
            ),
            const Spacer(),
            if (formattedDate.isNotEmpty)
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF34D399).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF34D399).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
