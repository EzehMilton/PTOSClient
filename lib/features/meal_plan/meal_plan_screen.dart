import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import 'meal_plan_provider.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MealPlanProvider>().loadPlan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Meal Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: Consumer<MealPlanProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.plan == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: provider.loadPlan,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.plan == null) {
            return const _EmptyState();
          }

          return _PlanBody(plan: provider.plan!);
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
              Icons.restaurant_menu,
              size: 64,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No meal plan assigned yet.\nYour PT will create one for you.',
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
// Plan body
// ---------------------------------------------------------------------------

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.plan});

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    final title = plan['title'] as String? ?? 'Your Meal Plan';
    final overview = plan['overview'] as String? ?? '';
    final dailyGuidance = plan['dailyGuidance'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Overview card
          if (overview.isNotEmpty) ...[
            _InfoCard(heading: 'Overview', body: overview),
            const SizedBox(height: 14),
          ],

          // Daily guidance card
          if (dailyGuidance.isNotEmpty) ...[
            _InfoCard(heading: 'Daily Guidance', body: dailyGuidance),
            const SizedBox(height: 24),
          ],

          // Compliance section
          const _ComplianceSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info card
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's compliance section
// ---------------------------------------------------------------------------

class _ComplianceSection extends StatefulWidget {
  const _ComplianceSection();

  @override
  State<_ComplianceSection> createState() => _ComplianceSectionState();
}

class _ComplianceSectionState extends State<_ComplianceSection> {
  String? _pendingLevel;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit(MealPlanProvider provider, String level) async {
    final needsNotes = level != 'followed';

    if (needsNotes && _pendingLevel != level) {
      setState(() => _pendingLevel = level);
      return;
    }

    final notes =
        needsNotes ? _notesController.text.trim() : null;

    final ok = await provider.submitCompliance(level, notes: notes);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Submission failed')),
      );
    } else if (ok) {
      setState(() => _pendingLevel = null);
      _notesController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MealPlanProvider>(
      builder: (context, provider, _) {
        final logged = provider.todayCompliance;
        final disabled = logged != null || provider.submitting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Compliance",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Buttons row
            Row(
              children: [
                Expanded(
                  child: _ComplianceButton(
                    label: 'Followed',
                    color: const Color(0xFF34D399),
                    selected: logged == 'followed',
                    disabled: disabled,
                    onTap: () => _submit(provider, 'followed'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComplianceButton(
                    label: 'Partially',
                    color: const Color(0xFFFBBF24),
                    selected: logged == 'partially_followed',
                    disabled: disabled,
                    onTap: () =>
                        _submit(provider, 'partially_followed'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ComplianceButton(
                    label: 'Not Followed',
                    color: const Color(0xFFEF4444),
                    selected: logged == 'not_followed',
                    disabled: disabled,
                    onTap: () => _submit(provider, 'not_followed'),
                  ),
                ),
              ],
            ),

            // Notes field (shown when partially / not followed is pending)
            if (_pendingLevel != null && logged == null) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any notes? (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: provider.submitting
                      ? null
                      : () => _submit(provider, _pendingLevel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5CF6),
                    disabledBackgroundColor:
                        const Color(0xFF7B5CF6).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: provider.submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],

            // Logged confirmation
            if (logged != null) ...[
              const SizedBox(height: 12),
              Text(
                'Logged for today',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Compliance button
// ---------------------------------------------------------------------------

class _ComplianceButton extends StatelessWidget {
  const _ComplianceButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF1E1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? color
                  : disabled
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
