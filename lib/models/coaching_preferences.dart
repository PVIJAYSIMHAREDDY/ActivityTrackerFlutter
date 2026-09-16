class CoachingPreferences {
  final String experience, equipment, recovery, habit;
  final int sessions, minutes;
  final List<String> exclusions;
  final bool pain, medical;
  final DateTime? checkedAt;
  const CoachingPreferences({
    this.experience = 'Beginner',
    this.equipment = 'Bodyweight',
    this.recovery = 'Not checked',
    this.habit = 'Prepare tomorrow’s breakfast',
    this.sessions = 3,
    this.minutes = 30,
    this.exclusions = const [],
    this.pain = false,
    this.medical = false,
    this.checkedAt,
  });
  factory CoachingPreferences.fromMap(Map<String, dynamic> m) {
    String choice(String key, List<String> values, String fallback) =>
        values.contains(m[key]) ? m[key] as String : fallback;
    return CoachingPreferences(
      experience: choice('experience', [
        'Beginner',
        'Intermediate',
        'Experienced',
      ], 'Beginner'),
      equipment: choice('equipment', [
        'Bodyweight',
        'Dumbbells',
        'Gym',
      ], 'Bodyweight'),
      recovery: choice('recovery', [
        'Not checked',
        'Recovered',
        'Tired',
      ], 'Not checked'),
      sessions: ((m['sessions'] as num?)?.toInt() ?? 3).clamp(2, 4),
      minutes: ((m['minutes'] as num?)?.toInt() ?? 30).clamp(20, 60),
      exclusions: (m['exclusions'] as List? ?? []).whereType<String>().toList(),
      pain: m['pain'] == true,
      medical: m['medical'] == true,
      habit: choice('habit', [
        'Prepare tomorrow’s breakfast',
        'Schedule my training days',
        'Log meals consistently',
        'Keep a regular bedtime',
        'Take a short movement break',
      ], 'Prepare tomorrow’s breakfast'),
      checkedAt: DateTime.tryParse(m['checkedAt']?.toString() ?? ''),
    );
  }
  bool fresh(DateTime now) =>
      checkedAt != null &&
      !checkedAt!.isAfter(now) &&
      now.difference(checkedAt!).inDays < 7;
  Map<String, dynamic> toMap() => {
    'experience': experience,
    'equipment': equipment,
    'recovery': recovery,
    'sessions': sessions,
    'minutes': minutes,
    'exclusions': exclusions,
    'pain': pain,
    'medical': medical,
    'habit': habit,
    'checkedAt': checkedAt?.toIso8601String(),
  };
}
