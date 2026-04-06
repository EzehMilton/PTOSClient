import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import 'checkin_provider.dart';

class CheckInHistoryScreen extends StatefulWidget {
  const CheckInHistoryScreen({super.key});

  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CheckInProvider>().loadCheckins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Check-in History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: Consumer<CheckInProvider>(
        builder: (context, provider, _) {
          if (provider.loadingList) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.listError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.listError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: provider.loadCheckins,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.checkins.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: provider.checkins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _CheckInCard(checkin: provider.checkins[index]);
            },
          );
        },
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
              Icons.fact_check_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No check-ins yet.\nSubmit your first one!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(Routes.checkinNew),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CF6),
              ),
              child: const Text('Submit Check-in'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check-in card
// ---------------------------------------------------------------------------

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({required this.checkin});

  final Map<String, dynamic> checkin;

  @override
  Widget build(BuildContext context) {
    final dateStr = checkin['date'] as String? ??
        checkin['createdAt'] as String? ??
        '';
    final formattedDate = _formatDate(dateStr);
    final weight = checkin['weight'];
    final status = checkin['status'] as String? ?? 'pending';
    final reviewed = status.toLowerCase() == 'reviewed';
    final id = '${checkin['id'] ?? checkin['_id'] ?? ''}';

    return GestureDetector(
      onTap: () {
        if (id.isNotEmpty) {
          context.go(Routes.checkinDetail(id));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F2E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Date & weight
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatWeight(weight)} kg',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
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
                  color: reviewed
                      ? const Color(0xFF34D399)
                      : const Color(0xFFFBBF24),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
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
