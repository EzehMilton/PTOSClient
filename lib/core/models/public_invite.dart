class PublicInvite {
  const PublicInvite({
    required this.token,
    required this.ptName,
    this.clientEmail,
    this.clientFullName,
  });

  final String token;
  final String ptName;
  final String? clientEmail;
  final String? clientFullName;

  factory PublicInvite.fromJson(
    Map<String, dynamic> json, {
    required String fallbackToken,
  }) {
    return PublicInvite(
      token: _readString(json, const [
            'token',
            'inviteToken',
          ]) ??
          fallbackToken,
      ptName: _readString(json, const [
            'ptName',
            'trainerName',
            'personalTrainerName',
            'coachName',
            'inviterName',
          ]) ??
          'Your PT',
      clientEmail: _readString(json, const [
        'clientEmail',
        'invitedClientEmail',
        'email',
      ]),
      clientFullName: _readString(json, const [
        'clientFullName',
        'fullName',
        'name',
      ]),
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
