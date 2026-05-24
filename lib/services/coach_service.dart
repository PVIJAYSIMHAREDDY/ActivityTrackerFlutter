import '../models/body_stats_model.dart';

class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String rest;
  final String tip;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.tip,
  });
}

class DayWorkout {
  final String title;
  final String type; // 'strength','cardio','rest','active_recovery'
  final List<Exercise> exercises;
  final String coachNote;

  const DayWorkout({
    required this.title,
    required this.type,
    required this.exercises,
    required this.coachNote,
  });
}

class WeeklyPlan {
  final int weekNumber;
  final String phase;
  final String phaseGoal;
  final List<DayWorkout> days; // 7 days (index 0 = Monday)
  final String nutritionNote;
  final String coachMessage;

  const WeeklyPlan({
    required this.weekNumber,
    required this.phase,
    required this.phaseGoal,
    required this.days,
    required this.nutritionNote,
    required this.coachMessage,
  });
}

class CoachService {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns today's workout based on program start date.
  static DayWorkout getTodayWorkout(BodyStats stats) {
    final week = getCurrentWeek(stats.programStartDate);
    final plan = getWeeklyPlan(week, stats);
    // weekday: 1=Mon ... 7=Sun  →  index 0-6
    final dayIndex = DateTime.now().weekday - 1;
    return plan.days[dayIndex];
  }

  /// Returns the current week number in the 52-week program (clamped 1-52).
  static int getCurrentWeek(DateTime programStart) {
    final now = DateTime.now();
    final diff = now.difference(programStart).inDays;
    final week = (diff ~/ 7) + 1;
    return week.clamp(1, 52);
  }

  /// Returns the phase name for a given week.
  static String getCurrentPhase(int week) {
    if (week <= 12) return 'Foundation';
    if (week <= 24) return 'Hypertrophy';
    if (week <= 36) return 'Strength';
    return 'Peak';
  }

  /// Builds and returns the full weekly plan for a given week number.
  static WeeklyPlan getWeeklyPlan(int week, BodyStats stats) {
    final phase = getCurrentPhase(week);
    switch (phase) {
      case 'Foundation':
        return _foundationWeek(week, stats);
      case 'Hypertrophy':
        return _hypertrophyWeek(week, stats);
      case 'Strength':
        return _strengthWeek(week, stats);
      default:
        return _peakWeek(week, stats);
    }
  }

  /// Returns a coach insight string based on recent weight progress.
  static String getProgressInsight(BodyStats stats) {
    if (stats.weightHistory.length < 2) {
      return 'Log your weight regularly so I can track your progress and fine-tune your plan!';
    }

    final sorted = List<WeightEntry>.from(stats.weightHistory)
      ..sort((a, b) => b.date.compareTo(a.date));

    final latest = sorted[0].weightKg;
    final previous = sorted[1].weightKg;
    final delta = latest - previous;

    switch (stats.goal.toLowerCase()) {
      case 'muscle_gain':
        if (delta.abs() < 0.2) {
          return 'Your weight has been stable. To build muscle effectively, consider adding 100-150 kcal to your daily intake and ensure you\'re hitting your protein target.';
        } else if (delta > 0.5) {
          return 'Great job! You\'re gaining weight — keep lifting heavy and prioritise protein to make sure those are quality gains.';
        } else {
          return 'Solid progress! Small consistent gains over time lead to real muscle. Stay consistent with training and nutrition.';
        }

      case 'fat_loss':
        if (delta < -1.0) {
          return 'You\'re losing weight quickly — more than 1 kg this week. Consider adding around 100 kcal to prevent muscle loss and keep energy levels up.';
        } else if (delta.abs() < 0.2) {
          return 'Weight has stalled. Try dropping calories by 100-150 kcal or adding one extra cardio session this week.';
        } else if (delta < 0) {
          return 'You\'re losing weight at a healthy pace. Keep up the great work — steady fat loss is sustainable fat loss!';
        } else {
          return 'Your weight went up slightly. Review your food tracking and make sure you\'re in a caloric deficit. Small course corrections now prevent bigger plateaus later.';
        }

      case 'recomp':
        if (delta.abs() < 0.3) {
          return 'Body recomposition is working — weight staying stable while you reshape your body is the goal. Trust the process and keep training hard.';
        } else if (delta > 0.3) {
          return 'Slight weight increase during recomp. Ensure calories are at target and you\'re getting enough cardio to balance your training stimulus.';
        } else {
          return 'Minor weight drop — that can be fine during recomp as long as strength is maintained. Focus on performance in the gym.';
        }

      default:
        if (delta.abs() < 0.5) {
          return 'Weight is stable — perfect for your maintenance goal. Keep your current nutrition and training consistent.';
        } else if (delta > 0.5) {
          return 'Weight is trending up slightly. If that\'s not your intention, review your caloric intake and adjust portion sizes.';
        } else {
          return 'Weight is trending down slightly. Make sure you\'re eating enough to fuel your workouts and daily activity.';
        }
    }
  }

  /// Returns an adjusted calorie recommendation based on recent progress.
  static double getAdjustedCalories(BodyStats stats) {
    final base = stats.targetCalories;
    if (stats.weightHistory.length < 2) return base;

    final sorted = List<WeightEntry>.from(stats.weightHistory)
      ..sort((a, b) => b.date.compareTo(a.date));

    final delta = sorted[0].weightKg - sorted[1].weightKg;

    switch (stats.goal.toLowerCase()) {
      case 'muscle_gain':
        if (delta.abs() < 0.2) return base + 125.0;
        return base;

      case 'fat_loss':
        if (delta < -1.0) return base + 100.0;
        if (delta.abs() < 0.2) return base - 125.0;
        return base;

      default:
        return base;
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1 — Foundation (weeks 1-12)
  // Full body 3x/week (Mon/Wed/Fri) + 2 cardio days (Tue/Thu) + rest Sat/Sun
  // ---------------------------------------------------------------------------

  static WeeklyPlan _foundationWeek(int week, BodyStats stats) {
    final fullBody = DayWorkout(
      title: 'Full Body — Foundation',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Barbell Squat',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '90 sec',
          tip: 'Keep chest tall and knees tracking over toes.',
        ),
        Exercise(
          name: 'Deadlift',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '90 sec',
          tip: 'Hip hinge initiated, bar stays close to shins, neutral spine throughout.',
        ),
        Exercise(
          name: 'Barbell Bench Press',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '90 sec',
          tip: 'Retract shoulder blades and lower the bar to mid-chest with control.',
        ),
        Exercise(
          name: 'Overhead Press',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '90 sec',
          tip: 'Brace your core, avoid excessive lumbar extension at the top.',
        ),
        Exercise(
          name: 'Barbell Row',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '90 sec',
          tip: 'Hinge to roughly 45 degrees, pull elbows back past your torso.',
        ),
        Exercise(
          name: 'Pull-ups / Assisted Pull-ups',
          sets: '3 sets',
          reps: '8-12 reps',
          rest: '90 sec',
          tip: 'Start from a dead hang, initiate with shoulder depression before pulling.',
        ),
        Exercise(
          name: 'Plank',
          sets: '3 sets',
          reps: '30-60 sec hold',
          rest: '60 sec',
          tip: 'Squeeze glutes and core simultaneously — no sagging hips.',
        ),
      ],
      coachNote:
          'Week $week — Foundation phase. Focus entirely on movement quality and building motor patterns. Use a weight that feels easy; add 2.5 kg each week.',
    );

    final cardio = DayWorkout(
      title: 'Steady-State Cardio',
      type: 'cardio',
      exercises: const [
        Exercise(
          name: 'Treadmill / Outdoor Walk-Run',
          sets: '1 session',
          reps: '30-40 min at 60-70% max HR',
          rest: 'N/A',
          tip: 'Maintain a conversational pace — you should be able to speak in sentences.',
        ),
      ],
      coachNote:
          'Light to moderate cardio today. Keep heart rate aerobic and enjoy the recovery-promoting blood flow.',
    );

    final rest = DayWorkout(
      title: 'Rest Day',
      type: 'rest',
      exercises: const [],
      coachNote:
          'Active recovery is key. Prioritise 7-9 hours of sleep and stay well hydrated.',
    );

    final activeRecovery = DayWorkout(
      title: 'Active Recovery',
      type: 'active_recovery',
      exercises: const [
        Exercise(
          name: 'Light Walk / Mobility Flow',
          sets: '1 session',
          reps: '20-30 min',
          rest: 'N/A',
          tip: 'Focus on breathing and joint range of motion — no intensity needed.',
        ),
      ],
      coachNote:
          'Keep movement gentle today. Foam rolling and stretching are ideal complements.',
    );

    // Mon=0 Tue=1 Wed=2 Thu=3 Fri=4 Sat=5 Sun=6
    return WeeklyPlan(
      weekNumber: week,
      phase: 'Foundation',
      phaseGoal:
          'Build movement quality, form mastery, and a habit of consistent training.',
      days: [
        fullBody, // Mon
        cardio, // Tue
        fullBody, // Wed
        cardio, // Thu
        fullBody, // Fri
        activeRecovery, // Sat
        rest, // Sun
      ],
      nutritionNote:
          'Eat at your target calories and hit your protein goal every day. Meals rich in whole foods will fuel recovery best.',
      coachMessage:
          'Welcome to Week $week of your Foundation phase! The first 12 weeks are about building an unshakeable base. Patience now = results later.',
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 2 — Hypertrophy (weeks 13-24)
  // Push / Pull / Legs 6x/week, Sunday rest
  // ---------------------------------------------------------------------------

  static WeeklyPlan _hypertrophyWeek(int week, BodyStats stats) {
    final push = DayWorkout(
      title: 'Push Day — Chest, Shoulders, Triceps',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Barbell Bench Press',
          sets: '4 sets',
          reps: '8-12 reps',
          rest: '90 sec',
          tip: 'Control the eccentric — 2-3 seconds down, explosive press up.',
        ),
        Exercise(
          name: 'Incline Dumbbell Press',
          sets: '4 sets',
          reps: '8-12 reps',
          rest: '90 sec',
          tip: 'Set bench to 30-45 degrees; fully stretch the chest at the bottom.',
        ),
        Exercise(
          name: 'Cable Fly',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '60 sec',
          tip: 'Keep a slight elbow bend and focus on the chest squeeze at the midline.',
        ),
        Exercise(
          name: 'Overhead Press',
          sets: '4 sets',
          reps: '8-12 reps',
          rest: '90 sec',
          tip: 'Press in a straight line; avoid flaring elbows excessively.',
        ),
        Exercise(
          name: 'Lateral Raise',
          sets: '4 sets',
          reps: '12-15 reps',
          rest: '60 sec',
          tip: 'Lead with your elbows and keep a slight forward lean to target medial delts.',
        ),
        Exercise(
          name: 'Tricep Pushdown (Cable)',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '60 sec',
          tip: 'Lock elbows at your sides and fully extend on every rep.',
        ),
      ],
      coachNote: 'Week $week — Push day. Progressive overload is king: add weight when you hit the top of the rep range for all sets.',
    );

    final pull = DayWorkout(
      title: 'Pull Day — Back, Biceps',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Deadlift',
          sets: '4 sets',
          reps: '8-10 reps',
          rest: '2 min',
          tip: 'Build tension before you pull — think "leg press the floor away".',
        ),
        Exercise(
          name: 'Pull-up / Weighted Pull-up',
          sets: '4 sets',
          reps: '8-12 reps',
          rest: '90 sec',
          tip: 'Full range of motion — dead hang to chin over bar.',
        ),
        Exercise(
          name: 'Seated Cable Row',
          sets: '4 sets',
          reps: '10-12 reps',
          rest: '90 sec',
          tip: 'Pull to the navel and hold the contraction for 1 second.',
        ),
        Exercise(
          name: 'Face Pull',
          sets: '3 sets',
          reps: '15-20 reps',
          rest: '60 sec',
          tip: 'Pull to eye level with external rotation — great for shoulder health.',
        ),
        Exercise(
          name: 'Barbell Bicep Curl',
          sets: '3 sets',
          reps: '10-12 reps',
          rest: '60 sec',
          tip: 'Eliminate swinging — elbows stay anchored to your sides.',
        ),
        Exercise(
          name: 'Hammer Curl',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '60 sec',
          tip: 'Neutral grip targets the brachialis and brachioradialis for arm thickness.',
        ),
      ],
      coachNote: 'Week $week — Pull day. Focus on the mind-muscle connection. Feel every rep in the target muscle.',
    );

    final legs = DayWorkout(
      title: 'Leg Day — Quads, Hamstrings, Glutes, Calves',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Barbell Squat',
          sets: '4 sets',
          reps: '8-12 reps',
          rest: '2 min',
          tip: 'Break parallel — a half squat is half a result.',
        ),
        Exercise(
          name: 'Leg Press',
          sets: '4 sets',
          reps: '10-12 reps',
          rest: '90 sec',
          tip: 'Feet shoulder-width, lower until quads are parallel to the sled.',
        ),
        Exercise(
          name: 'Romanian Deadlift',
          sets: '4 sets',
          reps: '10-12 reps',
          rest: '90 sec',
          tip: 'Hinge until you feel a stretch in the hamstrings — not a squat.',
        ),
        Exercise(
          name: 'Lying Leg Curl',
          sets: '3 sets',
          reps: '12-15 reps',
          rest: '60 sec',
          tip: 'Control the eccentric phase fully — resist the weight on the way down.',
        ),
        Exercise(
          name: 'Standing Calf Raise',
          sets: '4 sets',
          reps: '15-20 reps',
          rest: '60 sec',
          tip: 'Full range of motion with a 1-second pause at the top.',
        ),
        Exercise(
          name: 'Leg Extension',
          sets: '3 sets',
          reps: '15-20 reps',
          rest: '60 sec',
          tip: 'Great quad isolation finisher — squeeze hard at full extension.',
        ),
      ],
      coachNote: 'Week $week — Leg day. Leg training is where champions are made. Embrace the challenge.',
    );

    final rest = DayWorkout(
      title: 'Rest Day',
      type: 'rest',
      exercises: const [],
      coachNote: 'Full rest. Muscles grow during recovery — honour it.',
    );

    // PPL PPL Rest: Mon=Push, Tue=Pull, Wed=Legs, Thu=Push, Fri=Pull, Sat=Legs, Sun=Rest
    return WeeklyPlan(
      weekNumber: week,
      phase: 'Hypertrophy',
      phaseGoal:
          'Maximise muscle hypertrophy through high volume, progressive overload, and optimal recovery.',
      days: [
        push, // Mon
        pull, // Tue
        legs, // Wed
        push, // Thu
        pull, // Fri
        legs, // Sat
        rest, // Sun
      ],
      nutritionNote:
          'Prioritise protein at every meal. Carbohydrates around your workouts will improve performance and recovery. Stay within your calorie target.',
      coachMessage:
          'Week $week — Hypertrophy phase is all about volume and consistency. Track your lifts and add weight whenever you can.',
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 3 — Strength (weeks 25-36)
  // Upper/Lower 4x/week: Mon=Upper A, Tue=Lower A, Wed=Rest, Thu=Upper B,
  //                       Fri=Lower B, Sat=Active Recovery, Sun=Rest
  // ---------------------------------------------------------------------------

  static WeeklyPlan _strengthWeek(int week, BodyStats stats) {
    final upperA = DayWorkout(
      title: 'Upper A — Heavy Compounds',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Barbell Bench Press',
          sets: '5 sets',
          reps: '5 reps',
          rest: '3 min',
          tip: 'Use 85-90% of 1RM. Brace hard, drive the bar explosively.',
        ),
        Exercise(
          name: 'Overhead Press',
          sets: '4 sets',
          reps: '6 reps',
          rest: '2 min',
          tip: 'Tight core, glutes engaged — press in a vertical line over your base.',
        ),
        Exercise(
          name: 'Weighted Pull-up',
          sets: '4 sets',
          reps: '6 reps',
          rest: '2 min',
          tip: 'Add a belt or hold a dumbbell between your legs; full range of motion.',
        ),
        Exercise(
          name: 'Barbell Row',
          sets: '4 sets',
          reps: '6 reps',
          rest: '2 min',
          tip: 'Keep the lower back flat, pull bar into lower chest/upper abdomen.',
        ),
      ],
      coachNote:
          'Week $week — Upper A. Heavy compound day. If you hit all reps cleanly, add 2.5 kg next session.',
    );

    final upperB = DayWorkout(
      title: 'Upper B — Volume Accessory',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Incline Barbell Press',
          sets: '4 sets',
          reps: '8 reps',
          rest: '90 sec',
          tip: 'Upper chest focus — control the descent and drive explosively.',
        ),
        Exercise(
          name: 'Weighted Dips',
          sets: '4 sets',
          reps: '8 reps',
          rest: '90 sec',
          tip: 'Lean forward slightly for chest emphasis, stay upright for triceps.',
        ),
        Exercise(
          name: 'Seated Cable Row',
          sets: '4 sets',
          reps: '10 reps',
          rest: '90 sec',
          tip: 'Pause at the peak contraction — squeeze the rhomboids.',
        ),
        Exercise(
          name: 'Face Pull',
          sets: '3 sets',
          reps: '15 reps',
          rest: '60 sec',
          tip: 'Shoulder health essential — never skip this one.',
        ),
      ],
      coachNote:
          'Week $week — Upper B. Slightly higher reps to accumulate volume and target weak points.',
    );

    final lowerA = DayWorkout(
      title: 'Lower A — Heavy Squat Focus',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Barbell Back Squat',
          sets: '5 sets',
          reps: '5 reps',
          rest: '3 min',
          tip: 'Brace, squat below parallel, drive knees out throughout the lift.',
        ),
        Exercise(
          name: 'Romanian Deadlift',
          sets: '4 sets',
          reps: '6 reps',
          rest: '2 min',
          tip: 'Load the hamstrings under tension — feel the stretch before reversing.',
        ),
        Exercise(
          name: 'Leg Press',
          sets: '3 sets',
          reps: '10 reps',
          rest: '90 sec',
          tip: 'Supplementary volume for the quads after the main squat work.',
        ),
      ],
      coachNote:
          'Week $week — Lower A. Squat is the primary focus today. Warm up thoroughly before hitting your working weight.',
    );

    final lowerB = DayWorkout(
      title: 'Lower B — Front Squat & Accessory',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Front Squat',
          sets: '4 sets',
          reps: '6 reps',
          rest: '2 min',
          tip: 'Keep elbows high to maintain an upright torso throughout the squat.',
        ),
        Exercise(
          name: 'Hack Squat',
          sets: '4 sets',
          reps: '8 reps',
          rest: '90 sec',
          tip: 'Feet shoulder-width; emphasise a deep range of motion for quad sweep.',
        ),
        Exercise(
          name: 'Lying Leg Curl',
          sets: '4 sets',
          reps: '10 reps',
          rest: '90 sec',
          tip: 'Hamstring isolation is important — control both phases of each rep.',
        ),
      ],
      coachNote:
          'Week $week — Lower B. Front squats challenge quad strength and upper back stability — a great complement to back squats.',
    );

    final rest = DayWorkout(
      title: 'Rest Day',
      type: 'rest',
      exercises: const [],
      coachNote:
          'Full rest. With four training days at this intensity, rest is essential for central nervous system recovery.',
    );

    final activeRecovery = DayWorkout(
      title: 'Active Recovery',
      type: 'active_recovery',
      exercises: const [
        Exercise(
          name: 'Light Walk or Easy Bike',
          sets: '1 session',
          reps: '30-40 min',
          rest: 'N/A',
          tip: 'Keep intensity low — goal is blood flow and mobility, not fitness.',
        ),
      ],
      coachNote:
          'Flush the legs with easy movement. Foam roll hips, quads, and upper back.',
    );

    // Mon=Upper A, Tue=Lower A, Wed=Rest, Thu=Upper B, Fri=Lower B, Sat=Active, Sun=Rest
    return WeeklyPlan(
      weekNumber: week,
      phase: 'Strength',
      phaseGoal:
          'Maximise neuromuscular strength on the big compound lifts through heavy loading and low repetitions.',
      days: [
        upperA, // Mon
        lowerA, // Tue
        rest, // Wed
        upperB, // Thu
        lowerB, // Fri
        activeRecovery, // Sat
        rest, // Sun
      ],
      nutritionNote:
          'Caloric intake is critical for strength gains. Do not under-eat during this phase. Carbs before heavy sessions will noticeably improve performance.',
      coachMessage:
          'Week $week — Strength phase. The numbers on the bar are going up. Trust the programme and add weight methodically.',
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 4 — Peak (weeks 37-52)
  // Advanced PPL with drop sets/supersets Mon-Fri + HIIT Sat + Rest Sun
  // ---------------------------------------------------------------------------

  static WeeklyPlan _peakWeek(int week, BodyStats stats) {
    final push = DayWorkout(
      title: 'Peak Push Day — Drop Sets & Supersets',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Barbell Bench Press (+ drop set on final set)',
          sets: '4 sets',
          reps: '6-8 reps (drop: -20%, 10-12 reps)',
          rest: '2 min',
          tip: 'On the last set, immediately drop 20% weight and push out extra reps.',
        ),
        Exercise(
          name: 'Incline Dumbbell Press — superset with Cable Fly',
          sets: '3 supersets',
          reps: '10 reps + 15 reps',
          rest: '90 sec between supersets',
          tip: 'Minimal rest between the two exercises — push the intensity.',
        ),
        Exercise(
          name: 'Overhead Press (+ drop set on final set)',
          sets: '4 sets',
          reps: '6-8 reps (drop: -20%, 10-12 reps)',
          rest: '2 min',
          tip: 'Controlled tempo on the way down, explosive on the press.',
        ),
        Exercise(
          name: 'Lateral Raise — superset with Arnold Press',
          sets: '3 supersets',
          reps: '15 reps + 10 reps',
          rest: '90 sec',
          tip: 'Fully exhaust the medial and anterior deltoid for that round shoulder look.',
        ),
        Exercise(
          name: 'Tricep Pushdown — superset with Overhead Tricep Extension',
          sets: '3 supersets',
          reps: '12 reps + 12 reps',
          rest: '60 sec',
          tip: 'Both heads of the triceps hit — lockout completely on every rep.',
        ),
      ],
      coachNote:
          'Week $week — Peak phase push day. Intensity is high. Expect a serious pump. Each superset should leave you breathless.',
    );

    final pull = DayWorkout(
      title: 'Peak Pull Day — Drop Sets & Supersets',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Deadlift',
          sets: '4 sets',
          reps: '4-6 reps',
          rest: '3 min',
          tip: 'Heaviest lift of the week — warm up carefully and pull with intent.',
        ),
        Exercise(
          name: 'Weighted Pull-up — superset with Straight-Arm Pulldown',
          sets: '3 supersets',
          reps: '8 reps + 15 reps',
          rest: '90 sec',
          tip: 'The straight-arm pulldown pre-exhausts the lat for a greater contraction during pull-ups.',
        ),
        Exercise(
          name: 'Seated Cable Row (+ drop set on final set)',
          sets: '4 sets',
          reps: '8-10 reps (drop: 15 reps)',
          rest: '90 sec',
          tip: 'Neutral grip; drive elbows back and pinch shoulder blades hard.',
        ),
        Exercise(
          name: 'Barbell Curl — superset with Hammer Curl',
          sets: '3 supersets',
          reps: '10 reps + 12 reps',
          rest: '60 sec',
          tip: 'Back-to-back to fully fatigue the biceps and brachialis.',
        ),
        Exercise(
          name: 'Face Pull',
          sets: '3 sets',
          reps: '20 reps',
          rest: '60 sec',
          tip: 'Non-negotiable for shoulder health — even in the peak phase.',
        ),
      ],
      coachNote:
          'Week $week — Peak pull day. The aim is complete muscle exhaustion. Mind-muscle connection is paramount at this stage.',
    );

    final legs = DayWorkout(
      title: 'Peak Leg Day — Drop Sets & Supersets',
      type: 'strength',
      exercises: const [
        Exercise(
          name: 'Barbell Squat (+ drop set on final set)',
          sets: '4 sets',
          reps: '6-8 reps (drop: -20%, 12 reps)',
          rest: '2-3 min',
          tip: 'The drop set should be brutal — that\'s the point.',
        ),
        Exercise(
          name: 'Leg Press — superset with Leg Extension',
          sets: '3 supersets',
          reps: '12 reps + 20 reps',
          rest: '90 sec',
          tip: 'Superset creates maximum quad pump and time-under-tension.',
        ),
        Exercise(
          name: 'Romanian Deadlift — superset with Lying Leg Curl',
          sets: '3 supersets',
          reps: '10 reps + 15 reps',
          rest: '90 sec',
          tip: 'Both exercises hit hamstrings from different angles for full development.',
        ),
        Exercise(
          name: 'Walking Lunge',
          sets: '3 sets',
          reps: '20 steps (10 each leg)',
          rest: '90 sec',
          tip: 'Long strides for glute emphasis, shorter strides for quad emphasis.',
        ),
        Exercise(
          name: 'Standing Calf Raise (+ drop set on final set)',
          sets: '4 sets',
          reps: '15 reps (drop: 20 reps)',
          rest: '60 sec',
          tip: 'Calves respond to both volume and stretch — full ROM every rep.',
        ),
      ],
      coachNote:
          'Week $week — Peak leg day. This is the most demanding leg session of the programme. Fuel well and hydrate.',
    );

    final hiit = DayWorkout(
      title: 'HIIT Cardio — Conditioning & Definition',
      type: 'cardio',
      exercises: const [
        Exercise(
          name: 'Warm-up Jog',
          sets: '1 session',
          reps: '5 min easy pace',
          rest: 'N/A',
          tip: 'Get the heart rate up gradually before the intervals begin.',
        ),
        Exercise(
          name: 'Sprint Intervals',
          sets: '10 rounds',
          reps: '30 sec sprint : 30 sec walk',
          rest: '30 sec walk between rounds',
          tip: 'Each sprint should be at 90%+ effort — all-out, not a jog.',
        ),
        Exercise(
          name: 'Cool-down Walk',
          sets: '1 session',
          reps: '5-10 min',
          rest: 'N/A',
          tip: 'Bring heart rate below 100 BPM before stretching.',
        ),
      ],
      coachNote:
          'HIIT day. This session torches calories and improves cardiovascular conditioning. Push hard for 20 minutes total work.',
    );

    final rest = DayWorkout(
      title: 'Rest Day',
      type: 'rest',
      exercises: const [],
      coachNote:
          'Full rest. You\'ve worked incredibly hard this week. Let the body recover, rebuild, and come back stronger.',
    );

    final activeRecovery = DayWorkout(
      title: 'Active Recovery',
      type: 'active_recovery',
      exercises: const [
        Exercise(
          name: 'Yoga or Mobility Flow',
          sets: '1 session',
          reps: '30-45 min',
          rest: 'N/A',
          tip: 'Focus on hip flexors, thoracic spine, and hamstrings after heavy leg and pull days.',
        ),
      ],
      coachNote:
          'Deliberate mobility work in the peak phase accelerates recovery and keeps joints healthy under heavy load.',
    );

    // Mon=Push, Tue=Pull, Wed=Legs, Thu=Push, Fri=Pull, Sat=HIIT, Sun=Rest
    // Week offsets to alternate push/pull/legs ordering
    final isEvenBlock = ((week - 37) ~/ 2) % 2 == 0;
    return WeeklyPlan(
      weekNumber: week,
      phase: 'Peak',
      phaseGoal:
          'Maximise muscle definition, conditioning, and athletic performance. The final culmination of 9 months of work.',
      days: [
        isEvenBlock ? push : legs, // Mon
        isEvenBlock ? pull : push, // Tue
        isEvenBlock ? legs : pull, // Wed
        activeRecovery, // Thu — recovery mid-week
        isEvenBlock ? push : legs, // Fri
        hiit, // Sat
        rest, // Sun
      ],
      nutritionNote:
          'Dial in your nutrition in the peak phase. Clean carb sources around training, lean protein at every meal, and reduced processed foods.',
      coachMessage:
          'Week $week — Peak phase. You are in the final stretch of your transformation. Every session counts. Give it everything.',
    );
  }
}
