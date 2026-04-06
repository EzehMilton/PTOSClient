import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import 'profile_provider.dart';

// ---- Label helpers --------------------------------------------------------

const _goalOptions = {
  'WEIGHT_LOSS': 'Weight Loss',
  'MUSCLE_GAIN': 'Muscle Gain',
  'STRENGTH': 'Strength',
  'ENDURANCE': 'Endurance',
  'GENERAL_FITNESS': 'General Fitness',
};

const _experienceOptions = {
  'BEGINNER': 'Beginner',
  'INTERMEDIATE': 'Intermediate',
  'ADVANCED': 'Advanced',
};

String _goalLabel(String? raw) =>
    _goalOptions[raw?.toUpperCase()] ?? raw ?? '-';

String _experienceLabel(String? raw) =>
    _experienceOptions[raw?.toUpperCase()] ?? raw ?? '-';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;

  // Text controllers – initialised when entering edit mode.
  final _ageCtr = TextEditingController();
  final _heightCtr = TextEditingController();
  final _weightCtr = TextEditingController();
  final _targetWeightCtr = TextEditingController();
  final _injuriesCtr = TextEditingController();
  final _dietaryCtr = TextEditingController();
  final _notesCtr = TextEditingController();
  String? _goalType;
  String? _experience;

  @override
  void initState() {
    super.initState();
    context.read<ProfileProvider>().loadProfile();
  }

  @override
  void dispose() {
    _ageCtr.dispose();
    _heightCtr.dispose();
    _weightCtr.dispose();
    _targetWeightCtr.dispose();
    _injuriesCtr.dispose();
    _dietaryCtr.dispose();
    _notesCtr.dispose();
    super.dispose();
  }

  void _enterEdit() {
    final p = context.read<ProfileProvider>().profile;
    _ageCtr.text = '${p['age'] ?? ''}';
    _heightCtr.text = '${p['height'] ?? ''}';
    _weightCtr.text = '${p['currentWeight'] ?? ''}';
    _targetWeightCtr.text = '${p['targetWeight'] ?? ''}';
    _injuriesCtr.text = p['injuries'] as String? ?? '';
    _dietaryCtr.text = p['dietaryPreferences'] as String? ?? '';
    _notesCtr.text = p['notes'] as String? ?? '';
    _goalType = (p['goalType'] as String?)?.toUpperCase();
    _experience = (p['trainingExperience'] as String?)?.toUpperCase();
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    final updates = <String, dynamic>{
      'age': int.tryParse(_ageCtr.text.trim()),
      'height': double.tryParse(_heightCtr.text.trim()),
      'currentWeight': double.tryParse(_weightCtr.text.trim()),
      'targetWeight': double.tryParse(_targetWeightCtr.text.trim()),
      'goalType': _goalType,
      'trainingExperience': _experience,
      'injuries': _injuriesCtr.text.trim(),
      'dietaryPreferences': _dietaryCtr.text.trim(),
      'notes': _notesCtr.text.trim(),
    };

    final ok = await provider.saveProfile(updates);
    if (!mounted) return;

    if (ok) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Save failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.home),
        ),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit profile',
              onPressed: _enterEdit,
            ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.profile.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: provider.loadProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_editing) {
            return _EditBody(
              provider: provider,
              ageCtr: _ageCtr,
              heightCtr: _heightCtr,
              weightCtr: _weightCtr,
              targetWeightCtr: _targetWeightCtr,
              injuriesCtr: _injuriesCtr,
              dietaryCtr: _dietaryCtr,
              notesCtr: _notesCtr,
              goalType: _goalType,
              experience: _experience,
              onGoalChanged: (v) => setState(() => _goalType = v),
              onExperienceChanged: (v) => setState(() => _experience = v),
              onSave: _save,
              onCancel: _cancelEdit,
            );
          }

          return _DisplayBody(profile: provider.profile);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Display mode
// ---------------------------------------------------------------------------

class _DisplayBody extends StatelessWidget {
  const _DisplayBody({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final fullName = profile['fullName'] as String? ?? '';
    final email = profile['email'] as String? ?? '';
    final initials = _initials(fullName);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Avatar + name + email
          _AvatarHeader(initials: initials, name: fullName, email: email),
          const SizedBox(height: 24),

          // Details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1F2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _ReadRow('Age', _fmt(profile['age'])),
                _ReadRow('Height', _fmtUnit(profile['height'], 'cm')),
                _ReadRow(
                    'Current Weight', _fmtUnit(profile['currentWeight'], 'kg')),
                _ReadRow('Goal', _goalLabel(profile['goalType'] as String?)),
                _ReadRow(
                    'Target Weight', _fmtUnit(profile['targetWeight'], 'kg')),
                _ReadRow('Experience',
                    _experienceLabel(profile['trainingExperience'] as String?)),
                _ReadRow(
                    'Injuries / Conditions', profile['injuries'] as String?),
                _ReadRow(
                    'Dietary Preferences', profile['dietaryPreferences'] as String?),
                _ReadRow('Notes', profile['notes'] as String?, last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _fmt(dynamic v) => v?.toString() ?? '-';

  String _fmtUnit(dynamic v, String unit) {
    if (v == null) return '-';
    if (v is num) return '${v.toStringAsFixed(1)} $unit';
    return '$v $unit';
  }
}

// ---------------------------------------------------------------------------
// Avatar header
// ---------------------------------------------------------------------------

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({
    required this.initials,
    required this.name,
    required this.email,
  });

  final String initials;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B5CF6);

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: purple.withValues(alpha: 0.2),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: purple,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Read-only row
// ---------------------------------------------------------------------------

class _ReadRow extends StatelessWidget {
  const _ReadRow(this.label, this.value, {this.last = false});

  final String label;
  final String? value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value ?? '-',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Edit mode
// ---------------------------------------------------------------------------

class _EditBody extends StatelessWidget {
  const _EditBody({
    required this.provider,
    required this.ageCtr,
    required this.heightCtr,
    required this.weightCtr,
    required this.targetWeightCtr,
    required this.injuriesCtr,
    required this.dietaryCtr,
    required this.notesCtr,
    required this.goalType,
    required this.experience,
    required this.onGoalChanged,
    required this.onExperienceChanged,
    required this.onSave,
    required this.onCancel,
  });

  final ProfileProvider provider;
  final TextEditingController ageCtr;
  final TextEditingController heightCtr;
  final TextEditingController weightCtr;
  final TextEditingController targetWeightCtr;
  final TextEditingController injuriesCtr;
  final TextEditingController dietaryCtr;
  final TextEditingController notesCtr;
  final String? goalType;
  final String? experience;
  final ValueChanged<String?> onGoalChanged;
  final ValueChanged<String?> onExperienceChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B5CF6);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditField(label: 'Age', controller: ageCtr, keyboard: TextInputType.number),
          _EditField(
              label: 'Height (cm)',
              controller: heightCtr,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),
          _EditField(
              label: 'Current Weight (kg)',
              controller: weightCtr,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),

          // Goal dropdown
          const SizedBox(height: 6),
          const _FieldLabel('Goal'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _goalOptions.containsKey(goalType) ? goalType : null,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            dropdownColor: const Color(0xFF1E1F2E),
            items: _goalOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: onGoalChanged,
          ),
          const SizedBox(height: 14),

          _EditField(
              label: 'Target Weight (kg)',
              controller: targetWeightCtr,
              keyboard: const TextInputType.numberWithOptions(decimal: true)),

          // Experience dropdown
          const _FieldLabel('Experience Level'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _experienceOptions.containsKey(experience) ? experience : null,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            dropdownColor: const Color(0xFF1E1F2E),
            items: _experienceOptions.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: onExperienceChanged,
          ),
          const SizedBox(height: 14),

          _EditField(
              label: 'Injuries / Conditions',
              controller: injuriesCtr,
              maxLines: 2),
          _EditField(
              label: 'Dietary Preferences',
              controller: dietaryCtr,
              maxLines: 2),
          _EditField(label: 'Notes', controller: notesCtr, maxLines: 3),

          const SizedBox(height: 8),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: provider.saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                disabledBackgroundColor: purple.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: provider.saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),

          // Cancel button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: provider.saving ? null : onCancel,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Field label
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit field (text)
// ---------------------------------------------------------------------------

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    this.keyboard,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
