import '../models/body_stats_model.dart';
import 'adaptive_plan_service.dart';
import 'coaching_knowledge.dart';
import 'issa_library.dart';

/// Source-informed, deterministic coaching guidance; no remote AI provider.
class CoachingReply {
  final String text;
  final List<IssaPassage> passages;
  const CoachingReply(this.text, [this.passages = const []]);
}

class LocalCoachService {
  static bool _restricted(
    String message,
    BodyStats? stats,
    AdaptivePlan? plan,
  ) {
    final q = message.toLowerCase();
    return plan?.needsReview == true ||
        (stats != null && stats.age < 18) ||
        [
          'pain',
          'faint',
          'breathe',
          'injur',
          'hurt',
          'pregnan',
          'diabet',
          'medication',
          'eating disorder',
          'numb',
          'tingling',
          'supplement',
          'creatine',
          'fat burner',
          'steroid',
        ].any(q.contains);
  }

  static Future<CoachingReply> replyWithSources(
    String message,
    BodyStats? stats, {
    AdaptivePlan? plan,
    IssaLibrary? library,
  }) async {
    final guidance = reply(message, stats, plan: plan);
    if (_restricted(message, stats, plan)) return CoachingReply(guidance);
    try {
      final sources = library ?? await IssaLibrary.load();
      final results = sources.search(message, limit: 3);
      final general =
          stats == null &&
          !RegExp(
            r'\b(my|today|plan|targets|workout)\b',
            caseSensitive: false,
          ).hasMatch(message);
      return CoachingReply(
        general && results.isNotEmpty
            ? (CoachingKnowledge.answer(message) ??
                  'Here are matching passages from your ISSA library. Read the surrounding source page for context. These are educational excerpts, not a personalized prescription.')
            : guidance,
        results,
      );
    } catch (_) {
      return CoachingReply(
        '$guidance\n\nThe source library could not load. Your saved plan guidance is still available; retry the library to inspect source pages.',
      );
    }
  }

  static String reply(String message, BodyStats? stats, {AdaptivePlan? plan}) {
    final query = message.toLowerCase();
    bool has(List<String> words) => words.any(query.contains);
    if (has(['chest pain', 'faint', 'cannot breathe', "can't breathe"])) {
      return 'Stop exercising. Chest pain, fainting or difficulty breathing can require urgent medical attention. Contact your local emergency service now if these symptoms are happening. This app cannot assess an emergency.';
    }
    if (has([
      'pain',
      'injur',
      'hurt',
      'pregnan',
      'diabet',
      'medication',
      'eating disorder',
      'numb',
      'tingling',
    ])) {
      return 'I cannot diagnose symptoms or tailor exercise or nutrition to a medical condition. Stop movements that cause pain and speak with a qualified healthcare professional before continuing. Update your coaching assessment so automatic prescriptions are paused. Source: ISSA Corrective Exercise Specialist, PDF pages 103–104; Exercise Therapy, PDF pages 35–36.';
    }
    if (has(['supplement', 'creatine', 'fat burner', 'steroid'])) {
      return 'This coach does not prescribe supplements or doses. A qualified clinician or dietitian can review suitability and interactions. Start with meals, recovery and training consistency.';
    }
    if (plan?.needsReview == true) {
      return 'Your assessment reports symptoms or condition-specific needs, so personalized diet and exercise prescriptions are paused. Export your assessment and discuss it with a qualified professional.';
    }
    if (stats == null) {
      return 'Set up your body profile in Profile > Body Stats first, then complete the coaching assessment. I can use your goals, equipment and recovery check-in to create your weekly plan.';
    }
    if (stats.age < 18) {
      return 'Automatic plans are for adults. A qualified professional can help create an age-appropriate plan.';
    }
    AdaptivePlan current;
    try {
      current = plan ?? AdaptivePlanService.generate(stats);
    } on ArgumentError {
      return 'Update your body profile with valid adult measurements before generating personalized guidance.';
    }
    final source = CoachingKnowledge.answer(message);
    if (has(['meal', 'diet', 'eat', 'nutri', 'calori', 'protein', 'macro'])) {
      return 'Your current plan is ${current.phase}. Estimated daily targets: ${current.stats.units.energy(current.stats.targetCalories)}; protein ${current.stats.units.food(current.stats.targetProtein)}; carbohydrate ${current.stats.units.food(current.stats.targetCarbs)}; fat ${current.stats.units.food(current.stats.targetFat)}.\n\n${current.mealDays[current.generatedAt.weekday - 1].display(current.stats.units)}\n\nView all seven days in Coach > Nutrition, or download the diet or full plan below.\n\n${source ?? CoachingKnowledge.references.first.principle}';
    }
    if (has([
      'progress',
      'plateau',
      'weight',
      'goal reached',
      'completed goal',
    ])) {
      return '${current.reasons.join("\n\n")}\n\nNext step: ${current.preferences.habit}.\nSource: ISSA Sports Nutrition, PDF pages 409–410; Transformation Specialist, PDF page 14.';
    }
    if (has(['workout', 'train', 'plan', 'exercise', 'routine', 'cardio'])) {
      return '${current.phase}\n\n${current.workouts[current.generatedAt.weekday - 1]}\n\n${current.reasons.join("\n")}\n\n${source ?? CoachingKnowledge.references[1].principle}\n\nDownload Workout or Everything for the full seven-day programme.';
    }
    if (source != null) return source;
    return 'I can help with your saved workout plan, portioned meals, recovery, progression and habit building. Try “What is my workout today?”, “Show my diet plan”, or “How can I stay consistent?”. My answers use reviewed summaries and rules; I cannot answer every coaching question.';
  }
}
