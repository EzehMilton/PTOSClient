import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models/client_goal.dart';
import '../profile/profile_provider.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _targetWeightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ClientGoal? _selectedGoal;

  @override
  void dispose() {
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a goal to continue')),
      );
      return;
    }

    if (form == null || !form.validate()) {
      return;
    }

    final targetWeightText = _targetWeightController.text.trim();
    final targetWeight = targetWeightText.isEmpty
        ? null
        : double.parse(targetWeightText);

    final provider = context.read<ProfileProvider>();
    final normalizedTargetWeight = targetWeight == null
        ? null
        : double.parse(targetWeight.toStringAsFixed(1));
    final saved = await provider.saveProfile({
      'goalType': _selectedGoal!.backendValue,
      'targetWeightKg': normalizedTargetWeight,
      'targetWeight': normalizedTargetWeight,
    });

    if (!mounted) return;

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals saved')),
      );
      context.go(Routes.experienceAndHealth);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Failed to save goals')),
    );
  }

  String? _validateTargetWeight(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Target weight must be a number';
    }

    if (parsed < 30 || parsed > 350) {
      return 'Enter a target weight between 30 and 350 kg';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7B5CF6);
    const panel = Color(0xFF171826);
    const field = Color(0xFF1E2031);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF11131C),
              Color(0xFF0C0D14),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Consumer<ProfileProvider>(
                  builder: (context, profile, _) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2A000000),
                            blurRadius: 32,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.go(Routes.basicInfo),
                                  style: IconButton.styleFrom(
                                    backgroundColor: field,
                                  ),
                                  icon: const Icon(Icons.arrow_back_ios_new),
                                ),
                                const Spacer(),
                                const _ProgressStepIndicator(
                                  currentStep: 4,
                                  totalSteps: 7,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your main goal',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Pick the coaching outcome that matters most right now. You can change this later.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            ...ClientGoal.values.map(
                              (goal) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GoalOptionCard(
                                  goal: goal,
                                  selected: _selectedGoal == goal,
                                  onTap: () {
                                    setState(() => _selectedGoal = goal);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Target weight (optional)',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _targetWeightController,
                              validator: _validateTargetWeight,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                hintText: 'e.g. 74.0',
                                suffixText: 'kg',
                                helperText:
                                    'Leave blank if you do not want to set one yet',
                                filled: true,
                                fillColor: field,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide:
                                      const BorderSide(color: Colors.white12),
                                ),
                              ),
                            ),
                            if (profile.error != null) ...[
                              const SizedBox(height: 18),
                              Text(
                                profile.error!,
                                style: const TextStyle(
                                  color: Color(0xFFFF7A7A),
                                ),
                              ),
                            ],
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: profile.saving ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: accent,
                                  disabledBackgroundColor:
                                      accent.withValues(alpha: 0.55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: profile.saving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Continue',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalOptionCard extends StatelessWidget {
  const _GoalOptionCard({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final ClientGoal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7B5CF6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.18)
                : const Color(0xFF1E2031),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : Colors.white12,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  goal.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent : Colors.transparent,
                  border: Border.all(
                    color: selected ? accent : Colors.white24,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStepIndicator extends StatelessWidget {
  const _ProgressStepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Step $currentStep',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.64),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(totalSteps, (index) {
            final stepNumber = index + 1;
            final isComplete = stepNumber < currentStep;
            final isCurrent = stepNumber == currentStep;
            final color = isCurrent
                ? const Color(0xFF7B5CF6)
                : isComplete
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.16);

            return Container(
              width: isCurrent ? 30 : 18,
              height: 6,
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}
