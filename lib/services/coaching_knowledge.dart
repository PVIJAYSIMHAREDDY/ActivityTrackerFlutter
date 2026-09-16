class CoachingReference {
  final String title, file, pages, principle;
  const CoachingReference(this.title, this.file, this.pages, this.principle);
  String get citation => '$title — PDF pages $pages';
}

class CoachingKnowledge {
  static const references = [
    CoachingReference(
      'ISSA Sports Nutrition',
      'ISSA-Sports-Nutrition-Certification-Main-Course-Textbook.pdf',
      '409–410, 562',
      'Estimate energy needs from the individual, then review food intake, body changes and performance together. Meal timing and composition should fit training and daily life.',
    ),
    CoachingReference(
      'ISSA Strength and Conditioning',
      'ISSA_Strength_and_Conditioning_Certification_Main_Course_Textbook.pdf',
      '47–51',
      'Choose frequency, intensity, time and exercise type for the individual. Progress gradually when the current workload is manageable; calendar time alone does not justify more load.',
    ),
    CoachingReference(
      'ISSA Bodybuilding',
      'ISSA_Bodybuilding_Main_Course_Textbook.pdf',
      '188–189',
      'Plan recovery alongside training. Experience and recovery capacity influence training volume; fatigue calls for a lighter workload rather than automatic progression.',
    ),
    CoachingReference(
      'ISSA Transformation Specialist',
      'ISSA-Transformation-Specialist-Main-Course-Textbook.pdf',
      '14, 20–21',
      'Start with the person’s reasons and confidence. Use small attainable actions, supportive questions and a practical fallback after missed sessions.',
    ),
    CoachingReference(
      'ISSA Corrective Exercise Specialist',
      'ISSA_Corrective_Exercise_Specialist_Main_Course_Textbook.pdf.pdf',
      '103–104, 121–122',
      'Match movement challenges to ability and offer appropriate alternatives. Pain, numbness and other concerning symptoms require assessment rather than a software-generated diagnosis.',
    ),
    CoachingReference(
      'ISSA Specialist in Exercise Therapy',
      'ISSA_Specialist_in_Exercise_Therapy_Main_Course_Textbook.pdf',
      '35–36',
      'Consider functional limitations, environment, preferences and professional restrictions when planning activity. Condition-specific rehabilitation needs qualified supervision.',
    ),
  ];
  static String? answer(String query) {
    final q = query.toLowerCase();
    int? index;
    if (RegExp(
      r'\b(motivation|habit|confidence|missed|consistency|stuck)\b',
    ).hasMatch(q)) {
      index = 3;
    } else if (RegExp(
      r'\b(recovery|sleep|fatigue|deload|tired|rest)\b',
    ).hasMatch(q)) {
      index = 2;
    } else if (RegExp(
      r'\b(form|technique|mobility|warm.?up|posture)\b',
    ).hasMatch(q)) {
      index = 4;
    } else if (RegExp(
      r'\b(protein|nutrition|carbohydrate|carbs|hydration|meal|diet|calories)\b',
    ).hasMatch(q)) {
      index = 0;
    } else if (RegExp(
      r'\b(strength|workout|progression|sets|reps|training)\b',
    ).hasMatch(q)) {
      index = 1;
    }
    if (index == null) return null;
    final ref = references[index];
    final action = [
      'Use the portioned meal plan as a starting point. Compare its estimated totals with your targets and actual food labels. Review several consistent measurements before changing intake.',
      'Record repetitions and how difficult each set feels. Keep the same resistance until the prescribed repetitions feel controlled and recovery is good; then consider the smallest available increase.',
      'Use the weekly check-in to report tiredness. The plan reduces sets and holds progression when recovery is poor. Persistent unexplained fatigue deserves professional assessment.',
      'What is one action you feel confident you can repeat this week? Choose it in your coaching assessment and attach it to an existing routine.',
      'Start with controlled, comfortable movement and the easier variation. Software cannot assess your movement or diagnose a restriction; seek hands-on coaching when technique is uncertain.',
    ][index];
    return '${ref.principle}\n\n$action\n\nSource: ${ref.citation}. Adapted summary; session parameters are app rules.';
  }
}
