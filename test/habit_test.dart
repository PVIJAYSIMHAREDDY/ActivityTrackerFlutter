import 'package:flutter_test/flutter_test.dart';
import 'package:activity_tracker/models/habit_model.dart';
import 'package:activity_tracker/utils/date_utils.dart';

void main() {
  test('Undo today retains previous completions and their streak', () {
    final habit = HabitModel(
      id: '1',
      name: 'Walk',
      icon: 'x',
      streak: 2,
      lastDoneDate: '2026-09-08',
      completedDates: ['2026-09-07', '2026-09-08'],
    );
    final done = habit.toggleDate('2026-09-09', now: DateTime(2026, 9, 9));
    expect(done.streak, 3);
    final undone = done.toggleDate('2026-09-09', now: DateTime(2026, 9, 9));
    expect(undone.streak, 2);
    expect(undone.doneOn('2026-09-08'), isTrue);
    expect(undone.doneOn('2026-09-09'), isFalse);
  });
  test('Legacy records retain their known completion date', () {
    final habit = HabitModel.fromFirestore({
      'name': 'Walk',
      'lastDoneDate': '2026-09-08',
      'streak': 5,
    }, '1');
    expect(
      habit.toggleDate('2026-09-09', now: DateTime(2026, 9, 9)).completedDates,
      ['2026-09-08', '2026-09-09'],
    );
  });
  test('Selected historical day changes without marking today', () {
    final habit = HabitModel(
      id: '1',
      name: 'Walk',
      icon: 'x',
      streak: 0,
      lastDoneDate: '',
    );
    final updated = habit.toggleDate('2026-09-05', now: DateTime(2026, 9, 9));
    expect(updated.doneOn('2026-09-05'), isTrue);
    expect(updated.doneOn('2026-09-09'), isFalse);
    expect(updated.streak, 0);
  });
  test('Calendar navigation crosses month and year boundaries', () {
    expect(
      AppDateUtils.addDays(DateTime(2026, 12, 31), 1),
      DateTime(2027, 1, 1),
    );
    expect(
      AppDateUtils.subtractDays(DateTime(2026, 3, 1), 1),
      DateTime(2026, 2, 28),
    );
  });
}
