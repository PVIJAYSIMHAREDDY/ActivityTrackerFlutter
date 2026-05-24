import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/diet_entry_model.dart';
import '../utils/date_utils.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = AppDateUtils.today();

  String _selectedMealType = 'breakfast';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  bool _saving = false;

  static const List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _addEntry(List<DietEntryModel> entries) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter a food name');
      return;
    }
    final calories = double.tryParse(_caloriesController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;

    setState(() => _saving = true);
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final entry = DietEntryModel(
        id: id,
        name: name,
        mealType: _selectedMealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        date: AppDateUtils.formatDate(_selectedDate),
      );
      await FirestoreService.saveMeal(entry.toMap());
      if (!mounted) return;
      setState(() {
        _nameController.clear();
        _caloriesController.clear();
        _proteinController.clear();
        _carbsController.clear();
        _fatController.clear();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food added!'), backgroundColor: AppColors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Failed to add food entry');
    }
  }

  Future<void> _deleteEntry(DietEntryModel entry) async {
    try {
      await FirestoreService.deleteMeal(entry.id);
    } catch (e) {
      _showError('Failed to delete entry');
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
        stream: FirestoreService.dietStream(AppDateUtils.formatDate(_selectedDate)),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final entries = docs.map((doc) => DietEntryModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
          final loading = snapshot.connectionState == ConnectionState.waiting;

          return Column(
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
                    Tab(text: 'Add Food'),
                    Tab(text: 'Summary'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAddFoodTab(entries, loading),
                    _buildSummaryTab(entries, loading),
                  ],
                ),
              ),
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

  Widget _buildAddFoodTab(List<DietEntryModel> entries, bool loading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meal Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          _buildMealTypeSelector(),
          const SizedBox(height: 16),
          const Text(
            'Food Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'e.g. Chicken Breast'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nutrition',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _macroInput(_caloriesController, 'Calories', 'kcal')),
              const SizedBox(width: 8),
              Expanded(child: _macroInput(_proteinController, 'Protein', 'g')),
              const SizedBox(width: 8),
              Expanded(child: _macroInput(_carbsController, 'Carbs', 'g')),
              const SizedBox(width: 8),
              Expanded(child: _macroInput(_fatController, 'Fat', 'g')),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _addEntry(entries),
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
                      'Add to Log',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Today's Log",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          if (loading)
            const Center(child: CircularProgressIndicator(color: AppColors.navy))
          else if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No food logged yet',
                style: TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...entries.map((e) => _buildFoodListItem(e)),
        ],
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Wrap(
      spacing: 8,
      children: _mealTypes.map((meal) {
        final selected = _selectedMealType == meal;
        return GestureDetector(
          onTap: () => setState(() => _selectedMealType = meal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.navy : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.navy : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              _capitalize(meal),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _macroInput(TextEditingController ctrl, String label, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: unit,
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodListItem(DietEntryModel entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${_capitalize(entry.mealType)} · ${entry.calories.toStringAsFixed(0)} kcal · P:${entry.protein.toStringAsFixed(0)}g C:${entry.carbs.toStringAsFixed(0)}g F:${entry.fat.toStringAsFixed(0)}g',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.muted, size: 18),
            onPressed: () => _deleteEntry(entry),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(List<DietEntryModel> entries, bool loading) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.navy));
    }
    final totalCalories = entries.fold<double>(0, (s, e) => s + e.calories);
    final totalProtein = entries.fold<double>(0, (s, e) => s + e.protein);
    final totalCarbs = entries.fold<double>(0, (s, e) => s + e.carbs);
    final totalFat = entries.fold<double>(0, (s, e) => s + e.fat);

    final Map<String, List<DietEntryModel>> byMeal = {};
    for (final entry in entries) {
      byMeal.putIfAbsent(entry.mealType, () => []).add(entry);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCalorieCard(totalCalories),
          const SizedBox(height: 16),
          _buildMacroChips(totalProtein, totalCarbs, totalFat),
          const SizedBox(height: 20),
          _buildMealBreakdown(byMeal),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(double totalCalories) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            totalCalories.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'calories today',
            style: TextStyle(color: Color(0xFF8BA3BE), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChips(double totalProtein, double totalCarbs, double totalFat) {
    return Row(
      children: [
        Expanded(child: _macroChip('Protein', totalProtein, 'g', AppColors.blue)),
        const SizedBox(width: 10),
        Expanded(child: _macroChip('Carbs', totalCarbs, 'g', AppColors.orange)),
        const SizedBox(width: 10),
        Expanded(child: _macroChip('Fat', totalFat, 'g', AppColors.red)),
      ],
    );
  }

  Widget _macroChip(String label, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildMealBreakdown(Map<String, List<DietEntryModel>> byMeal) {
    if (byMeal.isEmpty) {
      return const Center(
        child: Text('No food logged yet', style: TextStyle(color: AppColors.muted)),
      );
    }
    final mealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
    final sortedMeals = byMeal.keys.toList()
      ..sort((a, b) => mealOrder.indexOf(a).compareTo(mealOrder.indexOf(b)));

    return Column(
      children: sortedMeals.map((meal) {
        final items = byMeal[meal]!;
        final totalKcal = items.fold<double>(0, (s, e) => s + e.calories);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _capitalize(meal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      '${totalKcal.toStringAsFixed(0)} kcal',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...items.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${e.calories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
