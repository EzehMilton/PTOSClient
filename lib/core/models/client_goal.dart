enum ClientGoal {
  weightLoss,
  muscleGain,
  strength,
  endurance,
  generalFitness,
}

extension ClientGoalX on ClientGoal {
  String get backendValue {
    switch (this) {
      case ClientGoal.weightLoss:
        return 'WEIGHT_LOSS';
      case ClientGoal.muscleGain:
        return 'MUSCLE_GAIN';
      case ClientGoal.strength:
        return 'STRENGTH';
      case ClientGoal.endurance:
        return 'ENDURANCE';
      case ClientGoal.generalFitness:
        return 'GENERAL_FITNESS';
    }
  }

  String get label {
    switch (this) {
      case ClientGoal.weightLoss:
        return 'Weight loss';
      case ClientGoal.muscleGain:
        return 'Muscle gain';
      case ClientGoal.strength:
        return 'Strength';
      case ClientGoal.endurance:
        return 'Endurance';
      case ClientGoal.generalFitness:
        return 'General fitness';
    }
  }
}

ClientGoal? clientGoalFromBackend(String? raw) {
  final normalized = raw?.trim().toUpperCase();
  for (final goal in ClientGoal.values) {
    if (goal.backendValue == normalized) {
      return goal;
    }
  }
  return null;
}

String clientGoalLabel(String? raw) {
  final goal = clientGoalFromBackend(raw);
  return goal?.label ?? raw ?? '-';
}
