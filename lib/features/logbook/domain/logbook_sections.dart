import 'elog_entry.dart';

class LogbookSection {
  const LogbookSection({
    required this.key,
    required this.label,
    this.moduleType,
    this.caseCategory,
  });

  final String key;
  final String label;
  final String? moduleType;
  final String? caseCategory;
}

const logbookSectionOpdCases = 'opd_cases';
const logbookSectionAtlas = 'atlas';
const logbookSectionSurgicalRecord = 'surgical_record';
const logbookSectionLearning = 'learning';
const logbookSectionRetinoblastoma = 'retinoblastoma_screening';
const logbookSectionRop = 'rop_screening';
const logbookSectionPublications = 'publications';
const logbookSectionReviews = 'reviews';

const logbookSections = [
  LogbookSection(
    key: logbookSectionOpdCases,
    label: 'OPD Cases',
    caseCategory: 'opd',
  ),
  LogbookSection(
    key: logbookSectionAtlas,
    label: 'Atlas',
    moduleType: moduleImages,
  ),
  LogbookSection(
    key: logbookSectionSurgicalRecord,
    label: 'Surgical Record',
    moduleType: moduleRecords,
  ),
  LogbookSection(
    key: logbookSectionLearning,
    label: 'Learning',
    moduleType: moduleLearning,
  ),
  LogbookSection(
    key: logbookSectionRetinoblastoma,
    label: 'Retinoblastoma Screening',
    caseCategory: 'retinoblastoma',
  ),
  LogbookSection(
    key: logbookSectionRop,
    label: 'ROP Screening',
    caseCategory: 'rop',
  ),
  LogbookSection(
    key: logbookSectionPublications,
    label: 'Publications',
  ),
  LogbookSection(
    key: logbookSectionReviews,
    label: 'Reviews',
  ),
];

const logbookEntrySections = {
  logbookSectionAtlas,
  logbookSectionSurgicalRecord,
  logbookSectionLearning,
};

const logbookCaseSections = {
  logbookSectionOpdCases,
  logbookSectionRetinoblastoma,
  logbookSectionRop,
};
