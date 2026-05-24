import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/summary_model.dart';
import '../models/body_stats_model.dart';
import '../utils/date_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _selectedDate = AppDateUtils.today();
  SummaryModel? _summary;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final date = AppDateUtils.formatDate(_selectedDate);

      final taskSnap    = await FirestoreService.tasksStream(date).first;
      final habitSnap   = await FirestoreService.habitsStream().first;
      final dietSnap    = await FirestoreService.dietStream(date).first;
      final workoutSnap = await FirestoreService.workoutsStream(date).first;
      final bodyStats   = await BodyStats.load();

      final tasks      = taskSnap.docs;
      final tasksDone  = tasks.where((d) => (d.data() as Map)['done'] == true).length;
      final habits     = habitSnap.docs;
      final habitsDone = habits.where((d) {
        final data = d.data() as Map;
        return data['lastDoneDate'] == date;
      }).length;

      double calories = 0, protein = 0, carbs = 0, fat = 0;
      for (final d in dietSnap.docs) {
        final data = d.data() as Map;
        calories += (data['calories'] ?? 0).toDouble();
        protein  += (data['protein']  ?? 0).toDouble();
        carbs    += (data['carbs']    ?? 0).toDouble();
        fat      += (data['fat']      ?? 0).toDouble();
      }

      if (!mounted) return;
      setState(() {
        _summary = SummaryModel(
          tasksDone: tasksDone,
          tasksTotal: tasks.length,
          habitsDone: habitsDone,
          habitsTotal: habits.length,
          calories: calories,
          workouts: workoutSnap.docs.length,
          macros: Macros(protein: protein, carbs: carbs, fat: fat),
          macroGoals: MacroGoals(
            protein: bodyStats?.targetProtein ?? 150,
            carbs: bodyStats?.targetCarbs ?? 250,
            fat: bodyStats?.targetFat ?? 65,
          ),
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = AppDateUtils.addDays(_selectedDate, days);
      _summary = null;
    });
    _fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildDateNav(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchSummary,
              color: AppColors.navy,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNav() {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            onPressed: () => _changeDate(-1),
          ),
          Text(
            AppDateUtils.formatDateDisplay(_selectedDate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            ),
          ),
        ],
      );
    }

    if (_error != null && _summary == null) {
      return ListView(
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.muted, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load data. Tap to retry.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchSummary,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final s = _summary!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Overview'),
        const SizedBox(height: 8),
        _buildStatGrid(s),
        const SizedBox(height: 20),
        _buildSectionHeader('Macros'),
        const SizedBox(height: 8),
        _buildMacrosCard(s),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatGrid(SummaryModel s) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          icon: Icons.check_box,
          color: AppColors.blue,
          label: 'Tasks Done',
          value: '${s.tasksDone}/${s.tasksTotal}',
        ),
        _buildStatCard(
          icon: Icons.local_fire_department,
          color: AppColors.green,
          label: 'Habits Done',
          value: '${s.habitsDone}/${s.habitsTotal}',
        ),
        _buildStatCard(
          icon: Icons.restaurant,
          color: AppColors.orange,
          label: 'Calories',
          value: '${s.calories.toStringAsFixed(0)} kcal',
        ),
        _buildStatCard(
          icon: Icons.fitness_center,
          color: AppColors.purple,
          label: 'Workouts',
          value: '${s.workouts}',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard(SummaryModel s) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMacroRow(
            label: 'Protein',
            value: s.macros.protein,
            goal: s.macroGoals.protein > 0 ? s.macroGoals.protein : 150,
            color: AppColors.blue,
            unit: 'g',
          ),
          const SizedBox(height: 16),
          _buildMacroRow(
            label: 'Carbs',
            value: s.macros.carbs,
            goal: s.macroGoals.carbs > 0 ? s.macroGoals.carbs : 250,
            color: AppColors.orange,
            unit: 'g',
          ),
          const SizedBox(height: 16),
          _buildMacroRow(
            label: 'Fat',
            value: s.macros.fat,
            goal: s.macroGoals.fat > 0 ? s.macroGoals.fat : 65,
            color: AppColors.red,
            unit: 'g',
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow({
    required String label,
    required double value,
    required double goal,
    required Color color,
    required String unit,
  }) {
    final progress = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit / ${goal.toStringAsFixed(0)}$unit',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
