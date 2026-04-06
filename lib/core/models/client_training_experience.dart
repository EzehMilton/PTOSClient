enum ClientTrainingExperience {
  beginner,
  intermediate,
  advanced,
}

extension ClientTrainingExperienceX on ClientTrainingExperience {
  String get backendValue {
    switch (this) {
      case ClientTrainingExperience.beginner:
        return 'BEGINNER';
      case ClientTrainingExperience.intermediate:
        return 'INTERMEDIATE';
      case ClientTrainingExperience.advanced:
        return 'ADVANCED';
    }
  }

  String get label {
    switch (this) {
      case ClientTrainingExperience.beginner:
        return 'Beginner';
      case ClientTrainingExperience.intermediate:
        return 'Intermediate';
      case ClientTrainingExperience.advanced:
        return 'Advanced';
    }
  }
}

ClientTrainingExperience? clientTrainingExperienceFromBackend(String? raw) {
  final normalized = raw?.trim().toUpperCase();
  for (final value in ClientTrainingExperience.values) {
    if (value.backendValue == normalized) {
      return value;
    }
  }
  return null;
}

String clientTrainingExperienceLabel(String? raw) {
  final experience = clientTrainingExperienceFromBackend(raw);
  return experience?.label ?? raw ?? '-';
}
