import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/habit_model.dart';
import '../utils/date_utils.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  DateTime _selectedDate = AppDateUtils.today();

  final TextEditingController _nameController = TextEditingController();
  String _selectedIcon = '💧';

  static const List<String> _icons = [
    '💧', '🏃', '📚', '🧘', '🥗', '💊', '😴', '✍️', '🎯', '🔥'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addHabit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final habit = HabitModel(
        id: id,
        name: name,
        icon: _selectedIcon,
        streak: 0,
        lastDoneDate: '',
      );
      await FirestoreService.saveHabit(habit.toMap());
      _nameController.clear();
    } catch (e) {
      _showError('Failed to add habit');
    }
  }

  String _todayString() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleHabit(HabitModel habit) async {
    try {
      final today = _todayString();
      final yesterday = _yesterdayString();
      HabitModel updated;
      if (habit.doneToday) {
        updated = habit.copyWith(
          lastDoneDate: '',
          streak: habit.streak > 0 ? habit.streak - 1 : 0,
        );
      } else if (habit.lastDoneDate == yesterday) {
        updated = habit.copyWith(
          lastDoneDate: today,
          streak: habit.streak + 1,
        );
      } else {
        updated = habit.copyWith(
          lastDoneDate: today,
          streak: 1,
        );
      }
      await FirestoreService.saveHabit(updated.toMap());
    } catch (e) {
      _showError('Failed to toggle habit');
    }
  }

  Future<void> _deleteHabit(HabitModel habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Delete "${habit.name}"?'),
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
        await FirestoreService.deleteHabit(habit.id);
      } catch (e) {
        _showError('Failed to delete habit');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.habitsStream(),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          List<HabitModel> habits = [];
          if (snapshot.hasData) {
            final docs = snapshot.data?.docs ?? [];
            try {
              habits = docs.map((doc) => HabitModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
            } catch (_) {}
          }
          final done     = habits.where((h) => h.doneToday).length;
          final total    = habits.length;
          final progress = total > 0 ? done / total : 0.0;

          return Column(
            children: [
              _buildDateNav(),
              if (habits.isNotEmpty) _buildHeader(done, total, progress),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                    : habits.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🌱', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(
                                  'No habits yet. Add one below!',
                                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: habits.length,
                            itemBuilder: (ctx, i) => _buildHabitItem(habits[i]),
                          ),
              ),
              _buildAddBar(),
            ],
          );
        },
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

  Widget _buildHeader(int done, int total, double progress) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$done/$total done today',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.green.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(HabitModel habit) {
    return GestureDetector(
      onLongPress: () => _deleteHabit(habit),
      child: Container(
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Text(habit.icon, style: const TextStyle(fontSize: 26)),
          title: Text(
            habit.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            '🔥 ${habit.streak} day streak',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          trailing: GestureDetector(
            onTap: () => _toggleHabit(habit),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: habit.doneToday ? AppColors.green : Colors.transparent,
                border: Border.all(
                  color: habit.doneToday ? AppColors.green : AppColors.muted,
                  width: 2,
                ),
              ),
              child: habit.doneToday
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddBar() {
    return Container(
      color: AppColors.card,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _icons.map((icon) {
                final selected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.navy.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? AppColors.navy : Colors.transparent,
                      ),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Habit name...',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addHabit(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
