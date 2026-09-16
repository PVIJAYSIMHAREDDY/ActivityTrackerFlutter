import 'package:firebase_core/firebase_core.dart';
import 'app_config.dart';
import '../models/habit_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

/// All data is stored under users/{firebaseUid}/ so it's
/// automatically scoped to the signed-in account.
class FirestoreService {
  static final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: AppConfig.databaseId,
  );

  static String? get _uid => fa.FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _uid;
    if (uid == null) throw StateError('Please sign in to save your data.');
    return _db.collection('users').doc(uid);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> bodyStatsStream() =>
      _userDoc.collection('profile').doc('body_stats').snapshots();

  static Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() =>
      _userDoc.collection('profile').doc('info').snapshots();

  // ── Body Stats ────────────────────────────────────────────────────────────

  static Future<void> saveBodyStats(Map<String, dynamic> stats) async {
    await _userDoc
        .collection('profile')
        .doc('body_stats')
        .set(stats, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> loadBodyStats() async {
    final snap = await _userDoc.collection('profile').doc('body_stats').get();
    return snap.exists == true ? snap.data() : null;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<void> saveProfile(Map<String, dynamic> data) async {
    await _userDoc
        .collection('profile')
        .doc('info')
        .set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> loadProfile() async {
    final snap = await _userDoc.collection('profile').doc('info').get();
    return snap.exists == true ? snap.data() : null;
  }

  // ── Weight History ────────────────────────────────────────────────────────

  static Future<void> addWeightEntry(double weightKg, DateTime date) async {
    await _userDoc.collection('weight_history').add({
      'weightKg': weightKg,
      'date': Timestamp.fromDate(date),
    });
  }

  static Future<List<Map<String, dynamic>>> loadWeightHistory() async {
    final snap = await _userDoc
        .collection('weight_history')
        .orderBy('date', descending: false)
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  static Future<void> saveTask(Map<String, dynamic> task) async {
    final id =
        task['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        .collection('tasks')
        .doc(id)
        .set(task, SetOptions(merge: true));
  }

  static Future<void> deleteTask(String id) async {
    await _userDoc.collection('tasks').doc(id).delete();
  }

  static Stream<QuerySnapshot> tasksStream(String date) {
    final doc = _userDoc;
    return doc.collection('tasks').where('date', isEqualTo: date).snapshots();
  }

  // ── Habits ────────────────────────────────────────────────────────────────

  static Future<void> saveHabit(Map<String, dynamic> habit) async {
    final id =
        habit['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        .collection('habits')
        .doc(id)
        .set(habit, SetOptions(merge: true));
  }

  static Future<void> toggleHabit(String id, String date) async {
    final ref = _userDoc.collection('habits').doc(id);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) throw StateError('Habit no longer exists.');
      final habit = HabitModel.fromFirestore(snap.data()!, id);
      transaction.update(ref, habit.toggleDate(date).toMap());
    });
  }

  static Future<void> deleteHabit(String id) async {
    await _userDoc.collection('habits').doc(id).delete();
  }

  static Stream<QuerySnapshot> habitsStream() {
    final doc = _userDoc;
    return doc.collection('habits').snapshots();
  }

  static Stream<QuerySnapshot> recentWorkoutsStream() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String date(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return _userDoc
        .collection('workouts')
        .where(
          'date',
          isGreaterThanOrEqualTo: date(today.subtract(const Duration(days: 7))),
        )
        .where('date', isLessThan: date(today))
        .snapshots();
  }

  // ── Workouts ──────────────────────────────────────────────────────────────

  static Future<void> saveWorkout(Map<String, dynamic> workout) async {
    final id =
        workout['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        .collection('workouts')
        .doc(id)
        .set(workout, SetOptions(merge: true));
  }

  static Future<void> deleteWorkout(String id) async {
    await _userDoc.collection('workouts').doc(id).delete();
  }

  static Stream<QuerySnapshot> workoutsStream(String date) {
    final doc = _userDoc;
    return doc
        .collection('workouts')
        .where('date', isEqualTo: date)
        .snapshots();
  }

  // ── Diet ──────────────────────────────────────────────────────────────────

  static Future<void> saveMeal(Map<String, dynamic> meal) async {
    final id =
        meal['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        .collection('diet')
        .doc(id)
        .set(meal, SetOptions(merge: true));
  }

  static Future<void> deleteMeal(String id) async {
    await _userDoc.collection('diet').doc(id).delete();
  }

  static Stream<QuerySnapshot> dietStream(String date) {
    final doc = _userDoc;
    return doc.collection('diet').where('date', isEqualTo: date).snapshots();
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  static Future<void> saveGoal(Map<String, dynamic> goal) async {
    final id =
        goal['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        .collection('goals')
        .doc(id)
        .set(goal, SetOptions(merge: true));
  }

  static Future<void> deleteGoal(String id) async {
    await _userDoc.collection('goals').doc(id).delete();
  }

  static Stream<QuerySnapshot> goalsStream() {
    final doc = _userDoc;
    return doc.collection('goals').snapshots();
  }

  /// Only this app's known, flat collections. Stop on failure so deletion is retryable.
  static Future<void> deleteUserData(String uid) async {
    if (_uid != uid) throw StateError('Account changed. Please try again.');
    final user = _db.collection('users').doc(uid);
    for (final name in [
      'profile',
      'weight_history',
      'tasks',
      'habits',
      'workouts',
      'diet',
      'goals',
    ]) {
      while (true) {
        final page = await user
            .collection(name)
            .limit(400)
            .get(const GetOptions(source: Source.server));
        if (page.docs.isEmpty) break;
        final batch = _db.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await user.delete();
  }
}
