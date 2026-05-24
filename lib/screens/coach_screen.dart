import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/coach_service.dart';
import '../models/body_stats_model.dart';
import '../screens/body_stats_screen.dart';
import '../screens/ai_coach_chat_screen.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  BodyStats? _stats;
  DayWorkout? _todayWorkout;
  WeeklyPlan? _weeklyPlan;
  String? _progressInsight;
  bool _loading = true;

  // Tracks which exercise's form tip is expanded
  final Set<int> _expandedExercises = {};

  // Tracks which day's workout is expanded in the weekly split
  int? _expandedDay;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final stats = await BodyStats.load();
    DayWorkout? todayWorkout;
    WeeklyPlan? weeklyPlan;
    String? insight;

    if (stats != null) {
      todayWorkout = CoachService.getTodayWorkout(stats);
      final week = CoachService.getCurrentWeek(stats.programStartDate);
      weeklyPlan = CoachService.getWeeklyPlan(week, stats);
      insight = CoachService.getProgressInsight(stats);
    }

    if (mounted) {
      setState(() {
        _stats = stats;
        _todayWorkout = todayWorkout;
        _weeklyPlan = weeklyPlan;
        _progressInsight = insight;
        _loading = false;
      });
    }
  }

  void _openBodyStats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BodyStatsScreen()),
    ).then((_) => _loadData());
  }

  // ── Phase helpers ────────────────────────────────────────────────────────────

  int _currentWeek(BodyStats stats) {
    final diff = DateTime.now().difference(stats.programStartDate).inDays;
    final week = (diff / 7).floor() + 1;
    return week.clamp(1, 52);
  }

  _PhaseInfo _phaseForWeek(int week) {
    if (week <= 12) {
      return const _PhaseInfo(
        number: 1,
        name: 'Foundation',
        weekRange: 'Wk 1–12',
        description: 'Foundation Phase: Building base strength and technique',
        expectedResult: 'Expected: +3–5 kg lean mass',
      );
    } else if (week <= 24) {
      return const _PhaseInfo(
        number: 2,
        name: 'Hypertrophy',
        weekRange: 'Wk 13–24',
        description: 'Hypertrophy Phase: Building maximum muscle mass',
        expectedResult: 'Expected: +4–6 kg muscle',
      );
    } else if (week <= 36) {
      return const _PhaseInfo(
        number: 3,
        name: 'Strength',
        weekRange: 'Wk 25–36',
        description: 'Strength Phase: Maximising force output and density',
        expectedResult: 'Expected: +15–25% strength increase',
      );
    } else {
      return const _PhaseInfo(
        number: 4,
        name: 'Peak',
        weekRange: 'Wk 37–52',
        description: 'Peak Phase: Refining physique and performance',
        expectedResult: 'Expected: Competition-ready conditioning',
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  void _openAiCoach() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiCoachChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAiCoach,
        backgroundColor: AppColors.navy,
        icon: const Icon(Icons.psychology, color: Colors.white),
        label: const Text('Ask AI Coach', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.navy),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.navy,
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  if (_stats == null) _buildSetupBanner(),
                  if (_stats != null) ...[
                    _buildPhaseBanner(),
                    const SizedBox(height: 16),
                    _buildCoachMessageCard(),
                    const SizedBox(height: 16),
                    _buildTodayWorkoutCard(),
                    const SizedBox(height: 16),
                    _buildNutritionCard(),
                    const SizedBox(height: 16),
                    _buildWeeklySplitCard(),
                    const SizedBox(height: 16),
                    if (_progressInsight != null) _buildProgressInsightCard(),
                    if (_progressInsight != null) const SizedBox(height: 16),
                    _buildRoadmapCard(),
                    const SizedBox(height: 16),
                    _buildSupplementCard(),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
    );
  }

  // ── Setup Banner ─────────────────────────────────────────────────────────────

  Widget _buildSetupBanner() {
    return GestureDetector(
      onTap: _openBodyStats,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orange, Color(0xFFE67E22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set up your body profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Personalise your plan to get started  →',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Phase Banner ─────────────────────────────────────────────────────────────

  Widget _buildPhaseBanner() {
    final stats = _stats!;
    final week = _currentWeek(stats);
    final phase = _phaseForWeek(week);
    final progress = (week / 52.0).clamp(0.0, 1.0);
    final weeksLeft = 52 - week;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Phase ${phase.number}: ${phase.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Week $week of 52',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            phase.description,
            style:
                TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% complete',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  Text(
                    '$weeksLeft weeks to go',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Today's Coach Message ────────────────────────────────────────────────────

  Widget _buildCoachMessageCard() {
    final workout = _todayWorkout;
    final message = workout?.coachNote ??
        'Great work staying consistent! Every session brings you closer to your goal. Focus on form today and give it your best.';

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              const Text(
                'Coach Says',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.navy.withOpacity(0.12)),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.55,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's Workout ──────────────────────────────────────────────────────────

  Widget _buildTodayWorkoutCard() {
    final workout = _todayWorkout;

    if (workout == null) {
      return _sectionCard(
        child: Column(
          children: [
            const Icon(Icons.fitness_center, color: AppColors.muted, size: 40),
            const SizedBox(height: 8),
            const Text("No workout scheduled",
                style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }

    final isRest = workout.type == 'rest' || workout.type == 'active_recovery';
    final typeColor = _workoutTypeColor(workout.type);

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isRest ? Icons.self_improvement : Icons.fitness_center,
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  workout.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  workout.type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isRest) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Recovery Day',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.green,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._restDaySuggestions().map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              size: 14, color: AppColors.green),
                          const SizedBox(width: 6),
                          Text(s,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textDark)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...List.generate(
              workout.exercises.length,
              (i) => _buildExerciseTile(workout.exercises[i], i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseTile(Exercise exercise, int index) {
    final isExpanded = _expandedExercises.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedExercises.remove(index);
                } else {
                  _expandedExercises.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${exercise.sets} sets × ${exercise.reps}  ·  Rest ${exercise.rest}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  if (exercise.tip.isNotEmpty)
                    Icon(
                      isExpanded
                          ? Icons.expand_less
                          : Icons.info_outline,
                      color: AppColors.blue,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
          if (isExpanded && exercise.tip.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      size: 14, color: AppColors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exercise.tip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<String> _restDaySuggestions() => [
        '10–15 min light walk or cycling',
        'Full-body foam rolling (10 min)',
        'Hip flexor & chest opener stretches',
        'Neck, shoulder, and lower back mobility',
        'Hydrate well — aim for 3 litres',
      ];

  // ── Nutrition Card ───────────────────────────────────────────────────────────

  Widget _buildNutritionCard() {
    final stats = _stats!;
    final calories = stats.targetCalories;
    final protein = stats.targetProtein;
    final carbs = stats.targetCarbs;
    final fat = stats.targetFat;
    final totalMacroGrams = protein + carbs + fat;
    final proteinPct = totalMacroGrams > 0
        ? ((protein / totalMacroGrams) * 100).round()
        : 30;
    final carbsPct = totalMacroGrams > 0
        ? ((carbs / totalMacroGrams) * 100).round()
        : 45;
    final fatPct = totalMacroGrams > 0
        ? ((fat / totalMacroGrams) * 100).round()
        : 25;

    final isRestDay = _todayWorkout?.type == 'rest' || _todayWorkout?.type == 'active_recovery';

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_outlined,
                    color: AppColors.orange, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                "Today's Nutrition Targets",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calorie target
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.orange.withOpacity(0.12),
                  AppColors.orange.withOpacity(0.04)
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Target Calories',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${calories.round()} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Macro rings row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroRing(
                label: 'Protein',
                grams: protein.round(),
                pct: proteinPct,
                color: AppColors.blue,
              ),
              _buildMacroRing(
                label: 'Carbs',
                grams: carbs.round(),
                pct: carbsPct,
                color: AppColors.orange,
              ),
              _buildMacroRing(
                label: 'Fat',
                grams: fat.round(),
                pct: fatPct,
                color: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),

          // Meal timing
          const Text(
            'Meal Timing Tips',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          if (!isRestDay) ...[
            _buildMealTip(
              icon: '⚡',
              label: 'Pre-workout (1–2 hrs before)',
              detail: '40g carbs + 20g protein — e.g. rice + chicken',
              color: AppColors.blue,
            ),
            const SizedBox(height: 6),
            _buildMealTip(
              icon: '💪',
              label: 'Post-workout (within 30 min)',
              detail: '50g carbs + 30g protein — e.g. oats + shake',
              color: AppColors.green,
            ),
          ] else ...[
            _buildMealTip(
              icon: '🥗',
              label: 'Rest day eating',
              detail: 'Slightly lower carbs, same protein. Focus on veggies.',
              color: AppColors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroRing({
    required String label,
    required int grams,
    required int pct,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: CircularProgressIndicator(
                value: pct / 100.0,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 7,
              ),
            ),
            Column(
              children: [
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${grams}g',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildMealTip({
    required String icon,
    required String label,
    required String detail,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: color,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly Split Card ────────────────────────────────────────────────────────

  Widget _buildWeeklySplitCard() {
    final plan = _weeklyPlan;
    if (plan == null) return const SizedBox.shrink();

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday - 1; // 0=Mon

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_view_week_outlined,
                    color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Weekly Training Split',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7-day mini calendar
          Row(
            children: List.generate(7, (i) {
              final dayPlan = plan.days.length > i ? plan.days[i] : null;
              final isToday = i == today;
              final isExpanded = _expandedDay == i;
              final typeColor = _workoutTypeColor(dayPlan?.type ?? 'Rest');
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedDay = _expandedDay == i ? null : i;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? typeColor.withOpacity(0.2)
                          : (isToday
                              ? typeColor.withOpacity(0.15)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday
                            ? typeColor
                            : typeColor.withOpacity(0.3),
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          days[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday ? typeColor : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dayTypeShort(dayPlan?.type ?? 'Rest'),
                          style: TextStyle(
                            fontSize: 9,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          // Expanded day detail
          if (_expandedDay != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final dayPlan = plan.days.length > _expandedDay!
                  ? plan.days[_expandedDay!]
                  : null;
              if (dayPlan == null) return const SizedBox.shrink();
              final typeColor = _workoutTypeColor(dayPlan.type);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        days[_expandedDay!],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dayPlan.title,
                          style: TextStyle(
                            fontSize: 11,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...dayPlan.exercises.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right,
                              size: 18, color: AppColors.muted),
                          Expanded(
                            child: Text(
                              '${e.name}  ${e.sets}×${e.reps}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  String _dayTypeShort(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return 'Push';
      case 'pull':
        return 'Pull';
      case 'legs':
        return 'Legs';
      case 'cardio':
        return 'Cardio';
      case 'strength':
        return 'Str';
      case 'rest':
        return 'Rest';
      default:
        return type.length > 4 ? type.substring(0, 4) : type;
    }
  }

  Color _workoutTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'push':
        return AppColors.blue;
      case 'pull':
        return AppColors.purple;
      case 'legs':
        return AppColors.green;
      case 'cardio':
        return AppColors.orange;
      case 'strength':
        return AppColors.navy;
      case 'rest':
        return AppColors.muted;
      default:
        return AppColors.navy;
    }
  }

  // ── Progress Insight Card ────────────────────────────────────────────────────

  Widget _buildProgressInsightCard() {
    final insight = _progressInsight!;
    final isGain = insight.toLowerCase().contains('gain') ||
        insight.toLowerCase().contains('great') ||
        insight.toLowerCase().contains('well');
    final isLoss = insight.toLowerCase().contains('attention') ||
        insight.toLowerCase().contains('below') ||
        insight.toLowerCase().contains('behind');
    final bgColor = isGain
        ? AppColors.green.withOpacity(0.08)
        : isLoss
            ? AppColors.orange.withOpacity(0.08)
            : AppColors.blue.withOpacity(0.08);
    final borderColor = isGain
        ? AppColors.green.withOpacity(0.3)
        : isLoss
            ? AppColors.orange.withOpacity(0.3)
            : AppColors.blue.withOpacity(0.3);
    final icon = isGain ? '📈' : isLoss ? '📉' : '✅';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Text(
                'Progress Insight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── 12-Month Roadmap ─────────────────────────────────────────────────────────

  Widget _buildRoadmapCard() {
    final stats = _stats!;
    final week = _currentWeek(stats);
    final currentPhase = _phaseForWeek(week);

    final phases = [
      const _PhaseInfo(
        number: 1,
        name: 'Foundation',
        weekRange: 'Wk 1–12',
        description: 'Base strength & technique',
        expectedResult: 'Expected: +3–5 kg lean mass',
      ),
      const _PhaseInfo(
        number: 2,
        name: 'Hypertrophy',
        weekRange: 'Wk 13–24',
        description: 'Max muscle building volume',
        expectedResult: 'Expected: +4–6 kg muscle',
      ),
      const _PhaseInfo(
        number: 3,
        name: 'Strength',
        weekRange: 'Wk 25–36',
        description: 'Force output & density',
        expectedResult: 'Expected: +15–25% strength',
      ),
      const _PhaseInfo(
        number: 4,
        name: 'Peak',
        weekRange: 'Wk 37–52',
        description: 'Conditioning & refinement',
        expectedResult: 'Expected: Competition-ready',
      ),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map_outlined,
                    color: AppColors.navy, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                '12-Month Roadmap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...phases.map((phase) {
            final isActive = phase.number == currentPhase.number;
            return _buildRoadmapPhase(phase, isActive);
          }),
        ],
      ),
    );
  }

  Widget _buildRoadmapPhase(_PhaseInfo phase, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? AppColors.navy : AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.navy : const Color(0xFFE2E8F0),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.navy.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${phase.number}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : AppColors.navy,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      phase.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isActive ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phase.weekRange,
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive
                            ? Colors.white70
                            : AppColors.muted,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  phase.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.white70 : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  phase.expectedResult,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.amber : AppColors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Supplement Stack ─────────────────────────────────────────────────────────

  Widget _buildSupplementCard() {
    const supplements = [
      _SupplementInfo(
        name: 'Creatine Monohydrate',
        dose: '5g/day, any time',
        note: 'Most-researched supplement. Increases ATP for strength & power.',
        icon: '💊',
        color: AppColors.blue,
      ),
      _SupplementInfo(
        name: 'Whey Protein',
        dose: '25–30g post-workout',
        note: 'Fast-absorbing. Stimulates muscle protein synthesis optimally.',
        icon: '🥛',
        color: AppColors.green,
      ),
      _SupplementInfo(
        name: 'Vitamin D3',
        dose: '2000 IU/day',
        note: 'Supports testosterone, immunity, and bone health. Most people are deficient.',
        icon: '☀️',
        color: AppColors.orange,
      ),
      _SupplementInfo(
        name: 'Omega-3',
        dose: '2g/day with meals',
        note: 'Reduces inflammation, supports joint health and recovery.',
        icon: '🐟',
        color: AppColors.purple,
      ),
      _SupplementInfo(
        name: 'Caffeine (optional)',
        dose: '3–6 mg/kg, pre-workout',
        note: 'Proven ergogenic. Improves endurance, strength, and focus.',
        icon: '☕',
        color: AppColors.navy,
      ),
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science_outlined,
                    color: AppColors.green, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evidence-Based Supplements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Optional but well-researched',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...supplements.map((s) => _buildSupplementTile(s)),
        ],
      ),
    );
  }

  Widget _buildSupplementTile(_SupplementInfo s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: s.color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: s.color,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.dose,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: s.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  s.note,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared card wrapper ──────────────────────────────────────────────────────

  Widget _sectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────

class _PhaseInfo {
  final int number;
  final String name;
  final String weekRange;
  final String description;
  final String expectedResult;

  const _PhaseInfo({
    required this.number,
    required this.name,
    required this.weekRange,
    required this.description,
    required this.expectedResult,
  });
}

class _SupplementInfo {
  final String name;
  final String dose;
  final String note;
  final String icon;
  final Color color;

  const _SupplementInfo({
    required this.name,
    required this.dose,
    required this.note,
    required this.icon,
    required this.color,
  });
}
