import '../models/body_stats_model.dart';
import '../models/coaching_preferences.dart';
import '../models/goal_model.dart';
import 'adaptive_plan_service.dart';
import 'firestore_service.dart';

class CoachingContextService {
  static Future<AdaptivePlan?> load() async {
    final stats = await BodyStats.load();
    if (stats == null) return null;
    final profile = await FirestoreService.loadProfile() ?? {};
    final goals = await FirestoreService.goalsStream().first;
    GoalModel? goal;
    for (final doc in goals.docs) {
      if (doc.id == profile['planGoalId']) {
        goal = GoalModel.fromFirestore(
          Map<String, dynamic>.from(doc.data() as Map),
          doc.id,
        );
      }
    }
    final workouts = await FirestoreService.recentWorkoutsStream().first;
    final dates = <String>{};
    for (final doc in workouts.docs) {
      final d = Map<String, dynamic>.from(doc.data() as Map);
      if (d['type']?.toString().toLowerCase() == 'strength') {
        dates.add(d['date'].toString());
      }
    }
    final diet = profile['planDiet'];
    return AdaptivePlanService.generate(
      stats,
      goal: goal,
      diet: ['Vegetarian', 'Mixed diet', 'Vegan'].contains(diet)
          ? diet as String
          : 'Vegetarian',
      preferences: CoachingPreferences.fromMap(
        Map<String, dynamic>.from(profile['coaching'] as Map? ?? {}),
      ),
      recentStrengthDays: dates.length,
    );
  }
}
