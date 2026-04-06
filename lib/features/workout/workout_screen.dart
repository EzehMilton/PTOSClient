import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import 'workout_provider.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WorkoutProvider>().loadWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Workout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.currentWorkout == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: provider.loadWorkouts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final current = provider.currentWorkout;
          final previous = provider.previousWorkouts;

          if (current == null && previous.isEmpty) {
            return const _EmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (current != null) ...[
                  _CurrentWorkoutSection(workout: current),
                  const SizedBox(height: 28),
                ],
                if (previous.isNotEmpty)
                  _PreviousWorkoutsSection(workouts: previous),
              ],
            ),
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
              Icons.fitness_center,
              size: 64,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No workouts assigned yet.\nYour PT will assign one soon.',
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
// Current workout section
// ---------------------------------------------------------------------------

class _CurrentWorkoutSection extends StatelessWidget {
  const _CurrentWorkoutSection({required this.workout});

  final Map<String, dynamic> workout;

  @override
  Widget build(BuildContext context) {
    final name = workout['name'] as String? ?? 'Workout';
    final description = workout['description'] as String? ?? '';
    final dateStr = workout['assignedDate'] as String? ??
        workout['createdAt'] as String? ??
        '';
    final status = (workout['status'] as String? ?? '').toUpperCase();
    final exercises = workout['exercises'] as List<dynamic>? ?? [];
    final id = '${workout['id'] ?? workout['_id'] ?? ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + status row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            _StatusPill(status: status),
          ],
        ),
        const SizedBox(height: 6),

        // Assigned date
        if (dateStr.isNotEmpty)
          Text(
            'Assigned ${_formatDate(dateStr)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        const SizedBox(height: 12),

        // Completed banner
        if (status == 'COMPLETED') ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
                SizedBox(width: 8),
                Text(
                  'Completed',
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Description
        if (description.isNotEmpty) ...[
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Exercise list
        if (exercises.isNotEmpty) ...[
          const Text(
            'Exercises',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...exercises.map((e) {
            final ex = e as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExerciseCard(exercise: ex),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Action button
        if (status == 'ASSIGNED' || status == 'IN_PROGRESS')
          _ActionButton(workoutId: id, status: status),
      ],
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
}

// ---------------------------------------------------------------------------
// Status pill
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (status) {
      case 'IN_PROGRESS':
        color = const Color(0xFFFBBF24);
        label = 'In Progress';
      case 'COMPLETED':
        color = const Color(0xFF34D399);
        label = 'Completed';
      default:
        color = const Color(0xFF7B5CF6);
        label = 'Assigned';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise card
// ---------------------------------------------------------------------------

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});

  final Map<String, dynamic> exercise;

  @override
  Widget build(BuildContext context) {
    final name = exercise['name'] as String? ?? '';
    final sets = exercise['sets'];
    final reps = exercise['reps'];
    final notes = exercise['notes'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (sets != null) ...[
                _MetricChip(label: 'Sets', value: '$sets'),
                const SizedBox(width: 10),
              ],
              if (reps != null) _MetricChip(label: 'Reps', value: '$reps'),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button (Start / Complete)
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.workoutId, required this.status});

  final String workoutId;
  final String status;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B5CF6);
    final isStart = status == 'ASSIGNED';
    final label = isStart ? 'Start Workout' : 'Mark as Complete';
    final nextStatus = isStart ? 'IN_PROGRESS' : 'COMPLETED';

    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: provider.updating
                ? null
                : () async {
                    final ok =
                        await provider.updateStatus(workoutId, nextStatus);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                provider.error ?? 'Update failed')),
                      );
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: purple,
              disabledBackgroundColor: purple.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: provider.updating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(label, style: const TextStyle(fontSize: 16)),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Previous workouts (collapsible)
// ---------------------------------------------------------------------------

class _PreviousWorkoutsSection extends StatelessWidget {
  const _PreviousWorkoutsSection({required this.workouts});

  final List<Map<String, dynamic>> workouts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        collapsedIconColor: Colors.white54,
        iconColor: Colors.white54,
        title: Text(
          'Previous workouts (${workouts.length})',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        children: workouts
            .map((w) => _PreviousWorkoutTile(workout: w))
            .toList(),
      ),
    );
  }
}

class _PreviousWorkoutTile extends StatelessWidget {
  const _PreviousWorkoutTile({required this.workout});

  final Map<String, dynamic> workout;

  @override
  Widget build(BuildContext context) {
    final name = workout['name'] as String? ?? 'Workout';
    final dateStr = workout['assignedDate'] as String? ??
        workout['createdAt'] as String? ??
        '';
    final status = (workout['status'] as String? ?? '').toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (dateStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatDate(dateStr),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _StatusPill(status: status),
        ],
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
}
