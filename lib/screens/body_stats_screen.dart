import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/body_stats_model.dart';
import '../services/coach_service.dart';
import '../theme.dart';

class BodyStatsScreen extends StatefulWidget {
  const BodyStatsScreen({super.key});

  @override
  State<BodyStatsScreen> createState() => _BodyStatsScreenState();
}

class _BodyStatsScreenState extends State<BodyStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BodyStats _stats = BodyStats.defaults();
  bool _loading = true;

  // -- Tab 1: Profile form controllers
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bfCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  // -- Tab 2: Weight log
  final _logWeightCtrl = TextEditingController();
  bool _addingWeight = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    _bfCtrl.dispose();
    _phoneCtrl.dispose();
    _logWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final loaded = await BodyStats.load();
    final stats = loaded ?? BodyStats.defaults();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
      _populateControllers(stats);
    });
  }

  void _populateControllers(BodyStats stats) {
    _heightCtrl.text = stats.heightCm == 0 ? '' : stats.heightCm.toStringAsFixed(1);
    _weightCtrl.text = stats.weightKg == 0 ? '' : stats.weightKg.toStringAsFixed(1);
    _ageCtrl.text = stats.age == 0 ? '' : stats.age.toString();
    _bfCtrl.text = stats.bodyFatPercent == 0 ? '' : stats.bodyFatPercent.toStringAsFixed(1);
    _phoneCtrl.text = stats.phoneNumber;
  }

  Future<void> _saveProfile() async {
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    final age = int.tryParse(_ageCtrl.text.trim());
    if (height == null || height <= 0) {
      _showError('Please enter a valid height.');
      return;
    }
    if (weight == null || weight <= 0) {
      _showError('Please enter a valid weight.');
      return;
    }
    if (age == null || age <= 0 || age > 120) {
      _showError('Please enter a valid age.');
      return;
    }
    final bf = double.tryParse(_bfCtrl.text.trim()) ?? 0.0;
    setState(() => _saving = true);

    final updated = _stats.copyWith(
      heightCm: height,
      weightKg: weight,
      age: age,
      bodyFatPercent: bf,
      phoneNumber: _phoneCtrl.text.trim(),
    );
    await updated.save();
    if (mounted) {
      setState(() {
        _stats = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _addWeightEntry() async {
    final weight = double.tryParse(_logWeightCtrl.text.trim());
    if (weight == null || weight <= 0) {
      _showError('Please enter a valid weight.');
      return;
    }
    setState(() => _addingWeight = true);

    final newEntry = WeightEntry(date: DateTime.now(), weightKg: weight);
    final updatedHistory = List<WeightEntry>.from(_stats.weightHistory)
      ..add(newEntry)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Keep last 52 entries (roughly 1 year of weekly logs)
    final trimmed = updatedHistory.length > 52
        ? updatedHistory.sublist(updatedHistory.length - 52)
        : updatedHistory;

    final updated = _stats.copyWith(
      weightKg: weight,
      weightHistory: trimmed,
    );
    await updated.save();
    if (mounted) {
      setState(() {
        _stats = updated;
        _logWeightCtrl.clear();
        _weightCtrl.text = weight.toStringAsFixed(1);
        _addingWeight = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weight logged!'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.red),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.navy)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            color: AppColors.navy,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF8BA3BE),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Body Profile'),
                Tab(text: 'Weight Log'),
                Tab(text: 'Progress Chart'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildWeightLogTab(),
                _buildProgressChartTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Body Profile
  // ---------------------------------------------------------------------------

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Basic Measurements'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _labeledField(
                  label: 'Height (cm)',
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'e.g. 175'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledField(
                  label: 'Weight (kg)',
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'e.g. 75.0'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _labeledField(
                  label: 'Age',
                  child: TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'e.g. 28'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _labeledField(
                  label: 'Body Fat % (optional)',
                  child: TextField(
                    controller: _bfCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: '? if unknown'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _labeledField(
            label: 'Phone Number',
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+91 9876543210'),
            ),
          ),

          const SizedBox(height: 20),
          _sectionTitle('Gender'),
          const SizedBox(height: 10),
          Row(
            children: [
              _genderChip('male', 'Male', Icons.male),
              const SizedBox(width: 12),
              _genderChip('female', 'Female', Icons.female),
            ],
          ),

          const SizedBox(height: 20),
          _sectionTitle('Activity Level'),
          const SizedBox(height: 10),
          _buildActivitySelector(),

          const SizedBox(height: 20),
          _sectionTitle('Goal'),
          const SizedBox(height: 10),
          _buildGoalSelector(),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Profile',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 24),
          _buildCalculatedStats(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _genderChip(String value, String label, IconData icon) {
    final selected = _stats.gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _stats = _stats.copyWith(gender: value)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.navy : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.muted, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySelector() {
    const levels = [
      {
        'value': 'sedentary',
        'label': 'Sedentary',
        'icon': Icons.chair_alt,
        'desc': 'Little or no exercise',
      },
      {
        'value': 'light',
        'label': 'Light',
        'icon': Icons.directions_walk,
        'desc': '1-3 days/week',
      },
      {
        'value': 'moderate',
        'label': 'Moderate',
        'icon': Icons.directions_run,
        'desc': '3-5 days/week',
      },
      {
        'value': 'active',
        'label': 'Active',
        'icon': Icons.fitness_center,
        'desc': '6-7 days/week',
      },
      {
        'value': 'athlete',
        'label': 'Athlete',
        'icon': Icons.sports,
        'desc': '2x/day training',
      },
    ];

    return Column(
      children: levels.map((level) {
        final value = level['value'] as String;
        final selected = _stats.activityLevel == value;
        return GestureDetector(
          onTap: () =>
              setState(() => _stats = _stats.copyWith(activityLevel: value)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.navy : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.navy : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  level['icon'] as IconData,
                  color: selected ? Colors.white : AppColors.blue,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      Text(
                        level['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Colors.white70
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGoalSelector() {
    const goals = [
      {
        'value': 'fat_loss',
        'label': 'Fat Loss',
        'emoji': '🔥',
        'desc': 'Reduce body fat while preserving muscle',
        'color': AppColors.red,
      },
      {
        'value': 'maintain',
        'label': 'Maintain',
        'emoji': '⚖️',
        'desc': 'Keep current weight and improve fitness',
        'color': AppColors.blue,
      },
      {
        'value': 'muscle_gain',
        'label': 'Muscle Gain',
        'emoji': '💪',
        'desc': 'Build mass with a lean bulk approach',
        'color': AppColors.green,
      },
      {
        'value': 'recomp',
        'label': 'Body Recomp',
        'emoji': '🔄',
        'desc': 'Lose fat and gain muscle simultaneously',
        'color': AppColors.purple,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: goals.map((goal) {
        final value = goal['value'] as String;
        final color = goal['color'] as Color;
        final selected = _stats.goal == value;
        return GestureDetector(
          onTap: () =>
              setState(() => _stats = _stats.copyWith(goal: value)),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? color : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? color : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(goal['emoji'] as String,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  goal['label'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  goal['desc'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected ? Colors.white70 : AppColors.muted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalculatedStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calculated Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statBox('BMI', _stats.bmi.toStringAsFixed(1), _bmiLabel(_stats.bmi)),
              const SizedBox(width: 10),
              _statBox('TDEE', '${_stats.tdee.toStringAsFixed(0)} kcal', 'Maintenance'),
            ],
          ),
          const SizedBox(height: 10),
          _statBox(
              'Target Calories',
              '${_stats.targetCalories.toStringAsFixed(0)} kcal',
              _goalLabel(_stats.goal),
              fullWidth: true),
          const SizedBox(height: 10),
          Row(
            children: [
              _statBox(
                  'Protein',
                  '${_stats.targetProtein.toStringAsFixed(0)}g',
                  'per day'),
              const SizedBox(width: 10),
              _statBox(
                  'Carbs',
                  '${_stats.targetCarbs.toStringAsFixed(0)}g',
                  'per day'),
              const SizedBox(width: 10),
              _statBox(
                  'Fat',
                  '${_stats.targetFat.toStringAsFixed(0)}g',
                  'per day'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, String sub,
      {bool fullWidth = false}) {
    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(sub,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: inner) : Expanded(child: inner);
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'fat_loss':
        return 'Caloric Deficit (20%)';
      case 'muscle_gain':
        return 'Caloric Surplus (10%)';
      case 'recomp':
        return 'Slight Deficit (5%)';
      default:
        return 'Maintenance';
    }
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Weight Log
  // ---------------------------------------------------------------------------

  Widget _buildWeightLogTab() {
    final sortedHistory = List<WeightEntry>.from(_stats.weightHistory)
      ..sort((a, b) => b.date.compareTo(a.date));
    final last12 = sortedHistory.take(12).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weigh-in reminder banner
          if (_stats.needsWeightUpdate)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orange, width: 1.5),
              ),
              child: const Row(
                children: [
                  Text('⏰', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Time for your weekly weigh-in! Log your current weight to keep your progress on track.',
                      style: TextStyle(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Log today's weight card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log Today\'s Weight',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _logWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 74.5',
                          suffixText: 'kg',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _addingWeight ? null : _addWeightEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      child: _addingWeight
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Add',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _sectionTitle('Recent Entries'),
          const SizedBox(height: 10),

          if (last12.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Text('⚖️', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'No weight entries yet.\nLog your first weigh-in above!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(last12.length, (i) {
              final entry = last12[i];
              double? delta;
              if (i < last12.length - 1) {
                delta = entry.weightKg - last12[i + 1].weightKg;
              }
              return _buildWeightEntryRow(entry, delta);
            }),
        ],
      ),
    );
  }

  Widget _buildWeightEntryRow(WeightEntry entry, double? delta) {
    final dateStr =
        DateFormat('EEE, MMM d yyyy').format(entry.date);
    Widget deltaWidget = const SizedBox.shrink();
    if (delta != null) {
      final isLoss = delta < 0;
      final isNeutral = delta.abs() < 0.05;
      deltaWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isNeutral)
            Icon(
              isLoss ? Icons.arrow_downward : Icons.arrow_upward,
              size: 14,
              color: isLoss ? AppColors.green : AppColors.red,
            ),
          Text(
            isNeutral
                ? '—'
                : '${delta.abs().toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isNeutral
                  ? AppColors.muted
                  : (isLoss ? AppColors.green : AppColors.red),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateStr,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 13),
            ),
          ),
          Text(
            '${entry.weightKg.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 12),
          deltaWidget,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Progress Chart
  // ---------------------------------------------------------------------------

  Widget _buildProgressChartTab() {
    final sorted = List<WeightEntry>.from(_stats.weightHistory)
      ..sort((a, b) => a.date.compareTo(b.date));
    final chartData = sorted.take(24).toList();

    final insight = CoachService.getProgressInsight(_stats);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Weight Progress'),
          const SizedBox(height: 12),
          if (chartData.length < 2)
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📈', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text(
                      'Log at least 2 weight entries\nto see your progress chart.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildChart(chartData),

          const SizedBox(height: 20),
          _buildProgressSummary(sorted),

          const SizedBox(height: 20),
          _buildInsightCard(insight),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChart(List<WeightEntry> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.weightKg);
    }).toList();

    final weights = data.map((e) => e.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxW - minW) < 1.0 ? 1.5 : 1.0;
    final minY = minW - padding;
    final maxY = maxW + padding;

    // Goal weight line for fat_loss / muscle_gain
    double? goalWeight;
    if (_stats.goal == 'fat_loss') {
      goalWeight = weights.first * 0.90; // indicative goal: 10% loss
    } else if (_stats.goal == 'muscle_gain') {
      goalWeight = weights.first * 1.05; // indicative goal: 5% gain
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: const Color(0xFFE2E8F0),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
              left: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.muted),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: data.length > 8
                    ? (data.length / 4).ceil().toDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final label =
                      DateFormat('MMM dd').format(data[idx].date);
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.muted),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          extraLinesData: goalWeight != null &&
                  goalWeight >= minY &&
                  goalWeight <= maxY
              ? ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: goalWeight,
                      color: AppColors.orange.withOpacity(0.7),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                        labelResolver: (_) => 'Goal',
                      ),
                    ),
                  ],
                )
              : null,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: AppColors.navy,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.navy,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.navy.withOpacity(0.08),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.navy,
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.spotIndex;
                if (idx < 0 || idx >= data.length) return null;
                final entry = data[idx];
                return LineTooltipItem(
                  '${DateFormat('MMM dd').format(entry.date)}\n${entry.weightKg.toStringAsFixed(1)} kg',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary(List<WeightEntry> sorted) {
    if (sorted.isEmpty) return const SizedBox.shrink();

    final start = sorted.first;
    final current = sorted.last;
    final totalDelta = current.weightKg - start.weightKg;
    final weekCount = sorted.length;
    final daysTracked =
        current.date.difference(start.date).inDays;
    final weeksTracked = (daysTracked / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryItem(
                  'Start', '${start.weightKg.toStringAsFixed(1)} kg'),
              _summaryItem(
                  'Current', '${current.weightKg.toStringAsFixed(1)} kg'),
              _summaryItem(
                  'Change',
                  '${totalDelta >= 0 ? '+' : ''}${totalDelta.toStringAsFixed(1)} kg',
                  color: totalDelta < 0 ? AppColors.green : AppColors.red),
              _summaryItem(
                  'Entries',
                  '$weekCount',
                  color: AppColors.blue),
            ],
          ),
          if (weeksTracked > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Tracked over $weeksTracked week${weeksTracked == 1 ? '' : 's'}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String insight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Coach Insight',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
