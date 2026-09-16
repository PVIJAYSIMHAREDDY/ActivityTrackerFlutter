import '../screens/issa_library_screen.dart';
import 'package:flutter/material.dart';
import '../services/adaptive_plan_service.dart';
import '../services/coaching_knowledge.dart';

class CoachingPlanView extends StatefulWidget {
  final AdaptivePlan plan;
  const CoachingPlanView({super.key, required this.plan});
  @override
  State<CoachingPlanView> createState() => _CoachingPlanViewState();
}

class _CoachingPlanViewState extends State<CoachingPlanView> {
  String section = 'Overview';
  Widget card(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
  Widget paragraph(String text) =>
      Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text));
  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ['Overview', 'Nutrition', 'Training', 'Sources']
              .map(
                (s) => ChoiceChip(
                  label: Text(s),
                  selected: section == s,
                  onSelected: (_) => setState(() => section = s),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        if (section == 'Overview') ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF142D4E), Color(0xFF246B78)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR COACHING WEEK',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  plan.phase,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final label in [
                      plan.preferences.experience,
                      plan.preferences.equipment,
                      '${plan.preferences.minutes} min sessions',
                      plan.preferences.fresh(plan.generatedAt)
                          ? 'Check-in up to date'
                          : 'Weekly check-in due',
                    ])
                      Chip(label: Text(label)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This week: ${plan.preferences.habit}',
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!plan.needsReview)
            card('Today’s session', [
              paragraph(plan.workouts[plan.generatedAt.weekday - 1]),
              TextButton(
                onPressed: () => setState(() => section = 'Training'),
                child: const Text('View your training week'),
              ),
            ]),
          card(plan.phase, plan.reasons.map(paragraph).toList()),
          card(
            'Your weekly coaching review',
            plan.review.map(paragraph).toList(),
          ),
        ],
        if (section == 'Nutrition' && !plan.needsReview) ...[
          card('Daily estimated targets', [
            Text(
              plan.stats.units.energy(plan.stats.targetCalories),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            paragraph(
              'Protein ${plan.stats.units.food(plan.stats.targetProtein)}  •  Carbs ${plan.stats.units.food(plan.stats.targetCarbs)}  •  Fat ${plan.stats.units.food(plan.stats.targetFat)}',
            ),
            paragraph(
              'Portions are edible ${plan.stats.units.foodUnit} in the state listed. Values are illustrative estimates; check your product labels. Meal macros may differ from the targets.',
            ),
          ]),
          for (final day in plan.mealDays)
            Card(
              child: ExpansionTile(
                title: Text(day.day),
                subtitle: Text(
                  '${plan.stats.units.energy(day.calories)} • ${plan.stats.units.food(day.protein)} protein',
                ),
                childrenPadding: const EdgeInsets.all(16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final meal in day.meals)
                    paragraph(meal.display(plan.stats.units)),
                  paragraph(
                    'Protein difference from target: ${plan.stats.units.food(day.protein - plan.stats.targetProtein)}. Adjust food choices and portions with appropriate guidance if needed.',
                  ),
                ],
              ),
            ),
          card('Shopping for the week', plan.shopping.map(paragraph).toList()),
          card('Food preparation', [
            paragraph(
              'Use the cooked weights listed for grains, pulses, meat and fish; oats are weighed dry. Cook animal foods appropriately. Prepare grains and proteins in batches, combine with vegetables, and use fruit or yogurt for simple breakfasts and snacks. Ingredient exclusions do not verify manufacturing cross-contact.',
            ),
          ]),
        ],
        if (section == 'Training' && !plan.needsReview) ...[
          card('Train with control', [
            paragraph(
              '${plan.preferences.experience} • ${plan.preferences.equipment} • up to ${plan.preferences.minutes} minutes per session',
            ),
            paragraph(
              'Choose resistance that leaves a few comfortable repetitions available. Complete the warm-up and follow the movement cues. A completed workout log does not establish correct technique.',
            ),
          ]),
          for (final day in plan.workouts)
            Card(
              child: ExpansionTile(
                title: Text(day.split(':').first),
                subtitle: Text(
                  day.split('\n').first.split(':').skip(1).join(':').trim(),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [Text(day)],
              ),
            ),
        ],
        if (plan.needsReview &&
            (section == 'Training' || section == 'Nutrition'))
          card('Professional review needed', [
            paragraph(
              'Your assessment reports symptoms or condition-specific needs. Personalized prescriptions are paused. Bring your exported assessment to a qualified clinician, trainer or dietitian.',
            ),
          ]),
        if (section == 'Sources') ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Search all six textbooks'),
              subtitle: const Text(
                'Explore the full extracted text with PDF page references',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IssaLibraryScreen()),
              ),
            ),
          ),
          card('How this coach uses your textbooks', [
            paragraph(
              'Selected principles from the six supplied ISSA textbooks inform these original summaries. The app is not ISSA-certified or endorsed, and the books have not been used to train a live AI model. Exact meal values, progression thresholds and schedules are app implementations, not validated textbook prescriptions.',
            ),
          ]),
          for (final ref in CoachingKnowledge.references)
            card(ref.title, [
              paragraph(ref.principle),
              SelectableText('PDF pages ${ref.pages}\n${ref.file}'),
            ]),
          card('Current general guidance', [
            const SelectableText(
              'CDC Adult Activity Overview\nhttps://www.cdc.gov/physical-activity-basics/guidelines/adults.html\n\nNIDDK Body Weight Planner\nhttps://www.niddk.nih.gov/health-information/weight-management/body-weight-planner',
            ),
            paragraph(
              'Reviewed September 11, 2026. General guidance does not establish an individual’s readiness or calorie requirements.',
            ),
          ]),
        ],
      ],
    );
  }
}
