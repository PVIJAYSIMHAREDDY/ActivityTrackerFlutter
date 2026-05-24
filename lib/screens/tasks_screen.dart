import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import '../utils/date_utils.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime _selectedDate = AppDateUtils.today();

  final TextEditingController _taskController = TextEditingController();
  String _selectedPriority = 'medium';

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final task = TaskModel(
        id: id,
        text: text,
        priority: _selectedPriority,
        done: false,
        date: AppDateUtils.formatDate(_selectedDate),
      );
      await FirestoreService.saveTask(task.toMap());
      _taskController.clear();
    } catch (e) {
      _showError('Failed to add task');
    }
  }

  Future<void> _toggleTask(TaskModel task) async {
    try {
      await FirestoreService.saveTask(task.copyWith(done: !task.done).toMap());
    } catch (e) {
      _showError('Failed to update task');
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.text}"?'),
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
        await FirestoreService.deleteTask(task.id);
      } catch (e) {
        _showError('Failed to delete task');
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = AppDateUtils.addDays(_selectedDate, days);
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.red),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.red;
      case 'medium':
        return AppColors.orange;
      case 'low':
        return AppColors.green;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildDateNav(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService.tasksStream(AppDateUtils.formatDate(_selectedDate)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.navy));
                }
                final docs = snapshot.data?.docs ?? [];
                final tasks = docs.map((doc) => TaskModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_box_outline_blank, color: AppColors.muted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks for this day',
                          style: TextStyle(color: AppColors.muted, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: tasks.length,
                  itemBuilder: (ctx, i) => _buildTaskItem(tasks[i]),
                );
              },
            ),
          ),
          _buildAddBar(),
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

  Widget _buildTaskItem(TaskModel task) {
    return GestureDetector(
      onLongPress: () => _deleteTask(task),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: GestureDetector(
            onTap: () => _toggleTask(task),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.done ? AppColors.green : AppColors.muted,
                  width: 2,
                ),
                color: task.done ? AppColors.green : Colors.transparent,
              ),
              child: task.done
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            task.text,
            style: TextStyle(
              fontSize: 15,
              color: task.done ? AppColors.muted : AppColors.textDark,
              decoration: task.done ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _priorityColor(task.priority).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority.toUpperCase()[0],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _priorityColor(task.priority),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _deleteTask(task),
                child: const Icon(Icons.close, color: AppColors.muted, size: 20),
              ),
            ],
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
        children: [
          Row(
            children: [
              _priorityButton('H', 'high'),
              const SizedBox(width: 6),
              _priorityButton('M', 'medium'),
              const SizedBox(width: 6),
              _priorityButton('L', 'low'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    hintText: 'Add a task...',
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addTask(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addTask,
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

  Widget _priorityButton(String label, String priority) {
    final selected = _selectedPriority == priority;
    final color = _priorityColor(priority);
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
