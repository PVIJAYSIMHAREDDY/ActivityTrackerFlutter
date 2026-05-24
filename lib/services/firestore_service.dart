import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

/// All data is stored under users/{firebaseUid}/ so it's
/// automatically scoped to the signed-in account.
class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => fa.FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  // ── Body Stats ────────────────────────────────────────────────────────────

  static Future<void> saveBodyStats(Map<String, dynamic> stats) async {
    await _userDoc?.collection('profile').doc('body_stats').set(
          stats,
          SetOptions(merge: true),
        );
  }

  static Future<Map<String, dynamic>?> loadBodyStats() async {
    final snap =
        await _userDoc?.collection('profile').doc('body_stats').get();
    return snap?.exists == true ? snap!.data() : null;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<void> saveProfile(Map<String, dynamic> data) async {
    await _userDoc?.collection('profile').doc('info').set(
          data,
          SetOptions(merge: true),
        );
  }

  static Future<Map<String, dynamic>?> loadProfile() async {
    final snap = await _userDoc?.collection('profile').doc('info').get();
    return snap?.exists == true ? snap!.data() : null;
  }

  // ── Weight History ────────────────────────────────────────────────────────

  static Future<void> addWeightEntry(double weightKg, DateTime date) async {
    await _userDoc?.collection('weight_history').add({
      'weightKg': weightKg,
      'date': Timestamp.fromDate(date),
    });
  }

  static Future<List<Map<String, dynamic>>> loadWeightHistory() async {
    final snap = await _userDoc
        ?.collection('weight_history')
        .orderBy('date', descending: false)
        .get();
    return snap?.docs.map((d) => {...d.data(), 'id': d.id}).toList() ?? [];
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  static Future<void> saveTask(Map<String, dynamic> task) async {
    final id = task['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        ?.collection('tasks')
        .doc(id)
        .set(task, SetOptions(merge: true));
  }

  static Future<void> deleteTask(String id) async {
    await _userDoc?.collection('tasks').doc(id).delete();
  }

  static Stream<QuerySnapshot> tasksStream(String date) {
    final doc = _userDoc;
    if (doc == null) return Stream.error(Exception('User not authenticated'));
    return doc
        .collection('tasks')
        .where('date', isEqualTo: date)
        .snapshots();
  }

  // ── Habits ────────────────────────────────────────────────────────────────

  static Future<void> saveHabit(Map<String, dynamic> habit) async {
    final id = habit['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        ?.collection('habits')
        .doc(id)
        .set(habit, SetOptions(merge: true));
  }

  static Future<void> deleteHabit(String id) async {
    await _userDoc?.collection('habits').doc(id).delete();
  }

  static Stream<QuerySnapshot> habitsStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.error(Exception('User not authenticated'));
    return doc.collection('habits').snapshots();
  }

  // ── Workouts ──────────────────────────────────────────────────────────────

  static Future<void> saveWorkout(Map<String, dynamic> workout) async {
    final id = workout['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        ?.collection('workouts')
        .doc(id)
        .set(workout, SetOptions(merge: true));
  }

  static Future<void> deleteWorkout(String id) async {
    await _userDoc?.collection('workouts').doc(id).delete();
  }

  static Stream<QuerySnapshot> workoutsStream(String date) {
    final doc = _userDoc;
    if (doc == null) return Stream.error(Exception('User not authenticated'));
    return doc
        .collection('workouts')
        .where('date', isEqualTo: date)
        .snapshots();
  }

  // ── Diet ──────────────────────────────────────────────────────────────────

  static Future<void> saveMeal(Map<String, dynamic> meal) async {
    final id = meal['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        ?.collection('diet')
        .doc(id)
        .set(meal, SetOptions(merge: true));
  }

  static Future<void> deleteMeal(String id) async {
    await _userDoc?.collection('diet').doc(id).delete();
  }

  static Stream<QuerySnapshot> dietStream(String date) {
    final doc = _userDoc;
    if (doc == null) return Stream.error(Exception('User not authenticated'));
    return doc
        .collection('diet')
        .where('date', isEqualTo: date)
        .snapshots();
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  static Future<void> saveGoal(Map<String, dynamic> goal) async {
    final id = goal['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _userDoc
        ?.collection('goals')
        .doc(id)
        .set(goal, SetOptions(merge: true));
  }

  static Future<void> deleteGoal(String id) async {
    await _userDoc?.collection('goals').doc(id).delete();
  }

  static Stream<QuerySnapshot> goalsStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.error(Exception('User not authenticated'));
    return doc.collection('goals').snapshots();
  }
}
