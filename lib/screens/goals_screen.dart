import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/goal_model.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _showForm = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _currentController = TextEditingController();
  String _selectedCategory = 'fitness';
  bool _saving = false;

  static const List<Map<String, dynamic>> _categories = [
    {'key': 'fitness', 'label': 'Fitness', 'color': AppColors.blue},
    {'key': 'diet', 'label': 'Diet', 'color': AppColors.green},
    {'key': 'work', 'label': 'Work', 'color': AppColors.navy},
    {'key': 'personal', 'label': 'Personal', 'color': AppColors.purple},
    {'key': 'finance', 'label': 'Finance', 'color': AppColors.orange},
    {'key': 'health', 'label': 'Health', 'color': AppColors.red},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a title');
      return;
    }
    final target = double.tryParse(_targetController.text);
    if (target == null || target <= 0) {
      _showError('Please enter a valid target value');
      return;
    }
    final current = double.tryParse(_currentController.text) ?? 0;

    setState(() => _saving = true);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final goal = GoalModel(
        id: id,
        title: title,
        category: _selectedCategory,
        targetValue: target,
        currentValue: current,
      );
      await FirestoreService.saveGoal(goal.toMap());
      setState(() {
        _titleController.clear();
        _targetController.clear();
        _currentController.clear();
        _selectedCategory = 'fitness';
        _showForm = false;
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
      _showError('Failed to create goal');
    }
  }

  Future<void> _updateGoalValue(GoalModel goal, double delta) async {
    final newValue = (goal.currentValue + delta).clamp(0.0, goal.targetValue * 2);
    try {
      await FirestoreService.saveGoal(goal.copyWith(currentValue: newValue).toMap());
    } catch (e) {
      _showError('Failed to update goal');
    }
  }

  Future<void> _deleteGoal(GoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Delete "${goal.title}"?'),
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
        await FirestoreService.deleteGoal(goal.id);
      } catch (e) {
        _showError('Failed to delete goal');
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.red),
    );
  }

  Color _categoryColor(String category) {
    final cat = _categories.firstWhere(
      (c) => c['key'] == category,
      orElse: () => {'color': AppColors.muted},
    );
    return cat['color'] as Color;
  }

  String _categoryLabel(String category) {
    final cat = _categories.firstWhere(
      (c) => c['key'] == category,
      orElse: () => {'label': category},
    );
    return cat['label'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.goalsStream(),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;

          List<GoalModel> goals = [];
          if (snapshot.hasData) {
            final docs = snapshot.data?.docs ?? [];
            try {
              goals = docs
                  .map((doc) => GoalModel.fromFirestore(
                      doc.data() as Map<String, dynamic>, doc.id))
                  .toList();
            } catch (_) {}
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAddButton(),
                if (_showForm) ...[
                  const SizedBox(height: 12),
                  _buildAddForm(),
                ],
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppColors.navy),
                    ),
                  )
                else if (goals.isEmpty && !_showForm)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Text('🎯', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text(
                            'No goals yet. Add one!',
                            style: TextStyle(color: AppColors.muted, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...goals.map((g) => _buildGoalCard(g)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _showForm = !_showForm),
        icon: Icon(_showForm ? Icons.close : Icons.add),
        label: Text(_showForm ? 'Cancel' : 'Add New Goal'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _showForm ? AppColors.muted : AppColors.navy,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Goal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Goal title...'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Category',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _categories.map((cat) {
              final selected = _selectedCategory == cat['key'];
              final color = cat['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat['key'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? color : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    cat['label'] as String,
                    style: TextStyle(
                      color: selected ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target Value',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '100', isDense: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Value',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _currentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0', isDense: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveGoal,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _showForm = false),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.muted),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    final color = _categoryColor(goal.category);
    final progress = goal.progress;
    final isComplete = goal.isComplete;

    return GestureDetector(
      onLongPress: () => _deleteGoal(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _categoryLabel(goal.category),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Done!',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              goal.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currentValue.toStringAsFixed(1)} / ${goal.targetValue.toStringAsFixed(1)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                Row(
                  children: [
                    _counterButton(
                      icon: Icons.remove,
                      onTap: () => _updateGoalValue(goal, -1),
                      color: AppColors.red,
                    ),
                    const SizedBox(width: 8),
                    _counterButton(
                      icon: Icons.add,
                      onTap: () => _updateGoalValue(goal, 1),
                      color: AppColors.green,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
