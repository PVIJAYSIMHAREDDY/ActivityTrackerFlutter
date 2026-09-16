import '../models/body_stats_model.dart';
import '../models/goal_model.dart';
import '../models/coaching_preferences.dart';
import 'meal_planner.dart';
import 'coaching_knowledge.dart';

class AdaptivePlan {
  final BodyStats stats;
  final List<String> reasons, workouts;
  final List<MealDay> mealDays;
  final String diet, phase;
  final CoachingPreferences preferences;
  final bool needsReview;
  final DateTime generatedAt;
  AdaptivePlan(
    this.stats,
    this.reasons,
    this.mealDays,
    this.workouts,
    this.diet,
    this.phase,
    this.preferences,
    this.needsReview,
    this.generatedAt,
  );
  List<String> get meals =>
      mealDays.map((d) => d.display(stats.units)).toList();
  List<String> get shopping => MealPlanner.shopping(mealDays, stats.units);
  List<String> get review => [
    'This week’s action: ${preferences.habit}. Choose a time and place; if you miss it, resume at the next opportunity.',
    'Check in weekly: how manageable was the plan, what got in the way, and how was recovery? Update your body profile and linked goal using consistent measurements.',
    'Training progression is an app rule: fresh recovered check-in plus consistent logged strength days can increase sets, never automatic weight increases. Tiredness reduces volume. A completed linked goal selects maintenance.',
    'Nutrition uses the existing body-profile energy equation; meal macros are illustrative rounded estimates, not laboratory or brand-specific values. Compare food labels and adjust with a dietitian when needed.',
  ];
  List<String> lines(String type) => [
    'Activity Tracker — ${type == "full" ? "Diet and workout" : type} coaching plan',
    'Generated: ${generatedAt.toIso8601String().substring(0, 10)} | $phase',
    'Profile: ${stats.units.weight(stats.weightKg)}; height: ${stats.units.height(stats.heightCm)}; objective: ${stats.goal}; diet: $diet',
    'Assessment: ${preferences.experience}; ${preferences.equipment}; ${preferences.minutes}-minute sessions. Excluded ingredient groups: ${preferences.exclusions.isEmpty ? "none selected" : preferences.exclusions.join(", ")}.',
    ...reasons,
    'Educational software informed by selected ISSA textbook principles. Not an ISSA certification, medical assessment or individualized treatment.',
    if (needsReview)
      'Personalized meal and exercise prescriptions are paused. Discuss symptoms or condition-specific restrictions with a qualified professional; use this assessment summary for that conversation.',
    if (!needsReview && type != 'workout') ...[
      'Daily nutrition targets',
      '${stats.units.energy(stats.targetCalories)}; protein ${stats.units.food(stats.targetProtein)}; carbohydrate ${stats.units.food(stats.targetCarbs)}; fat ${stats.units.food(stats.targetFat)}',
      'Weekly meal plan',
      'All portions are ${stats.units.foodUnit} of edible food in the state listed. Estimated meal totals can differ from macro targets. Check ingredient labels and cross-contact risks for allergies.',
      ...meals,
      'Weekly shopping list',
      ...shopping,
    ],
    if (!needsReview && type != 'nutrition') ...[
      'Weekly workout plan',
      ...workouts,
    ],
    'Weekly coaching review',
    ...review,
    'Source notes',
    ...CoachingKnowledge.references.map((r) => '${r.citation}. ${r.principle}'),
    'General activity reference: CDC Adult Activity Overview — https://www.cdc.gov/physical-activity-basics/guidelines/adults.html. Build toward general activity guidelines as ability permits; this starting plan may be below them.',
  ];
}

class AdaptivePlanService {
  static AdaptivePlan generate(
    BodyStats stats, {
    GoalModel? goal,
    String diet = 'Vegetarian',
    CoachingPreferences? preferences,
    int? recentStrengthDays,
    DateTime? now,
  }) {
    if (!['Vegetarian', 'Mixed diet', 'Vegan'].contains(diet)) {
      throw ArgumentError('Unknown diet');
    }
    if (stats.age < 18 ||
        stats.age > 120 ||
        !stats.weightKg.isFinite ||
        stats.weightKg <= 0 ||
        !stats.heightCm.isFinite ||
        stats.heightCm <= 0 ||
        !stats.targetCalories.isFinite ||
        stats.targetCalories <= 0) {
      throw ArgumentError('Plans require a valid adult body profile.');
    }
    final date = now ?? DateTime.now();
    final prefs =
        preferences ??
        CoachingPreferences(
          sessions: stats.activityLevel == 'sedentary' ? 2 : 3,
        );
    final complete =
        goal != null &&
        goal.category.toLowerCase() == 'fitness' &&
        goal.targetValue.isFinite &&
        goal.currentValue.isFinite &&
        goal.targetValue > 0 &&
        goal.isComplete;
    final effective = complete ? stats.copyWith(goal: 'maintain') : stats;
    final fresh = prefs.fresh(date);
    final tired = fresh && prefs.recovery == 'Tired';
    final review = prefs.pain || prefs.medical;
    final sessions = complete
        ? 2
        : prefs.sessions.clamp(2, prefs.experience == 'Beginner' ? 3 : 4);
    final ready =
        fresh &&
        prefs.recovery == 'Recovered' &&
        recentStrengthDays != null &&
        recentStrengthDays >= sessions;
    final sets = tired
        ? 1
        : ready && !complete
        ? 3
        : 2;
    final phase = review
        ? 'Professional review needed'
        : complete
        ? 'Maintenance'
        : tired
        ? 'Recovery week'
        : ready
        ? 'Build consistency and capacity'
        : 'Foundation and assessment';
    final reasons = <String>[
      'Nutrition estimates recalculated from your latest saved weight, activity level and fitness objective.',
      if (goal != null)
        'Linked goal: ${goal.title} (${goal.currentValue}/${goal.targetValue}).',
      if (complete)
        'Goal reached: maintenance nutrition and two strength sessions.'
      else
        'Working toward ${stats.goal}: $sessions strength sessions matched to your assessment.',
      if (goal == null)
        'No fitness goal linked. Select one to enable the maintenance transition.',
      if (recentStrengthDays != null)
        '$recentStrengthDays distinct strength-training days logged in the previous seven completed days. Missing logs do not prove inactivity.',
      if (!fresh)
        'Weekly recovery check-in is missing or older than seven days: hold the starting workload.',
      if (tired)
        'You reported tiredness: reduce to one set per movement and defer progression.',
      if (ready && !complete)
        'Recent strength consistency and a recovered check-in support three sets; keep resistance controlled and leave repetitions in reserve.',
      weightInsight(stats, date),
      if (review)
        'Your assessment reports pain or a condition needing individualized guidance. Automatic prescriptions are paused.',
    ];
    final days = review
        ? <MealDay>[]
        : MealPlanner.generate(
            effective.targetCalories,
            effective.targetProtein,
            diet,
            prefs.exclusions,
          );
    final strengthDays = sessions == 2
        ? [0, 3]
        : sessions == 3
        ? [0, 2, 4]
        : [0, 1, 3, 4];
    List<String> exercises(int day) {
      final upper = sessions == 4 && (day == 1 || day == 4);
      final lower = sessions == 4 && !upper;
      final squat = prefs.equipment == 'Bodyweight'
          ? 'Chair squat — sit back toward a stable chair, knees follow toes'
          : 'Goblet squat — hold a manageable dumbbell close, use a comfortable depth';
      final hinge = prefs.equipment == 'Bodyweight'
          ? 'Glute bridge — lift hips without arching the lower back'
          : 'Dumbbell Romanian deadlift — hinge at hips, keep weights close';
      final push = prefs.equipment == 'Bodyweight'
          ? 'Wall push-up — keep a straight body, bring chest toward wall'
          : 'Dumbbell floor press — lower with control, wrists above elbows';
      final pull = prefs.equipment == 'Gym'
          ? 'Seated cable row — draw elbows back without swinging'
          : prefs.equipment == 'Dumbbells'
          ? 'Supported dumbbell row — support torso, pull elbow toward hip'
          : 'Prone W raise — lift arms gently with thumbs up; a light movement drill, not a loaded row';
      final list = lower
          ? [
              squat,
              hinge,
              'Supported calf raise — use stable support',
              'Dead bug — alternate limbs without arching back',
            ]
          : upper
          ? [
              push,
              pull,
              'Wall slide — move within a comfortable range',
              'Dead bug — alternate limbs without arching back',
            ]
          : [
              squat,
              push,
              pull,
              hinge,
              'Dead bug — alternate limbs without arching back',
            ];
      return list.take(prefs.minutes <= 20 ? 3 : list.length).toList();
    }

    final workouts = review
        ? <String>[]
        : List.generate(7, (i) {
            final day = MealPlanner.days[i];
            if (!strengthDays.contains(i)) {
              return '$day: ${i == 6 ? "Rest and comfortable mobility" : "Optional easy walking or cycling for ${tired ? 10 : 20} minutes; choose a conversational pace"}.';
            }
            final pattern = sessions == 4
                ? ((i == 1 || i == 4)
                      ? 'Upper-body strength'
                      : 'Lower-body strength')
                : 'Full-body strength';
            return '$day: $pattern — up to ${prefs.minutes} minutes. Warm up with 5 minutes of comfortable movement; finish with easy movement.\n${exercises(i).map((e) => "$e: $sets sets of 8–12 controlled repetitions, rest 60–90 seconds. Stop before technique deteriorates.").join("\n")}\nIf time runs out, finish fewer movements rather than rush. Stop painful movements; do not push through symptoms.';
          });
    return AdaptivePlan(
      effective,
      reasons,
      days,
      workouts,
      diet,
      phase,
      prefs,
      review,
      date,
    );
  }

  static String weightInsight(BodyStats stats, DateTime now) {
    final daily = <String, WeightEntry>{};
    for (final w in stats.weightHistory) {
      if (w.weightKg.isFinite && w.weightKg > 0 && !w.date.isAfter(now)) {
        final key = '${w.date.year}-${w.date.month}-${w.date.day}';
        if (!daily.containsKey(key) || w.date.isAfter(daily[key]!.date)) {
          daily[key] = w;
        }
      }
    }
    final recent = daily.values
        .where((w) => now.difference(w.date).inDays < 7)
        .toList();
    final prior = daily.values
        .where(
          (w) =>
              now.difference(w.date).inDays >= 7 &&
              now.difference(w.date).inDays < 14,
        )
        .toList();
    if (recent.length < 3 || prior.length < 3) {
      return 'Weight trend: at least three separate measurement days in each of two weeks are needed. No plateau or calorie-cut conclusion from isolated weigh-ins.';
    }
    double mean(List<WeightEntry> entries) =>
        entries.fold<double>(0, (s, w) => s + w.weightKg) / entries.length;
    final delta = mean(recent) - mean(prior);
    return 'Weight trend: weekly average changed ${delta >= 0 ? "+" : ""}${stats.units.weight(delta, decimals: 2)}. Review this with intake, training and recovery; this observation alone does not change calories.';
  }
}
