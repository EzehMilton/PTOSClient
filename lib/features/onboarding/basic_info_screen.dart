import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../profile/profile_provider.dart';

enum _HeightUnit { cm, ft }

enum _WeightUnit { kg, lbs }

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  _HeightUnit _heightUnit = _HeightUnit.cm;
  _WeightUnit _weightUnit = _WeightUnit.kg;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final age = int.parse(_ageController.text.trim());
    final heightValue = double.parse(_heightController.text.trim());
    final weightValue = double.parse(_weightController.text.trim());
    final heightCm = _toHeightCm(heightValue);
    final currentWeightKg = _toWeightKg(weightValue);

    final provider = context.read<ProfileProvider>();
    final saved = await provider.saveProfile({
      'age': age,
      'heightCm': heightCm,
      'height': heightCm,
      'currentWeightKg': currentWeightKg,
      'currentWeight': currentWeightKg,
    });

    if (!mounted) return;

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Basic info saved')),
      );
      context.go(Routes.goals);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Failed to save basic info')),
    );
  }

  double _toHeightCm(double value) {
    switch (_heightUnit) {
      case _HeightUnit.cm:
        return double.parse(value.toStringAsFixed(1));
      case _HeightUnit.ft:
        return double.parse((value * 30.48).toStringAsFixed(1));
    }
  }

  double _toWeightKg(double value) {
    switch (_weightUnit) {
      case _WeightUnit.kg:
        return double.parse(value.toStringAsFixed(1));
      case _WeightUnit.lbs:
        return double.parse((value * 0.45359237).toStringAsFixed(1));
    }
  }

  String? _validateAge(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your age';
    }

    final age = int.tryParse(trimmed);
    if (age == null) {
      return 'Age must be a whole number';
    }

    if (age < 13 || age > 120) {
      return 'Enter an age between 13 and 120';
    }

    return null;
  }

  String? _validateHeight(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your height';
    }

    final height = double.tryParse(trimmed);
    if (height == null) {
      return 'Height must be a number';
    }

    final isValid = switch (_heightUnit) {
      _HeightUnit.cm => height >= 100 && height <= 250,
      _HeightUnit.ft => height >= 3 && height <= 8.2,
    };

    if (!isValid) {
      return _heightUnit == _HeightUnit.cm
          ? 'Enter a height between 100 and 250 cm'
          : 'Enter a height between 3.0 and 8.2 ft';
    }

    return null;
  }

  String? _validateWeight(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your current weight';
    }

    final weight = double.tryParse(trimmed);
    if (weight == null) {
      return 'Weight must be a number';
    }

    final isValid = switch (_weightUnit) {
      _WeightUnit.kg => weight >= 30 && weight <= 350,
      _WeightUnit.lbs => weight >= 66 && weight <= 770,
    };

    if (!isValid) {
      return _weightUnit == _WeightUnit.kg
          ? 'Enter a weight between 30 and 350 kg'
          : 'Enter a weight between 66 and 770 lbs';
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
                                  onPressed: () => context.go(Routes.createAccount),
                                  style: IconButton.styleFrom(
                                    backgroundColor: field,
                                  ),
                                  icon: const Icon(Icons.arrow_back_ios_new),
                                ),
                                const Spacer(),
                                const _ProgressStepIndicator(
                                  currentStep: 3,
                                  totalSteps: 7,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Basic info',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'We use these details to personalise your coaching plan from day one.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _SectionLabel(label: 'Age'),
                            const SizedBox(height: 10),
                            _NumberField(
                              controller: _ageController,
                              hintText: 'Enter your age',
                              suffixText: 'years',
                              validator: _validateAge,
                            ),
                            const SizedBox(height: 20),
                            _SectionLabel(label: 'Height'),
                            const SizedBox(height: 10),
                            _UnitToggle<_HeightUnit>(
                              value: _heightUnit,
                              options: const {
                                _HeightUnit.cm: 'cm',
                                _HeightUnit.ft: 'ft',
                              },
                              onChanged: (value) {
                                setState(() => _heightUnit = value);
                                _formKey.currentState?.validate();
                              },
                            ),
                            const SizedBox(height: 12),
                            _NumberField(
                              controller: _heightController,
                              hintText: _heightUnit == _HeightUnit.cm
                                  ? 'e.g. 178'
                                  : 'e.g. 5.9',
                              suffixText:
                                  _heightUnit == _HeightUnit.cm ? 'cm' : 'ft',
                              validator: _validateHeight,
                              helperText: _heightUnit == _HeightUnit.ft
                                  ? 'Enter height in decimal feet'
                                  : 'Metric values are sent to the backend',
                            ),
                            const SizedBox(height: 20),
                            _SectionLabel(label: 'Current weight'),
                            const SizedBox(height: 10),
                            _UnitToggle<_WeightUnit>(
                              value: _weightUnit,
                              options: const {
                                _WeightUnit.kg: 'kg',
                                _WeightUnit.lbs: 'lbs',
                              },
                              onChanged: (value) {
                                setState(() => _weightUnit = value);
                                _formKey.currentState?.validate();
                              },
                            ),
                            const SizedBox(height: 12),
                            _NumberField(
                              controller: _weightController,
                              hintText: _weightUnit == _WeightUnit.kg
                                  ? 'e.g. 82.5'
                                  : 'e.g. 182',
                              suffixText:
                                  _weightUnit == _WeightUnit.kg ? 'kg' : 'lbs',
                              validator: _validateWeight,
                              helperText: _weightUnit == _WeightUnit.lbs
                                  ? 'Saved as kilograms after conversion'
                                  : 'Metric values are sent to the backend',
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.92),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.hintText,
    required this.validator,
    this.suffixText,
    this.helperText,
  });

  final TextEditingController controller;
  final String hintText;
  final String? suffixText;
  final String? helperText;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hintText,
        suffixText: suffixText,
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
    );
  }
}

class _UnitToggle<T> extends StatelessWidget {
  const _UnitToggle({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2031),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: options.entries.map((entry) {
          final isSelected = entry.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7B5CF6)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
