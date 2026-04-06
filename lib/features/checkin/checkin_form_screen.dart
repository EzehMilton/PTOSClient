import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import 'checkin_provider.dart';

class CheckInFormScreen extends StatefulWidget {
  const CheckInFormScreen({super.key});

  @override
  State<CheckInFormScreen> createState() => _CheckInFormScreenState();
}

class _CheckInFormScreenState extends State<CheckInFormScreen> {
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<CheckInProvider>();
    provider.reset();
    _weightController.text = provider.weight;
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<CheckInProvider>();
    final weightText = _weightController.text.trim();
    final weightVal = double.tryParse(weightText);

    if (weightText.isEmpty || weightVal == null || weightVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    provider.weight = weightText;
    final success = await provider.submit();

    if (!mounted) return;

    if (success) {
      context.go(Routes.checkinConfirmation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Submission failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B5CF6);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Submit Check-in'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
      ),
      body: Consumer<CheckInProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Weight ---
                const _SectionLabel('Current Weight (kg)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 75.5',
                    border: OutlineInputBorder(),
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: 24),

                // --- Mood ---
                const _SectionLabel('Mood'),
                const SizedBox(height: 8),
                _EmojiSlider(
                  value: provider.mood,
                  labels: const ['😔', '😐', '🙂', '😊', '😄'],
                  onChanged: (v) {
                    provider.mood = v;
                    provider.notifyListeners();
                  },
                ),
                const SizedBox(height: 24),

                // --- Energy ---
                const _SectionLabel('Energy'),
                const SizedBox(height: 8),
                _LabelledSlider(
                  value: provider.energy,
                  labels: const [
                    'Very Low',
                    'Low',
                    'Medium',
                    'High',
                    'Very High'
                  ],
                  onChanged: (v) {
                    provider.energy = v;
                    provider.notifyListeners();
                  },
                ),
                const SizedBox(height: 24),

                // --- Sleep ---
                const _SectionLabel('Sleep'),
                const SizedBox(height: 8),
                _LabelledSlider(
                  value: provider.sleep,
                  labels: const [
                    'Poor',
                    'Fair',
                    'Average',
                    'Good',
                    'Excellent'
                  ],
                  onChanged: (v) {
                    provider.sleep = v;
                    provider.notifyListeners();
                  },
                ),
                const SizedBox(height: 24),

                // --- Notes ---
                const _SectionLabel('Notes'),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'How are you feeling this week?',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (v) => provider.notes = v,
                ),
                const SizedBox(height: 24),

                // --- Photos ---
                const _SectionLabel('Progress Photos'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PhotoPicker(
                        label: 'Front',
                        file: provider.photoFront,
                        onPick: () => provider.pickPhoto('front'),
                        onRemove: () => provider.removePhoto('front'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PhotoPicker(
                        label: 'Side',
                        file: provider.photoSide,
                        onPick: () => provider.pickPhoto('side'),
                        onRemove: () => provider.removePhoto('side'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PhotoPicker(
                        label: 'Back',
                        file: provider.photoBack,
                        onPick: () => provider.pickPhoto('back'),
                        onRemove: () => provider.removePhoto('back'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- Submit ---
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: provider.submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      disabledBackgroundColor: purple.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: provider.submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Check-in',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}

// ---------------------------------------------------------------------------
// Emoji slider (mood)
// ---------------------------------------------------------------------------

class _EmojiSlider extends StatelessWidget {
  const _EmojiSlider({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  final double value;
  final List<String> labels;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF7B5CF6),
            inactiveTrackColor: const Color(0xFF2A2B3D),
            thumbColor: const Color(0xFF7B5CF6),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((l) => Text(l, style: const TextStyle(fontSize: 20)))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Labelled slider (energy, sleep)
// ---------------------------------------------------------------------------

class _LabelledSlider extends StatelessWidget {
  const _LabelledSlider({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  final double value;
  final List<String> labels;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final idx = (value.round() - 1).clamp(0, labels.length - 1);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF7B5CF6),
            inactiveTrackColor: const Color(0xFF2A2B3D),
            thumbColor: const Color(0xFF7B5CF6),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
          ),
        ),
        Text(
          labels[idx],
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Photo picker
// ---------------------------------------------------------------------------

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.label,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  final String label;
  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1F2E),
              borderRadius: BorderRadius.circular(12),
              image: file != null
                  ? DecorationImage(
                      image: FileImage(file!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: file == null
                ? const Center(
                    child: Icon(Icons.add_a_photo, color: Colors.white38),
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
