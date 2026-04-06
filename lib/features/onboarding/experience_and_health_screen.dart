import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/models/client_training_experience.dart';
import '../profile/profile_provider.dart';

class ExperienceAndHealthScreen extends StatefulWidget {
  const ExperienceAndHealthScreen({super.key});

  @override
  State<ExperienceAndHealthScreen> createState() =>
      _ExperienceAndHealthScreenState();
}

class _ExperienceAndHealthScreenState extends State<ExperienceAndHealthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _injuriesController = TextEditingController();
  final _dietaryPreferencesController = TextEditingController();
  final _additionalNotesController = TextEditingController();

  ClientTrainingExperience? _selectedExperience;

  @override
  void dispose() {
    _injuriesController.dispose();
    _dietaryPreferencesController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedExperience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select your training experience to continue'),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<ProfileProvider>();
    final saved = await provider.saveProfile({
      'trainingExperience': _selectedExperience!.backendValue,
      'injuriesOrConditions': _optionalText(_injuriesController.text),
      'dietaryPreferences': _optionalText(_dietaryPreferencesController.text),
      'additionalNotes': _optionalText(_additionalNotesController.text),
    });

    if (!mounted) return;

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Experience and health saved')),
      );
      context.go(Routes.progressPhotos);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.error ?? 'Failed to save experience and health details',
        ),
      ),
    );
  }

  String? _optionalText(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
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
                                  onPressed: () => context.go(Routes.goals),
                                  style: IconButton.styleFrom(
                                    backgroundColor: field,
                                  ),
                                  icon: const Icon(Icons.arrow_back_ios_new),
                                ),
                                const Spacer(),
                                const _ProgressStepIndicator(
                                  currentStep: 5,
                                  totalSteps: 7,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Experience and health',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Share the context your PT needs to tailor training, nutrition, and support.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Training experience',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...ClientTrainingExperience.values.map(
                              (experience) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SelectableOptionCard(
                                  label: experience.label,
                                  selected: _selectedExperience == experience,
                                  onTap: () {
                                    setState(
                                      () => _selectedExperience = experience,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _MultilineField(
                              controller: _injuriesController,
                              label: 'Injuries or conditions',
                              hintText:
                                  'Anything your PT should know before planning training',
                            ),
                            const SizedBox(height: 16),
                            _MultilineField(
                              controller: _dietaryPreferencesController,
                              label: 'Dietary preferences',
                              hintText:
                                  'Vegetarian, halal, allergies, foods you avoid, and so on',
                            ),
                            const SizedBox(height: 16),
                            _MultilineField(
                              controller: _additionalNotesController,
                              label: 'Additional notes',
                              hintText:
                                  'Anything else that will help your PT support you',
                              helperText: 'Optional',
                              maxLines: 4,
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

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
                  label,
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

class _MultilineField extends StatelessWidget {
  const _MultilineField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.helperText,
    this.maxLines = 3,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? helperText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            filled: true,
            fillColor: const Color(0xFF1E2031),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
      ],
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
