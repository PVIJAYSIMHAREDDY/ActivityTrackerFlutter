import 'adaptive_plan_service.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/body_stats_model.dart';
import 'coach_service.dart';

class PlanExportService {
  static Future<Uint8List> createAdaptivePdf(
    AdaptivePlan plan,
    String type,
  ) async {
    if (!['workout', 'nutrition', 'full'].contains(type)) {
      throw ArgumentError.value(type);
    }
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        maxPages: 100,
        pageFormat: PdfPageFormat.a4,
        build: (_) => plan
            .lines(type)
            .expand((line) => line.split('\n'))
            .map(
              (line) => pw.Paragraph(
                text: line.replaceAll(RegExp(r'[^\x20-\x7E]'), '-'),
              ),
            )
            .toList(),
        footer: (c) =>
            pw.Text('Activity Tracker | ${c.pageNumber}/${c.pagesCount}'),
      ),
    );
    return doc.save();
  }

  static Future<void> shareAdaptive(AdaptivePlan plan, String type) async {
    await Printing.sharePdf(
      bytes: await createAdaptivePdf(plan, type),
      filename: 'activity_tracker_${type}_coaching_plan.pdf',
    );
  }

  static Future<Uint8List> createPdf(String type, BodyStats stats) async {
    if (!['workout', 'nutrition', 'full'].contains(type)) {
      throw ArgumentError.value(type);
    }
    final plan = CoachService.getWeeklyPlan(
      CoachService.getCurrentWeek(stats.programStartDate),
      stats,
    );
    final doc = pw.Document();
    // Standard PDF fonts keep export independent of network font services.
    String plain(String text) =>
        text.replaceAll(RegExp(r'[^\x20-\x7E\n]'), '-');
    final content = <pw.Widget>[
      pw.Header(
        level: 0,
        child: pw.Text('Activity Tracker - ${type.toUpperCase()} PLAN'),
      ),
      pw.Paragraph(
        text:
            'Week ${plan.weekNumber} | ${plan.phase} | Generated ${DateTime.now().toIso8601String().substring(0, 10)}',
      ),
      pw.Paragraph(
        text:
            'General fitness guidance for adults. Estimates and templates are not medical advice or a prescription. Adjust with a qualified professional for your experience, health and recovery. Stop if exercise causes pain.',
      ),
    ];
    if (type != 'nutrition') {
      const names = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      for (var i = 0; i < plan.days.length; i++) {
        final day = plan.days[i];
        content.add(
          pw.Header(
            level: 1,
            child: pw.Text(plain('${names[i]}: ${day.title}')),
          ),
        );
        for (final exercise in day.exercises) {
          content.add(
            pw.Paragraph(
              text: plain(
                '${exercise.name}: ${exercise.sets}, ${exercise.reps}. Rest: ${exercise.rest}. ${exercise.tip}',
              ),
            ),
          );
        }
        content.add(pw.Paragraph(text: plain(day.coachNote)));
      }
    }
    if (type != 'workout') {
      content.addAll([
        pw.Header(
          level: 1,
          child: pw.Text('Estimated daily nutrition targets'),
        ),
        pw.Paragraph(
          text:
              'Energy: ${stats.units.energy(stats.targetCalories)}\nProtein: ${stats.units.food(stats.targetProtein)}\nCarbohydrate: ${stats.units.food(stats.targetCarbs)}\nFat: ${stats.units.food(stats.targetFat)}',
        ),
        pw.Paragraph(
          text:
              'These are estimates from your saved profile, not measured energy needs. Include varied foods and review targets with a qualified dietitian, especially for medical conditions or a history of disordered eating.',
        ),
      ]);
    }
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => content,
        footer: (context) => pw.Text(
          'Activity Tracker | ${context.pageNumber} / ${context.pagesCount}',
        ),
      ),
    );
    return doc.save();
  }

  static Future<void> share(String type, BodyStats stats) async {
    final bytes = await createPdf(type, stats);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'activity_tracker_${type}_plan.pdf',
    );
  }
}
