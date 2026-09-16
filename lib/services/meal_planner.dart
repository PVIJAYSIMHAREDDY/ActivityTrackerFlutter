import '../models/measurement_units.dart';

class PlanFood {
  final String name;
  final double protein, carbs, fat;
  final List<String> allergens;
  const PlanFood(
    this.name,
    this.protein,
    this.carbs,
    this.fat, [
    this.allergens = const [],
  ]);
  double get calories => protein * 4 + carbs * 4 + fat * 9;
}

class FoodPortion {
  final PlanFood food;
  final int grams;
  const FoodPortion(this.food, this.grams);
  double get calories => food.calories * grams / 100;
  double get protein => food.protein * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fat => food.fat * grams / 100;
  String get description => display(const MeasurementUnits());
  String display(MeasurementUnits units) =>
      '${food.name}: ${units.food(grams.toDouble())}';
}

class PlannedMeal {
  final String name;
  final List<FoodPortion> portions;
  const PlannedMeal(this.name, this.portions);
  double get calories => portions.fold(0, (a, b) => a + b.calories);
  double get protein => portions.fold(0, (a, b) => a + b.protein);
  double get carbs => portions.fold(0, (a, b) => a + b.carbs);
  double get fat => portions.fold(0, (a, b) => a + b.fat);
  String get description => display(const MeasurementUnits());
  String display(MeasurementUnits units) =>
      '$name: ${portions.map((p) => p.display(units)).join("; ")}. Approx. ${units.energy(calories)}, P ${units.food(protein)} / C ${units.food(carbs)} / F ${units.food(fat)}.';
}

class MealDay {
  final String day;
  final List<PlannedMeal> meals;
  const MealDay(this.day, this.meals);
  double get calories => meals.fold(0, (a, b) => a + b.calories);
  double get protein => meals.fold(0, (a, b) => a + b.protein);
  String get description => display(const MeasurementUnits());
  String display(MeasurementUnits units) =>
      '$day — ${units.energy(calories)}, ${units.food(protein)} protein\n${meals.map((m) => m.display(units)).join("\n")}';
}

class MealPlanner {
  // Illustrative rounded macro estimates per 100 g, not a verified food database.
  // Energy is calculated using 4/4/9 kcal per gram. Product labels take precedence.
  static const rice = PlanFood('rice, cooked', 2.7, 28, .3);
  static const oats = PlanFood('oats, dry', 13, 68, 7, ['Gluten']);
  static const potato = PlanFood('potato, cooked', 2, 20, .1);
  static const lentils = PlanFood('lentils, cooked', 9, 20, .4);
  static const beans = PlanFood('beans, cooked', 8, 22, .5);
  static const tofu = PlanFood('firm tofu', 15, 3, 8, ['Soy']);
  static const yogurt = PlanFood('plain Greek yogurt', 10, 4, 2, ['Milk']);
  static const chicken = PlanFood('chicken breast, cooked', 31, 0, 3.6);
  static const fish = PlanFood('white fish, cooked', 23, 0, 1, ['Fish']);
  static const vegetables = PlanFood('mixed non-starchy vegetables', 2, 7, .3);
  static const fruit = PlanFood('fresh fruit', .5, 15, .2);
  static const seeds = PlanFood('pumpkin seeds', 30, 11, 49, ['Seeds']);
  static const oil = PlanFood('olive oil', 0, 0, 100);
  static const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static List<MealDay> generate(
    double calories,
    double protein,
    String diet,
    List<String> exclusions,
  ) {
    bool allowed(PlanFood f) => !f.allergens.any(exclusions.contains);
    final proteins = [
      if (diet == 'Mixed diet') ...[chicken, fish],
      if (diet != 'Vegan') yogurt,
      tofu,
      lentils,
      beans,
    ].where(allowed).toList();
    final grains = [rice, potato, oats].where(allowed).toList();
    PlannedMeal make(String name, int index, double share) {
      final budget = calories * share;
      final breakfast = [
        if (diet != 'Vegan') yogurt,
        tofu,
        beans,
      ].where(allowed).toList();
      final mains = proteins.where((f) => f != yogurt).toList();
      final choices = name == 'Breakfast' || name == 'Snack'
          ? breakfast
          : mains;
      final source = choices[index % choices.length];
      final grain = grains[index % grains.length];
      final portions = <FoodPortion>[
        FoodPortion(
          source,
          (protein * share / source.protein * 100).clamp(80, 280).round(),
        ),
        FoodPortion(
          name == 'Breakfast' || name == 'Snack' ? fruit : vegetables,
          name == 'Snack' ? 100 : 150,
        ),
        if (name == 'Lunch' || name == 'Dinner') const FoodPortion(oil, 10),
        if (name == 'Snack' && allowed(seeds)) const FoodPortion(seeds, 15),
      ];
      final used = portions.fold<double>(0, (a, b) => a + b.calories);
      portions.add(
        FoodPortion(
          grain,
          ((budget - used) / grain.calories * 100).clamp(20, 350).round(),
        ),
      );
      final subtotal = portions.fold<double>(0, (a, b) => a + b.calories);
      return PlannedMeal(
        name,
        portions
            .map(
              (p) => FoodPortion(
                p.food,
                (p.grams * budget / subtotal).round().clamp(1, 600),
              ),
            )
            .toList(),
      );
    }

    return List.generate(
      7,
      (i) => MealDay(days[i], [
        make('Breakfast', i, .25),
        make('Lunch', i + 1, .35),
        make('Dinner', i + 2, .30),
        make('Snack', i + 3, .10),
      ]),
    );
  }

  static List<String> shopping(
    List<MealDay> days, [
    MeasurementUnits units = const MeasurementUnits(),
  ]) {
    final grams = <String, int>{};
    for (final d in days) {
      for (final m in d.meals) {
        for (final p in m.portions) {
          grams.update(
            p.food.name,
            (g) => g + p.grams,
            ifAbsent: () => p.grams,
          );
        }
      }
    }
    return grams.entries
        .map(
          (e) =>
              '${e.key}: ${units.food(e.value.toDouble())} for the week (weights as listed; cooked quantities differ from raw purchase weights)',
        )
        .toList();
  }
}
