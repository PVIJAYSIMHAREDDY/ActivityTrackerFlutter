import 'package:activity_tracker/screens/diet_screen.dart';
import 'package:activity_tracker/utils/date_utils.dart';
import 'package:activity_tracker/screens/body_stats_screen.dart';
import 'package:activity_tracker/models/measurement_units.dart';
import 'package:activity_tracker/services/coaching_context_service.dart';
import 'package:activity_tracker/models/coaching_preferences.dart';
import 'support/register_stub.dart'
    if (dart.library.js_interop) 'support/register_web.dart';
import 'package:activity_tracker/services/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:activity_tracker/main.dart';
import 'package:activity_tracker/services/auth_service.dart';
import 'package:activity_tracker/services/firestore_service.dart';
import 'package:activity_tracker/models/body_stats_model.dart';

// Run explicitly in Chrome with local emulators. Never contacts production.
void main() {
  const enabled = bool.fromEnvironment('RUN_EMULATOR_TESTS');
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Firebase emulator integration', () {
    late FirebaseAuth auth;
    late FirebaseFirestore db;
    setUpAll(() async {
      registerTestPlugins();
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'demo-key',
          appId: '1:123:web:demo',
          messagingSenderId: '123',
          projectId: 'demo-activity-tracker',
          authDomain: 'localhost',
        ),
      );
      auth = FirebaseAuth.instance;
      await auth.useAuthEmulator('127.0.0.1', 9099);
      db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: AppConfig.databaseId,
      );
      db.useFirestoreEmulator('127.0.0.1', 8080);
    });
    test(
      'Guest sign-in, all record types, deletion and account isolation',
      () async {
        await AuthService.continueAsGuest();
        final owner = auth.currentUser!.uid;
        await BodyStats.defaults().save();
        expect((await BodyStats.load())!.weightKg, 75);
        await FirestoreService.saveProfile({
          'displayName': 'Test profile',
          'photoBase64': null,
        });
        await FirestoreService.saveTask({
          'id': 'task',
          'text': 'Walk',
          'date': '2026-09-09',
          'done': false,
        });
        await FirestoreService.saveHabit({
          'id': 'habit',
          'name': 'Walk',
          'streak': 0,
          'lastDoneDate': '',
        });
        await FirestoreService.toggleHabit('habit', '2026-09-09');
        await FirestoreService.saveWorkout({
          'id': 'workout',
          'date': '2026-09-09',
          'type': 'strength',
          'durationMins': 30,
        });
        await FirestoreService.saveMeal({
          'id': 'meal',
          'date': '2026-09-09',
          'name': 'Lunch',
          'calories': 450,
        });
        await FirestoreService.saveGoal({
          'id': 'goal',
          'title': 'Walk regularly',
          'targetValue': 10,
          'currentValue': 1,
        });
        expect(
          (await FirestoreService.tasksStream('2026-09-09').first).docs,
          hasLength(1),
        );
        expect(
          (await FirestoreService.dietStream('2026-09-09').first).docs,
          hasLength(1),
        );
        expect(
          (await FirestoreService.workoutsStream('2026-09-09').first).docs,
          hasLength(1),
        );
        expect((await FirestoreService.goalsStream().first).docs, hasLength(1));
        final otherApp = await Firebase.initializeApp(
          name: 'other',
          options: Firebase.app().options,
        );
        final otherAuth = FirebaseAuth.instanceFor(app: otherApp);
        await otherAuth.useAuthEmulator('127.0.0.1', 9099);
        await otherAuth.signInAnonymously();
        final otherDb = FirebaseFirestore.instanceFor(
          app: otherApp,
          databaseId: AppConfig.databaseId,
        );
        otherDb.useFirestoreEmulator('127.0.0.1', 8080);
        await expectLater(
          otherDb
              .doc('users/$owner/profile/info')
              .get(const GetOptions(source: Source.server)),
          throwsA(
            isA<FirebaseException>().having(
              (e) => e.code,
              'code',
              'permission-denied',
            ),
          ),
        );
        await expectLater(
          otherDb.doc('users/$owner/tasks/attack').set({'text': 'no'}),
          throwsA(
            isA<FirebaseException>().having(
              (e) => e.code,
              'code',
              'permission-denied',
            ),
          ),
        );
        await otherDb.doc('users/${otherAuth.currentUser!.uid}/tasks/keep').set(
          {'text': 'Keep'},
        );
        // Cross the 400-document deletion batch boundary.
        final batch = db.batch();
        for (var i = 0; i < 405; i++) {
          batch.set(db.doc('users/$owner/tasks/batch$i'), {'text': 'Test'});
        }
        await batch.commit();
        await AuthService.deleteAccount();
        expect(auth.currentUser, isNull);
        final survivor = await otherDb
            .doc('users/${otherAuth.currentUser!.uid}/tasks/keep')
            .get();
        expect(survivor.exists, isTrue);
        await otherDb
            .doc('users/${otherAuth.currentUser!.uid}/tasks/keep')
            .delete();
        await otherAuth.currentUser!.delete();
        await expectLater(
          FirestoreService.saveTask({'id': 'unauth', 'text': 'No'}),
          throwsStateError,
        );
      },
    );

    test(
      'Coaching assessment persists and goal updates rebuild the shared plan',
      () async {
        await AuthService.continueAsGuest();
        await BodyStats.defaults().copyWith(goal: 'fat_loss').save();
        final now = DateTime.now();
        final preferences = CoachingPreferences(
          experience: 'Intermediate',
          equipment: 'Dumbbells',
          recovery: 'Recovered',
          checkedAt: now,
          exclusions: ['Milk', 'Soy'],
        );
        await FirestoreService.saveProfile({
          'coaching': preferences.toMap(),
          'planDiet': 'Vegan',
          'planGoalId': 'coaching-goal',
        });
        await FirestoreService.saveGoal({
          'id': 'coaching-goal',
          'title': 'Complete training milestone',
          'category': 'fitness',
          'targetValue': 10,
          'currentValue': 9,
        });
        for (var i = 1; i <= 3; i++) {
          final date = now
              .subtract(Duration(days: i))
              .toIso8601String()
              .substring(0, 10);
          await FirestoreService.saveWorkout({
            'id': 'session$i',
            'type': 'strength',
            'date': date,
            'durationMins': 30,
          });
        }
        final before = (await CoachingContextService.load())!;
        expect(before.diet, 'Vegan');
        expect(before.preferences.equipment, 'Dumbbells');
        expect(before.workouts.join(), contains('3 sets'));
        expect(before.stats.goal, 'fat_loss');
        await FirestoreService.saveGoal({
          'id': 'coaching-goal',
          'currentValue': 10,
        });
        final after = (await CoachingContextService.load())!;
        expect(after.stats.goal, 'maintain');
        expect(after.phase, 'Maintenance');
        await FirestoreService.saveProfile({
          'coaching': const CoachingPreferences(pain: true).toMap(),
        });
        expect((await CoachingContextService.load())!.needsReview, isTrue);
        await AuthService.deleteAccount();
      },
    );

    testWidgets(
      'Imperial profile input preserves stored measurements and accepts pounds',
      (tester) async {
        await tester.runAsync(() async {
          await AuthService.continueAsGuest();
          await BodyStats.defaults()
              .copyWith(weightKg: 75.123456, heightCm: 175.26)
              .save();
        });
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(const MaterialApp(home: BodyStatsScreen()));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pump();
        await tester.tap(find.text('Use imperial'));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('body-weight')));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pump();
        expect(find.byKey(const ValueKey('height-feet')), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('body-weight')))
              .controller!
              .text,
          '165.62',
        );
        await tester.ensureVisible(find.text('Save Profile'));
        await tester.tap(find.text('Save Profile'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pump();
        await tester.runAsync(() async {
          final saved = (await BodyStats.load())!;
          expect(saved.units.pounds, isTrue);
          expect(saved.weightKg, 75.123456);
          expect(saved.heightCm, 175.26);
        });
        await tester.ensureVisible(find.byKey(const ValueKey('body-weight')));
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('body-weight')),
            matching: find.byType(EditableText),
          ),
          findsOneWidget,
          reason: 'Body weight editor must be mounted',
        );
        await tester.enterText(
          find.byKey(const ValueKey('body-weight')),
          '180',
        );
        await tester.ensureVisible(find.text('Save Profile'));
        await tester.tap(find.text('Save Profile'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pump();
        await tester.runAsync(() async {
          final saved = (await BodyStats.load())!;
          expect(
            saved.weightKg,
            closeTo(180 * MeasurementUnits.kgPerPound, 1e-9),
          );
        });
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        await tester.tap(find.text('Weight Log'));
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pump();
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('log-weight')),
            matching: find.byType(EditableText),
          ),
          findsOneWidget,
          reason: 'Weight log editor must be mounted',
        );
        await tester.enterText(find.byKey(const ValueKey('log-weight')), '170');
        await tester.tap(find.text('Add'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pump();
        await tester.runAsync(() async {
          final saved = (await BodyStats.load())!;
          expect(
            saved.weightHistory.last.weightKg,
            closeTo(170 * MeasurementUnits.kgPerPound, 1e-9),
          );
          await saved
              .copyWith(units: saved.units.copyWith(kilojoules: true))
              .save();
        });
        await tester.pumpWidget(const MaterialApp(home: DietScreen()));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('diet-name')),
          'Unit conversion check',
        );
        await tester.enterText(
          find.byKey(const ValueKey('diet-Energy')),
          '418.4',
        );
        await tester.enterText(find.byKey(const ValueKey('diet-Protein')), '1');
        await tester.enterText(find.byKey(const ValueKey('diet-Carbs')), '2');
        await tester.enterText(find.byKey(const ValueKey('diet-Fat')), '0.5');
        await tester.ensureVisible(find.text('Add to Log'));
        await tester.tap(find.text('Add to Log'));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        await tester.pump();
        await tester.runAsync(() async {
          final meals = await FirestoreService.dietStream(
            AppDateUtils.formatDate(AppDateUtils.today()),
          ).first;
          final meal = meals.docs.single.data() as Map;
          expect(meal['calories'], closeTo(100, 1e-9));
          expect(
            meal['protein'],
            closeTo(MeasurementUnits.gramsPerOunce, 1e-9),
          );
          expect(
            meal['carbs'],
            closeTo(2 * MeasurementUnits.gramsPerOunce, 1e-9),
          );
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.runAsync(AuthService.deleteAccount);
      },
    );

    testWidgets('Signed-in navigation works on phone and desktop', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await AuthService.continueAsGuest();
        await BodyStats.defaults().save();
      });
      for (final width in [390.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(const ActivityTrackerApp());
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        await tester.pump();
        for (final label in [
          'Training',
          'Diet',
          'Habits',
          'Tasks',
          'Goals',
          'Coach',
          'Dashboard',
        ]) {
          await tester.tap(find.text(label).last);
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 350)),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$label at $width');
        }
      }
      await tester.pumpWidget(const SizedBox());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.runAsync(AuthService.deleteAccount);
    });
  }, skip: !enabled);
}
