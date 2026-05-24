import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/summary_model.dart';
import '../models/task_model.dart';
import '../models/habit_model.dart';
import '../models/workout_model.dart';
import '../models/diet_entry_model.dart';
import '../models/goal_model.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.4.26:5050';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ─── Summary ───────────────────────────────────────────────────────────────

  static Future<SummaryModel> getSummary(String date) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/summary?date=$date'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return SummaryModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load summary: ${response.statusCode}');
  }

  // ─── Tasks ─────────────────────────────────────────────────────────────────

  static Future<List<TaskModel>> getTasks(String date) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/tasks?date=$date'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => TaskModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load tasks: ${response.statusCode}');
  }

  static Future<TaskModel> createTask(String text, String priority, String date) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/tasks'),
          headers: _headers,
          body: json.encode({'text': text, 'priority': priority, 'date': date}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return TaskModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create task: ${response.statusCode}');
  }

  static Future<void> updateTask(int id, bool done) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/tasks/$id'),
          headers: _headers,
          body: json.encode({'done': done}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }

  static Future<void> deleteTask(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/api/tasks/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }

  // ─── Habits ────────────────────────────────────────────────────────────────

  static Future<List<HabitModel>> getHabits(String date) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/habits?date=$date'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => HabitModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load habits: ${response.statusCode}');
  }

  static Future<HabitModel> createHabit(String name, String icon) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/habits'),
          headers: _headers,
          body: json.encode({'name': name, 'icon': icon}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return HabitModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create habit: ${response.statusCode}');
  }

  static Future<void> toggleHabit(int id, String date) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/habits/$id/toggle'),
          headers: _headers,
          body: json.encode({'date': date}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle habit: ${response.statusCode}');
    }
  }

  static Future<void> deleteHabit(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/api/habits/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete habit: ${response.statusCode}');
    }
  }

  // ─── Diet ──────────────────────────────────────────────────────────────────

  static Future<List<DietEntryModel>> getDiet(String date) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/diet?date=$date'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => DietEntryModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load diet: ${response.statusCode}');
  }

  static Future<DietEntryModel> createDietEntry({
    required String name,
    required String mealType,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required String date,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/diet'),
          headers: _headers,
          body: json.encode({
            'name': name,
            'meal_type': mealType,
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat,
            'date': date,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return DietEntryModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create diet entry: ${response.statusCode}');
  }

  static Future<void> deleteDietEntry(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/api/diet/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete diet entry: ${response.statusCode}');
    }
  }

  // ─── Workouts ──────────────────────────────────────────────────────────────

  static Future<List<WorkoutModel>> getWorkouts(String date) async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/workouts?date=$date'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => WorkoutModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load workouts: ${response.statusCode}');
  }

  static Future<WorkoutModel> createWorkout({
    required String type,
    required String notes,
    required int durationMins,
    required String date,
    required String label,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/workouts'),
          headers: _headers,
          body: json.encode({
            'type': type,
            'notes': notes,
            'duration_mins': durationMins,
            'date': date,
            'label': label,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return WorkoutModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create workout: ${response.statusCode}');
  }

  static Future<void> deleteWorkout(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/api/workouts/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete workout: ${response.statusCode}');
    }
  }

  // ─── Goals ─────────────────────────────────────────────────────────────────

  static Future<List<GoalModel>> getGoals() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/goals'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => GoalModel.fromJson(j)).toList();
    }
    throw Exception('Failed to load goals: ${response.statusCode}');
  }

  static Future<GoalModel> createGoal({
    required String title,
    required String category,
    required double targetValue,
    required double currentValue,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/goals'),
          headers: _headers,
          body: json.encode({
            'title': title,
            'category': category,
            'target_value': targetValue,
            'current_value': currentValue,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return GoalModel.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create goal: ${response.statusCode}');
  }

  static Future<void> updateGoal(int id, double currentValue) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl/api/goals/$id'),
          headers: _headers,
          body: json.encode({'current_value': currentValue}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to update goal: ${response.statusCode}');
    }
  }

  static Future<void> deleteGoal(int id) async {
    final response = await http
        .delete(Uri.parse('$baseUrl/api/goals/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete goal: ${response.statusCode}');
    }
  }
}
