import 'issa_library_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/body_stats_model.dart';
import '../models/goal_model.dart';
import '../services/firestore_service.dart';
import '../services/adaptive_plan_service.dart';
import '../services/word_plan_export.dart';
import 'body_stats_screen.dart';
import 'coaching_assessment_screen.dart';
import 'ai_coach_chat_screen.dart';
import '../models/coaching_preferences.dart';
import '../widgets/coaching_plan_view.dart';
import '../services/plan_export_service.dart';

class AdaptivePlanScreen extends StatefulWidget {
  const AdaptivePlanScreen({super.key});
  @override
  State<AdaptivePlanScreen> createState() => _AdaptivePlanScreenState();
}

class _AdaptivePlanScreenState extends State<AdaptivePlanScreen> {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  BodyStats? _stats;
  List<GoalModel> _goals = [];
  String _diet = 'Vegetarian';
  CoachingPreferences _preferences = const CoachingPreferences();
  int? _strengthDays;
  String? _goalId;
  String? _error;
  bool _busy = false;
  bool _bodyReady = false, _goalsReady = false, _settingsReady = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _failed(Object error) {
    if (mounted) {
      setState(
        () => _error =
            'Could not load the latest plan data. Check your connection and retry.',
      );
    }
  }

  void _subscribe() {
    _subscriptions.add(
      FirestoreService.recentWorkoutsStream().listen((snapshot) {
        if (!mounted) return;
        final dates = <String>{};
        for (final doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data() as Map);
          if (data['type']?.toString().toLowerCase() == 'strength') {
            dates.add(data['date'].toString());
          }
        }
        setState(() => _strengthDays = dates.length);
      }, onError: _failed),
    );
    _subscriptions.add(
      FirestoreService.bodyStatsStream().listen((snapshot) {
        if (!mounted) return;
        setState(() {
          _stats = snapshot.data() == null
              ? null
              : BodyStats.fromJson(snapshot.data()!);
          _bodyReady = true;
        });
      }, onError: _failed),
    );
    _subscriptions.add(
      FirestoreService.goalsStream().listen((snapshot) {
        if (!mounted) return;
        setState(() {
          _goals = snapshot.docs
              .map(
                (d) => GoalModel.fromFirestore(
                  Map<String, dynamic>.from(d.data() as Map),
                  d.id,
                ),
              )
              .where(
                (g) =>
                    g.category.toLowerCase() == 'fitness' && g.targetValue > 0,
              )
              .toList();
          _goalsReady = true;
        });
      }, onError: _failed),
    );
    _subscriptions.add(
      FirestoreService.profileStream().listen((snapshot) {
        if (!mounted) return;
        final data = snapshot.data() ?? {};
        setState(() {
          final diet = data['planDiet'];
          _diet = ['Vegetarian', 'Mixed diet', 'Vegan'].contains(diet)
              ? diet as String
              : 'Vegetarian';
          _goalId = data['planGoalId'] as String?;
          _preferences = CoachingPreferences.fromMap(
            Map<String, dynamic>.from(data['coaching'] as Map? ?? {}),
          );
          _settingsReady = true;
        });
      }, onError: _failed),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _saveSettings(String diet, String? goalId) async {
    setState(() => _busy = true);
    try {
      await FirestoreService.saveProfile({
        'planDiet': diet,
        'planGoalId': goalId,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save plan preferences. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(AdaptivePlan plan, String type) async {
    setState(() => _busy = true);
    try {
      final message = await WordPlanExport.save(plan, type);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the document. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assessment() async {
    final next = await Navigator.push<CoachingPreferences>(
      context,
      MaterialPageRoute(
        builder: (_) => CoachingAssessmentScreen(initial: _preferences),
      ),
    );
    if (next == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await FirestoreService.saveProfile({'coaching': next.toMap()});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assessment could not be saved. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pdf(AdaptivePlan plan) async {
    setState(() => _busy = true);
    try {
      await PlanExportService.shareAdaptive(plan, 'full');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF could not be saved. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openLibrary() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const IssaLibraryScreen()),
  );

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(
              onPressed: () async {
                for (final s in _subscriptions) {
                  await s.cancel();
                }
                _subscriptions.clear();
                if (!mounted) return;
                setState(() {
                  _error = null;
                  _bodyReady = false;
                  _goalsReady = false;
                  _settingsReady = false;
                });
                _subscribe();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (!_bodyReady || !_goalsReady || !_settingsReady) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_stats == null) {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.sports_gymnastics, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'Build your coaching foundation',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Start with your body profile, then tell your coach about your experience, equipment and recovery. Your weekly plan brings training, meals and habits together.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BodyStatsScreen()),
                  ),
                  label: const Text('Set up body profile'),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.menu_book_outlined),
                  onPressed: _openLibrary,
                  label: const Text('Explore the ISSA library'),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final matches = _goals.where((g) => g.id == _goalId);
      final goal = matches.isEmpty ? null : matches.first;
      AdaptivePlan? plan;
      try {
        plan = AdaptivePlanService.generate(
          _stats!,
          goal: goal,
          diet: _diet,
          preferences: _preferences,
          recentStrengthDays: _strengthDays,
        );
      } on ArgumentError {
        /* Show profile guidance below. */
      }
      final current = plan;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your training & nutrition coach',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Text(
            'A weekly plan built around your profile, recovery and goals, informed by your ISSA training library.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _assessment,
            icon: const Icon(Icons.tune),
            label: const Text('Assessment & weekly check-in'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiCoachChatScreen()),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Ask the fitness & nutrition coach'),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Your ISSA learning library'),
              subtitle: const Text(
                'Six complete text indexes · Search topics and read source pages',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openLibrary,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(_diet),
            initialValue: _diet,
            decoration: const InputDecoration(labelText: 'Diet preference'),
            items: [
              'Vegetarian',
              'Mixed diet',
              'Vegan',
            ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: _busy
                ? null
                : (d) {
                    if (d != null) _saveSettings(d, _goalId);
                  },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(goal?.id),
            initialValue: goal?.id ?? '',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Fitness goal for maintenance transition',
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('No linked goal')),
              ..._goals.map(
                (g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(g.title, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: _busy
                ? null
                : (id) => _saveSettings(_diet, id == '' ? null : id),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BodyStatsScreen()),
            ),
            child: const Text('Update body stats and weight'),
          ),
          if (current == null)
            const Text('Enter a valid adult body profile to generate a plan.')
          else ...[
            Wrap(
              spacing: 8,
              children: [
                for (final type in ['nutrition', 'workout', 'full'])
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _export(current, type),
                    icon: const Icon(Icons.download),
                    label: Text(
                      '${type == "nutrition"
                          ? "Diet"
                          : type == "workout"
                          ? "Workout"
                          : "Everything"} (.docx)',
                    ),
                  ),
              ],
            ),
            TextButton.icon(
              onPressed: _busy ? null : () => _pdf(current),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download everything as PDF'),
            ),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            CoachingPlanView(plan: current),
          ],
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaching'),
        actions: [
          IconButton(
            tooltip: 'ISSA learning library',
            onPressed: _openLibrary,
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: body,
        ),
      ),
    );
  }
}
