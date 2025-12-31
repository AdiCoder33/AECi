class OscarCriterion {
  const OscarCriterion({
    required this.label,
    this.maxScore = 2,
  });

  final String label;
  final int maxScore;
}

// Draft OSCAR rubric - update when official form is provided.
const oscarRubric = [
  OscarCriterion(label: 'Respect for tissue'),
  OscarCriterion(label: 'Instrument handling'),
  OscarCriterion(label: 'Time and motion'),
  OscarCriterion(label: 'Flow of operation'),
  OscarCriterion(label: 'Knowledge of procedure'),
  OscarCriterion(label: 'Use of assistant'),
  OscarCriterion(label: 'Exposure and visualization'),
  OscarCriterion(label: 'Hemostasis and control'),
  OscarCriterion(label: 'Complication management'),
  OscarCriterion(label: 'Overall safety'),
];
