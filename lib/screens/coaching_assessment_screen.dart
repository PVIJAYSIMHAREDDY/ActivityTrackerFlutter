import 'package:flutter/material.dart';
import '../models/coaching_preferences.dart';

class CoachingAssessmentScreen extends StatefulWidget {
  final CoachingPreferences initial;
  const CoachingAssessmentScreen({super.key, required this.initial});
  @override
  State<CoachingAssessmentScreen> createState() =>
      _CoachingAssessmentScreenState();
}

class _CoachingAssessmentScreenState extends State<CoachingAssessmentScreen> {
  late String experience, equipment, recovery, habit;
  late int sessions, minutes;
  late bool pain, medical;
  bool checked = false;
  late Set<String> exclusions;
  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    experience = p.experience;
    equipment = p.equipment;
    recovery = p.recovery;
    habit = p.habit;
    sessions = p.sessions;
    minutes = p.minutes;
    pain = p.pain;
    medical = p.medical;
    exclusions = p.exclusions.toSet();
  }

  Widget choice(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => change(v));
      },
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Assessment & weekly check-in')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Build a plan around your life',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Your answers guide the workload, food choices and weekly review. Update them when your circumstances change.',
        ),
        const SizedBox(height: 20),
        choice('Training experience', experience, [
          'Beginner',
          'Intermediate',
          'Experienced',
        ], (v) => experience = v),
        choice('Available equipment', equipment, [
          'Bodyweight',
          'Dumbbells',
          'Gym',
        ], (v) => equipment = v),
        choice(
          'Available strength days each week',
          '$sessions',
          ['2', '3', '4'],
          (v) => sessions = int.parse(v),
        ),
        const Text(
          'Beginners start with at most three strength days. Completed goals use two maintenance sessions.',
        ),
        const SizedBox(height: 12),
        Text('Time available: $minutes minutes'),
        Slider(
          value: minutes.toDouble(),
          min: 20,
          max: 60,
          divisions: 8,
          label: '$minutes minutes',
          onChanged: (v) => setState(() => minutes = v.round()),
        ),
        const SizedBox(height: 12),
        choice(
          'How is your recovery this week?',
          recovery,
          ['Not checked', 'Recovered', 'Tired'],
          (v) {
            recovery = v;
            checked = true;
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Confirm this is my current weekly recovery check-in',
          ),
          value: checked,
          onChanged: (v) => setState(() => checked = v ?? false),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'I currently have pain, numbness or a movement-related symptom',
          ),
          value: pain,
          onChanged: (v) => setState(() => pain = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I need condition-specific guidance'),
          subtitle: const Text(
            'For example, pregnancy, an injury, an eating disorder or medical exercise/diet restrictions.',
          ),
          value: medical,
          onChanged: (v) => setState(() => medical = v),
        ),
        if (pain || medical)
          const Text(
            'Automatic prescriptions will pause. Discuss appropriate exercise and nutrition with a qualified professional. You can still export your assessment and review notes.',
          ),
        const SizedBox(height: 20),
        const Text(
          'Ingredient groups to exclude',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Filters apply to this app’s ingredient catalog. Always check packaging and cross-contact risks; unlisted allergies need individual review.',
        ),
        Wrap(
          spacing: 8,
          children: ['Milk', 'Soy', 'Gluten', 'Fish', 'Seeds']
              .map(
                (a) => FilterChip(
                  label: Text(a),
                  selected: exclusions.contains(a),
                  onSelected: (v) => setState(() {
                    if (v) {
                      exclusions.add(a);
                    } else {
                      exclusions.remove(a);
                    }
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        choice('One achievable action this week', habit, [
          'Prepare tomorrow’s breakfast',
          'Schedule my training days',
          'Log meals consistently',
          'Keep a regular bedtime',
          'Take a short movement break',
        ], (v) => habit = v),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => Navigator.pop(
            context,
            CoachingPreferences(
              experience: experience,
              equipment: equipment,
              recovery: recovery,
              habit: habit,
              sessions: sessions,
              minutes: minutes,
              exclusions: exclusions.toList(),
              pain: pain,
              medical: medical,
              checkedAt: checked ? DateTime.now() : widget.initial.checkedAt,
            ),
          ),
          icon: const Icon(Icons.check),
          label: const Text('Save assessment and update plan'),
        ),
      ],
    ),
  );
}
