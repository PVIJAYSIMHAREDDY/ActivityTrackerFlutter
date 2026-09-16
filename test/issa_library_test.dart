import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:activity_tracker/services/issa_library.dart';
import 'package:activity_tracker/services/local_coach_service.dart';
import 'package:activity_tracker/services/adaptive_plan_service.dart';
import 'package:activity_tracker/models/body_stats_model.dart';
import 'package:activity_tracker/models/coaching_preferences.dart';
import 'package:activity_tracker/screens/issa_library_screen.dart';

void main() {
  final fixture = IssaLibrary(const [
    IssaBook('strength', 'Strength and Conditioning', 'strength.pdf', [
      '',
      'Progressive overload changes training demands gradually.',
      'Recovery follows training. A balanced plan includes rest.',
    ]),
    IssaBook('nutrition', 'Sports Nutrition', 'nutrition.pdf', [
      'Protein supports recovery. Protein is a nutrient.',
      'Hydration requirements depend on individual conditions.',
    ]),
  ]);
  test(
    'Retrieval preserves PDF numbering, filters courses, and rejects unrelated queries',
    () {
      expect(fixture.search('What is progressive overload?').single.page, 2);
      expect(fixture.search('recovery'), hasLength(2));
      expect(
        fixture.search('recovery', bookId: 'nutrition').single.book.id,
        'nutrition',
      );
      expect(fixture.search('protein overload'), isEmpty);
      expect(fixture.search('the and my'), isEmpty);
      expect(fixture.search('unknownword'), isEmpty);
      expect(fixture.search('protein', limit: 0), isEmpty);
    },
  );
  test('All six supplied books have searchable full-text pages', () {
    final library = IssaLibrary.fromJson(
      File('assets/coaching/issa_library.json').readAsStringSync(),
    );
    expect(library.books, hasLength(6));
    expect(library.books.fold<int>(0, (n, b) => n + b.pages.length), 2451);
    expect(library.searchablePages, greaterThan(2400));
    for (final book in library.books) {
      expect(
        library.search('training', bookId: book.id),
        isNotEmpty,
        reason: book.title,
      );
    }
    for (final topic in [
      'periodization',
      'hypertrophy',
      'hydration',
      'motivation',
      'assessment',
    ]) {
      final results = library.search(topic);
      expect(results, isNotEmpty, reason: topic);
      for (final result in results) {
        expect(
          result.book.pages[result.page - 1].toLowerCase(),
          contains(topic),
        );
      }
    }
  });
  test(
    'Source answers work without a profile but cannot override referral safeguards',
    () async {
      final answer = await LocalCoachService.replyWithSources(
        'What is protein?',
        null,
        library: fixture,
      );
      expect(answer.passages.single.book.id, 'nutrition');
      expect(answer.text, isNot(contains('Set up your body profile')));
      final stats = BodyStats.defaults();
      for (final query in [
        'chest pain',
        'protein for diabetes',
        'creatine dosage',
      ]) {
        final answer = await LocalCoachService.replyWithSources(
          query,
          stats,
          library: fixture,
        );
        expect(answer.passages, isEmpty);
      }
      final plan = AdaptivePlanService.generate(
        stats,
        preferences: const CoachingPreferences(pain: true),
      );
      final paused = await LocalCoachService.replyWithSources(
        'protein',
        stats,
        plan: plan,
        library: fixture,
      );
      expect(paused.passages, isEmpty);
      expect(paused.text, contains('paused'));
    },
  );
  for (final width in [360.0, 1280.0]) {
    testWidgets('Library search and reader navigation work at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: IssaLibraryScreen(library: Future.value(fixture))),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'progressive overload');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        find.text('Strength and Conditioning · PDF page 2'),
        findsOneWidget,
      );
      await tester.tap(find.text('Read source page'));
      await tester.pumpAndSettle();
      expect(
        find.text('Progressive overload changes training demands gradually.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
      expect(
        find.text('Recovery follows training. A balanced plan includes rest.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
