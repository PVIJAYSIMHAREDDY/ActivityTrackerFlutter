import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/workout_model.dart';
import '../utils/date_utils.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = AppDateUtils.today();

  String _selectedType = 'Strength';
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _saving = false;

  static const List<Map<String, dynamic>> _workoutTypes = [
    {'type': 'Strength', 'icon': '🏋️', 'color': AppColors.navy},
    {'type': 'Cardio', 'icon': '🏃', 'color': AppColors.blue},
    {'type': 'Yoga', 'icon': '🧘', 'color': AppColors.purple},
    {'type': 'Sports', 'icon': '⚽', 'color': AppColors.green},
    {'type': 'HIIT', 'icon': '🔥', 'color': AppColors.red},
    {'type': 'Other', 'icon': '💪', 'color': AppColors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    final durationText = _durationController.text.trim();
    if (durationText.isEmpty) {
      _showError('Please enter duration');
      return;
    }
    final duration = int.tryParse(durationText);
    if (duration == null || duration <= 0) {
      _showError('Please enter a valid duration');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final workout = WorkoutModel(
        id: id,
        type: _selectedType.toLowerCase(),
        notes: _notesController.text.trim(),
        durationMins: duration,
        date: AppDateUtils.formatDate(_selectedDate),
        label: _selectedType,
      );
      await FirestoreService.saveWorkout(workout.toMap());
      if (!mounted) return;
      setState(() {
        _durationController.clear();
        _notesController.clear();
        _saving = false;
      });
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout saved!'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Failed to save workout');
    }
  }

  Future<void> _deleteWorkout(WorkoutModel workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workout'),
        content: const Text('Delete this workout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirestoreService.deleteWorkout(workout.id);
      } catch (e) {
        _showError('Failed to delete workout');
      }
    }
  }

  void _changeDate(int days) {
    setState(() => _selectedDate = AppDateUtils.addDays(_selectedDate, days));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.red),
    );
  }

  String _workoutIcon(String type) {
    final match = _workoutTypes.firstWhere(
      (t) => (t['type'] as String).toLowerCase() == type.toLowerCase(),
      orElse: () => {'icon': '💪'},
    );
    return match['icon'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildDateNav(),
          Container(
            color: AppColors.navy,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF8BA3BE),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              tabs: const [
                Tab(text: 'Log'),
                Tab(text: 'History'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNav() {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            onPressed: () => _changeDate(-1),
          ),
          Text(
            AppDateUtils.formatDateDisplay(_selectedDate),
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Workout Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: _workoutTypes.map((wt) => _buildTypeCard(wt)).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Duration (minutes)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 30',
              suffixText: 'min',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Optional notes...',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save Workout',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> wt) {
    final selected = _selectedType == wt['type'];
    final color = wt['color'] as Color;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = wt['type'] as String),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? color : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(wt['icon'] as String, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              wt['type'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.workoutsStream(AppDateUtils.formatDate(_selectedDate)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.navy));
        }
        final docs = snapshot.data?.docs ?? [];
        final workouts = docs.map((doc) => WorkoutModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
        final totalMin = workouts.fold<int>(0, (sum, w) => sum + w.durationMins);
        return Column(
          children: [
            if (workouts.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Today: ${workouts.length} workout${workouts.length == 1 ? '' : 's'} · $totalMin min total',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            Expanded(
              child: workouts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🏋️', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text(
                            'No workouts logged yet',
                            style: TextStyle(color: AppColors.muted, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: workouts.length,
                      itemBuilder: (ctx, i) => _buildWorkoutCard(workouts[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutCard(WorkoutModel workout) {
    final icon = _workoutIcon(workout.type);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.navy.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
        ),
        title: Text(
          workout.label ?? workout.type,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${workout.durationMins} min',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            if (workout.notes != null && workout.notes!.isNotEmpty)
              Text(
                workout.notes!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: AppColors.muted, size: 20),
          onPressed: () => _deleteWorkout(workout),
        ),
      ),
    );
  }
}
