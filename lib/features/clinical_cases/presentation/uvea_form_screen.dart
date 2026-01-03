import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/clinical_cases_controller.dart';
import '../data/clinical_case_constants.dart';

class UveaFormScreen extends ConsumerStatefulWidget {
  const UveaFormScreen({super.key, this.caseId});

  final String? caseId;

  @override
  ConsumerState<UveaFormScreen> createState() => _UveaFormScreenState();
}

class _UveaFormScreenState extends ConsumerState<UveaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _uidController = TextEditingController();
  final _mrnController = TextEditingController();
  final _ageController = TextEditingController();
  final _occupationController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  final _durationController = TextEditingController(text: '1');
  final _drugHistoryController = TextEditingController();
  final _traumaController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _labTestsController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _etiologyController = TextEditingController();
  final _extraNotesController = TextEditingController();
  final _followUpController = TextEditingController();
  final _iopReController = TextEditingController();
  final _iopLeController = TextEditingController();
  final _systemicOtherController = TextEditingController();

  final _uveaLocation = <String, String?>{'RE': null, 'LE': null};
  final _symptoms = <String>{};
  final _systemicIllnesses = <String>{};
  final _imaging = <String>{};

  late final _UveaAnteriorEyeState _anteriorRe;
  late final _UveaAnteriorEyeState _anteriorLe;
  late final _UveaFundusEyeState _fundusRe;
  late final _UveaFundusEyeState _fundusLe;

  Map<String, dynamic> _baseAnteriorSegment = {};
  Map<String, dynamic> _baseFundus = {};
  bool _loadingCase = false;

  DateTime _examDate = DateTime.now();
  String _gender = 'male';
  String _durationUnit = complaintUnits.first;
  String _bcvaRe = '';
  String _bcvaLe = '';
  String? _laterality;
  bool? _previousUveitis;
  String _chiefComplaintFallback = '';

  static const _symptomOptions = [
    'Pain',
    'Redness',
    'Photophobia',
    'Blurring',
    'Floaters',
  ];

  static const _lateralityOptions = ['RE', 'LE', 'BE'];

  static const _systemicOptions = [
    'TB',
    'Sarcoidosis',
    'HLA-B27',
    'Autoimmune disease',
    'Infections',
    'Other',
  ];

  static const _conjunctivaOptions = [
    'CCC',
    'Episcleritis',
    'Scleritis',
    'Other',
  ];

  static const _kpsTypeOptions = [
    'Granulomatous',
    'Non-granulomatous',
  ];

  static const _kpsDistributionOptions = [
    'Diffuse',
    'Inferior',
  ];

  static const _acCellOptions = [
    '0.5+',
    '1+',
    '2+',
    '3+',
    '4+',
  ];

  static const _flareOptions = [
    '1+',
    '2+',
    '3+',
    '4+',
  ];

  static const _irisNodulesOptions = [
    'Koeppe',
    'Busacca',
    'Other',
  ];

  static const _irisSynechiaeOptions = [
    'Anterior',
    'Posterior',
  ];

  static const _glaucomaOptions = [
    'Open angle',
    'Angle closure',
    'Steroid-induced',
    'Other',
  ];

  static const _lensStatusOptions = [
    'Clear',
    'Complicated cataract',
    'Pseudophakia',
    'Aphakia',
  ];

  static const _opticDiscOptions = [
    'Normal',
    'Hyperemic',
    'Edematous',
    'Pale',
  ];

  static const _vesselsOptions = [
    'Normal',
    'Vasculitis',
  ];

  static const _vesselsTypeOptions = [
    'Arterial',
    'Venous',
  ];

  static const _backgroundOptions = [
    'Nil',
    'Focal',
    'Multifocal',
    'Disseminated',
  ];

  static const _locationOptions = [
    'Anterior uveitis',
    'Intermediate uveitis',
    'Posterior uveitis',
    'Pan uveitis',
    'Nil',
  ];

  static const _imagingOptions = [
    'OCT',
    'FFA',
    'USG',
    'Fundus photo',
  ];

  @override
  void initState() {
    super.initState();
    _anteriorRe = _UveaAnteriorEyeState();
    _anteriorLe = _UveaAnteriorEyeState();
    _fundusRe = _UveaFundusEyeState();
    _fundusLe = _UveaFundusEyeState();
    _dateController.text = _formatDate(_examDate);
    if (widget.caseId != null) {
      _loadCase();
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _uidController.dispose();
    _mrnController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _durationController.dispose();
    _drugHistoryController.dispose();
    _traumaController.dispose();
    _familyHistoryController.dispose();
    _labTestsController.dispose();
    _diagnosisController.dispose();
    _etiologyController.dispose();
    _extraNotesController.dispose();
    _followUpController.dispose();
    _iopReController.dispose();
    _iopLeController.dispose();
    _systemicOtherController.dispose();
    _anteriorRe.dispose();
    _anteriorLe.dispose();
    _fundusRe.dispose();
    _fundusLe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(clinicalCaseMutationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.caseId == null ? 'Uvea Entry' : 'Edit Uvea Entry',
        ),
      ),
      body: _loadingCase
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDemographicsSection(),
                    const SizedBox(height: 16),
                    _buildChiefComplaintSection(),
                    const SizedBox(height: 16),
                    _buildRelevantHistorySection(),
                    const SizedBox(height: 16),
                    _buildVisualParametersSection(),
                    const SizedBox(height: 16),
                    _buildAnteriorSegmentSection(),
                    const SizedBox(height: 16),
                    _buildFundusSection(),
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildInvestigationsSection(),
                    const SizedBox(height: 16),
                    _buildDiagnosisSection(),
                    const SizedBox(height: 16),
                    _buildExtraNotesSection(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: mutation.isLoading ? null : _save,
                          child: mutation.isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDemographicsSection() {
    return _sectionCard(
      title: '1. Patient Demographics',
      child: Column(
        children: [
          _buildTextField(
            controller: _patientNameController,
            label: 'Patient name',
            validator: _required,
          ),
          _buildTwoColumn(
            left: _buildTextField(
              controller: _uidController,
              label: 'UHID / UID',
              validator: _required,
            ),
            right: _buildTextField(
              controller: _mrnController,
              label: 'MR No',
              validator: _required,
            ),
          ),
          _buildTwoColumn(
            left: _buildTextField(
              controller: _ageController,
              label: 'Age',
              keyboardType: TextInputType.number,
              validator: _requiredNumber,
            ),
            right: _buildDropdown(
              label: 'Sex',
              value: _gender,
              items: const ['male', 'female'],
              labelBuilder: (value) =>
                  value == 'male' ? 'Male' : 'Female',
              onChanged: (value) => setState(() => _gender = value ?? 'male'),
            ),
          ),
          _buildTextField(
            controller: _occupationController,
            label: 'Occupation',
          ),
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            maxLines: 2,
          ),
          _buildDateField(),
        ],
      ),
    );
  }

  Widget _buildChiefComplaintSection() {
    return _sectionCard(
      title: '2. Chief Complaint',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Symptoms',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _symptomOptions.map((option) {
              final selected = _symptoms.contains(option);
              return FilterChip(
                label: Text(option),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _symptoms.add(option);
                    } else {
                      _symptoms.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildTwoColumn(
            left: _buildTextField(
              controller: _durationController,
              label: 'Duration',
              keyboardType: TextInputType.number,
              validator: _requiredNumber,
            ),
            right: _buildDropdown(
              label: 'Unit',
              value: _durationUnit,
              items: complaintUnits,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _durationUnit = value);
              },
            ),
          ),
          _buildDropdown(
            label: 'Laterality',
            value: _laterality,
            items: _lateralityOptions,
            onChanged: (value) => setState(() => _laterality = value),
          ),
        ],
      ),
    );
  }

  Widget _buildRelevantHistorySection() {
    return _sectionCard(
      title: '3. Relevant History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildYesNo(
            label: 'Previous episodes of uveitis',
            value: _previousUveitis,
            onChanged: (value) => setState(() => _previousUveitis = value),
          ),
          const SizedBox(height: 12),
          const Text(
            'Systemic illness',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _systemicOptions.map((option) {
              final selected = _systemicIllnesses.contains(option);
              return FilterChip(
                label: Text(option),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _systemicIllnesses.add(option);
                    } else {
                      _systemicIllnesses.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
          if (_systemicIllnesses.contains('Other'))
            _buildTextField(
              controller: _systemicOtherController,
              label: 'Systemic illness (other)',
              validator: (value) {
                if (!_systemicIllnesses.contains('Other')) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
          _buildTextField(
            controller: _drugHistoryController,
            label: 'Drug history (especially steroids)',
          ),
          _buildTextField(
            controller: _traumaController,
            label: 'Trauma / surgery',
          ),
          _buildTextField(
            controller: _familyHistoryController,
            label: 'Family history',
          ),
        ],
      ),
    );
  }

  Widget _buildVisualParametersSection() {
    return _sectionCard(
      title: '4. Visual Parameters (RE / LE)',
      child: Column(
        children: [
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'BCVA',
                value: _bcvaRe,
                items: bcvaOptions,
                onChanged: (value) =>
                    setState(() => _bcvaRe = value ?? ''),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'BCVA',
                value: _bcvaLe,
                items: bcvaOptions,
                onChanged: (value) =>
                    setState(() => _bcvaLe = value ?? ''),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildTextField(
                controller: _iopReController,
                label: 'IOP',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildTextField(
                controller: _iopLeController,
                label: 'IOP',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnteriorSegmentSection() {
    return _sectionCard(
      title: '5. Anterior Segment Examination (RE / LE)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '5.1 Conjunctiva',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Conjunctiva',
                value: _anteriorRe.conjunctiva,
                items: _conjunctivaOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.conjunctiva = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Conjunctiva',
                value: _anteriorLe.conjunctiva,
                items: _conjunctivaOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.conjunctiva = value),
              ),
            ),
          ),
          if (_anteriorRe.conjunctiva == 'Other' ||
              _anteriorLe.conjunctiva == 'Other')
            _buildEyeTwoColumn(
              left: _buildEyeField(
                eye: 'RE',
                child: _buildTextField(
                  controller: _anteriorRe.conjunctivaOther,
                  label: 'Conjunctiva (other)',
                  validator: (value) =>
                      _otherValidator(_anteriorRe.conjunctiva, value),
                ),
              ),
              right: _buildEyeField(
                eye: 'LE',
                child: _buildTextField(
                  controller: _anteriorLe.conjunctivaOther,
                  label: 'Conjunctiva (other)',
                  validator: (value) =>
                      _otherValidator(_anteriorLe.conjunctiva, value),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            '5.2 Cornea',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildYesNo(
                label: 'Keratitis',
                value: _anteriorRe.keratitis,
                onChanged: (value) =>
                    setState(() => _anteriorRe.keratitis = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildYesNo(
                label: 'Keratitis',
                value: _anteriorLe.keratitis,
                onChanged: (value) =>
                    setState(() => _anteriorLe.keratitis = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'KPs type',
                value: _anteriorRe.kpsType,
                items: _kpsTypeOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.kpsType = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'KPs type',
                value: _anteriorLe.kpsType,
                items: _kpsTypeOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.kpsType = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'KPs distribution',
                value: _anteriorRe.kpsDistribution,
                items: _kpsDistributionOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.kpsDistribution = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'KPs distribution',
                value: _anteriorLe.kpsDistribution,
                items: _kpsDistributionOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.kpsDistribution = value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '5.3 Anterior Chamber (AC)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Cells',
                value: _anteriorRe.acCells,
                items: _acCellOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.acCells = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Cells',
                value: _anteriorLe.acCells,
                items: _acCellOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.acCells = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Flare',
                value: _anteriorRe.flare,
                items: _flareOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.flare = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Flare',
                value: _anteriorLe.flare,
                items: _flareOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.flare = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildYesNo(
                label: 'Fibrin / FM',
                value: _anteriorRe.fm,
                onChanged: (value) => setState(() => _anteriorRe.fm = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildYesNo(
                label: 'Fibrin / FM',
                value: _anteriorLe.fm,
                onChanged: (value) => setState(() => _anteriorLe.fm = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildYesNo(
                label: 'Hypopyon',
                value: _anteriorRe.hypopyon,
                onChanged: (value) =>
                    setState(() => _anteriorRe.hypopyon = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildYesNo(
                label: 'Hypopyon',
                value: _anteriorLe.hypopyon,
                onChanged: (value) =>
                    setState(() => _anteriorLe.hypopyon = value),
              ),
            ),
          ),
          if (_anteriorRe.hypopyon == true ||
              _anteriorLe.hypopyon == true)
            _buildEyeTwoColumn(
              left: _buildEyeField(
                eye: 'RE',
                child: _buildTextField(
                  controller: _anteriorRe.hypopyonHeight,
                  label: 'Hypopyon height (mm)',
                  keyboardType: TextInputType.number,
                  validator: (value) => _hypopyonValidator(
                    _anteriorRe.hypopyon,
                    value,
                  ),
                ),
              ),
              right: _buildEyeField(
                eye: 'LE',
                child: _buildTextField(
                  controller: _anteriorLe.hypopyonHeight,
                  label: 'Hypopyon height (mm)',
                  keyboardType: TextInputType.number,
                  validator: (value) => _hypopyonValidator(
                    _anteriorLe.hypopyon,
                    value,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            '5.4 Iris',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Nodules',
                value: _anteriorRe.irisNodules,
                items: _irisNodulesOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.irisNodules = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Nodules',
                value: _anteriorLe.irisNodules,
                items: _irisNodulesOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.irisNodules = value),
              ),
            ),
          ),
          if (_anteriorRe.irisNodules == 'Other' ||
              _anteriorLe.irisNodules == 'Other')
            _buildEyeTwoColumn(
              left: _buildEyeField(
                eye: 'RE',
                child: _buildTextField(
                  controller: _anteriorRe.irisNodulesOther,
                  label: 'Nodules (other)',
                  validator: (value) =>
                      _otherValidator(_anteriorRe.irisNodules, value),
                ),
              ),
              right: _buildEyeField(
                eye: 'LE',
                child: _buildTextField(
                  controller: _anteriorLe.irisNodulesOther,
                  label: 'Nodules (other)',
                  validator: (value) =>
                      _otherValidator(_anteriorLe.irisNodules, value),
                ),
              ),
            ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Synechiae',
                value: _anteriorRe.irisSynechiae,
                items: _irisSynechiaeOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.irisSynechiae = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Synechiae',
                value: _anteriorLe.irisSynechiae,
                items: _irisSynechiaeOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.irisSynechiae = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildYesNo(
                label: 'Rubeosis',
                value: _anteriorRe.irisRubeosis,
                onChanged: (value) =>
                    setState(() => _anteriorRe.irisRubeosis = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildYesNo(
                label: 'Rubeosis',
                value: _anteriorLe.irisRubeosis,
                onChanged: (value) =>
                    setState(() => _anteriorLe.irisRubeosis = value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '5.5 Glaucoma Status',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Glaucoma',
                value: _anteriorRe.glaucoma,
                items: _glaucomaOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.glaucoma = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Glaucoma',
                value: _anteriorLe.glaucoma,
                items: _glaucomaOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.glaucoma = value),
              ),
            ),
          ),
          if (_anteriorRe.glaucoma == 'Other' ||
              _anteriorLe.glaucoma == 'Other')
            _buildEyeTwoColumn(
              left: _buildEyeField(
                eye: 'RE',
                child: _buildTextField(
                  controller: _anteriorRe.glaucomaOther,
                  label: 'Glaucoma (other)',
                  validator: (value) =>
                      _otherValidator(_anteriorRe.glaucoma, value),
                ),
              ),
              right: _buildEyeField(
                eye: 'LE',
                child: _buildTextField(
                  controller: _anteriorLe.glaucomaOther,
                  label: 'Glaucoma (other)',
                  validator: (value) =>
                      _otherValidator(_anteriorLe.glaucoma, value),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            '5.6 Lens Status',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Lens status',
                value: _anteriorRe.lensStatus,
                items: _lensStatusOptions,
                onChanged: (value) =>
                    setState(() => _anteriorRe.lensStatus = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Lens status',
                value: _anteriorLe.lensStatus,
                items: _lensStatusOptions,
                onChanged: (value) =>
                    setState(() => _anteriorLe.lensStatus = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundusSection() {
    return _sectionCard(
      title: '6. Fundus Examination (RE / LE)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '6.1 Media',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildTextField(
                controller: _fundusRe.avfVitreous,
                label: 'AVF / Vitreous opacities',
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildTextField(
                controller: _fundusLe.avfVitreous,
                label: 'AVF / Vitreous opacities',
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildPresenceDropdown(
                label: 'Snowballs',
                value: _fundusRe.snowballs,
                onChanged: (value) =>
                    setState(() => _fundusRe.snowballs = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildPresenceDropdown(
                label: 'Snowballs',
                value: _fundusLe.snowballs,
                onChanged: (value) =>
                    setState(() => _fundusLe.snowballs = value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '6.2 Optic Disc',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Optic disc',
                value: _fundusRe.opticDisc,
                items: _opticDiscOptions,
                onChanged: (value) =>
                    setState(() => _fundusRe.opticDisc = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Optic disc',
                value: _fundusLe.opticDisc,
                items: _opticDiscOptions,
                onChanged: (value) =>
                    setState(() => _fundusLe.opticDisc = value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '6.3 Vessels',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Vessels',
                value: _fundusRe.vessels,
                items: _vesselsOptions,
                onChanged: (value) =>
                    setState(() => _fundusRe.vessels = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Vessels',
                value: _fundusLe.vessels,
                items: _vesselsOptions,
                onChanged: (value) =>
                    setState(() => _fundusLe.vessels = value),
              ),
            ),
          ),
          if (_fundusRe.vessels == 'Vasculitis' ||
              _fundusLe.vessels == 'Vasculitis')
            _buildEyeTwoColumn(
              left: _buildEyeField(
                eye: 'RE',
                child: _buildDropdown(
                  label: 'Vasculitis type',
                  value: _fundusRe.vesselsType,
                  items: _vesselsTypeOptions,
                  onChanged: (value) =>
                      setState(() => _fundusRe.vesselsType = value),
                ),
              ),
              right: _buildEyeField(
                eye: 'LE',
                child: _buildDropdown(
                  label: 'Vasculitis type',
                  value: _fundusLe.vesselsType,
                  items: _vesselsTypeOptions,
                  onChanged: (value) =>
                      setState(() => _fundusLe.vesselsType = value),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            '6.4 Background Retina',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Retinitis',
                value: _fundusRe.retinitis,
                items: _backgroundOptions,
                onChanged: (value) =>
                    setState(() => _fundusRe.retinitis = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Retinitis',
                value: _fundusLe.retinitis,
                items: _backgroundOptions,
                onChanged: (value) =>
                    setState(() => _fundusLe.retinitis = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Choroiditis',
                value: _fundusRe.choroiditis,
                items: _backgroundOptions,
                onChanged: (value) =>
                    setState(() => _fundusRe.choroiditis = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Choroiditis',
                value: _fundusLe.choroiditis,
                items: _backgroundOptions,
                onChanged: (value) =>
                    setState(() => _fundusLe.choroiditis = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildYesNo(
                label: 'Snowbanking',
                value: _fundusRe.snowbanking,
                onChanged: (value) =>
                    setState(() => _fundusRe.snowbanking = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildYesNo(
                label: 'Snowbanking',
                value: _fundusLe.snowbanking,
                onChanged: (value) =>
                    setState(() => _fundusLe.snowbanking = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildYesNo(
                label: 'Exudative retinal detachment',
                value: _fundusRe.exudativeRd,
                onChanged: (value) =>
                    setState(() => _fundusRe.exudativeRd = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildYesNo(
                label: 'Exudative retinal detachment',
                value: _fundusLe.exudativeRd,
                onChanged: (value) =>
                    setState(() => _fundusLe.exudativeRd = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildTextField(
                controller: _fundusRe.backgroundOther,
                label: 'Background (other)',
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildTextField(
                controller: _fundusLe.backgroundOther,
                label: 'Background (other)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '6.5 Macula',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildYesNo(
                label: 'Cystoid macular edema',
                value: _fundusRe.maculaCme,
                onChanged: (value) =>
                    setState(() => _fundusRe.maculaCme = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildYesNo(
                label: 'Cystoid macular edema',
                value: _fundusLe.maculaCme,
                onChanged: (value) =>
                    setState(() => _fundusLe.maculaCme = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildYesNo(
                label: 'Exudates',
                value: _fundusRe.maculaExudates,
                onChanged: (value) =>
                    setState(() => _fundusRe.maculaExudates = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildYesNo(
                label: 'Exudates',
                value: _fundusLe.maculaExudates,
                onChanged: (value) =>
                    setState(() => _fundusLe.maculaExudates = value),
              ),
            ),
          ),
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildTextField(
                controller: _fundusRe.maculaOther,
                label: 'Macula (other)',
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildTextField(
                controller: _fundusLe.maculaOther,
                label: 'Macula (other)',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _sectionCard(
      title: '7. Location of Uveitis (RE / LE)',
      child: Column(
        children: [
          _buildEyeTwoColumn(
            left: _buildEyeField(
              eye: 'RE',
              child: _buildDropdown(
                label: 'Location',
                value: _uveaLocation['RE'],
                items: _locationOptions,
                onChanged: (value) =>
                    setState(() => _uveaLocation['RE'] = value),
              ),
            ),
            right: _buildEyeField(
              eye: 'LE',
              child: _buildDropdown(
                label: 'Location',
                value: _uveaLocation['LE'],
                items: _locationOptions,
                onChanged: (value) =>
                    setState(() => _uveaLocation['LE'] = value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationsSection() {
    return _sectionCard(
      title: '8. Investigations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _labTestsController,
            label: 'Relevant laboratory tests',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          const Text(
            'Imaging',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _imagingOptions.map((option) {
              final selected = _imaging.contains(option);
              return FilterChip(
                label: Text(option),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _imaging.add(option);
                    } else {
                      _imaging.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (widget.caseId == null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Save the case first to upload images.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          OutlinedButton.icon(
            onPressed: widget.caseId == null
                ? null
                : () => context.push('/cases/${widget.caseId}/media'),
            icon: const Icon(Icons.image_outlined),
            label: const Text('Upload Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisSection() {
    return _sectionCard(
      title: '9. Impression / Diagnosis',
      child: Column(
        children: [
          _buildTextField(
            controller: _diagnosisController,
            label: 'Working diagnosis',
            validator: _required,
          ),
          _buildTextField(
            controller: _etiologyController,
            label: 'Etiology (if known)',
          ),
        ],
      ),
    );
  }

  Widget _buildExtraNotesSection() {
    return _sectionCard(
      title: '10. Extra Notes',
      child: Column(
        children: [
          _buildTextField(
            controller: _extraNotesController,
            label: 'Additional observations',
            maxLines: 3,
          ),
          _buildTextField(
            controller: _followUpController,
            label: 'Follow-up plan',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String value)? labelBuilder,
    String? Function(String?)? validator,
  }) {
    final effectiveValue =
        value != null && items.contains(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: effectiveValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(labelBuilder?.call(item) ?? item),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildYesNo({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<bool>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: const [
          DropdownMenuItem(value: true, child: Text('Yes')),
          DropdownMenuItem(value: false, child: Text('No')),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPresenceDropdown({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<bool>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: const [
          DropdownMenuItem(value: true, child: Text('Present')),
          DropdownMenuItem(value: false, child: Text('Absent')),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        decoration: const InputDecoration(labelText: 'Date of Examination'),
        validator: _required,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _examDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() {
              _examDate = picked;
              _dateController.text = _formatDate(picked);
            });
          }
        },
      ),
    );
  }

  Widget _buildEyeTwoColumn({
    required Widget left,
    required Widget right,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildTwoColumn({
    required Widget left,
    required Widget right,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              left,
              const SizedBox(height: 8),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildEyeField({
    required String eye,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eye,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Future<void> _loadCase() async {
    setState(() => _loadingCase = true);
    try {
      final c =
          await ref.read(clinicalCaseDetailProvider(widget.caseId!).future);
      _baseAnteriorSegment =
          Map<String, dynamic>.from(c.anteriorSegment ?? {});
      _baseFundus = Map<String, dynamic>.from(c.fundus ?? {});
      _patientNameController.text = c.patientName;
      _uidController.text = c.uidNumber;
      _mrnController.text = c.mrNumber;
      _ageController.text = c.patientAge.toString();
      _gender = c.patientGender;
      _examDate = c.dateOfExamination;
      _dateController.text = _formatDate(c.dateOfExamination);
      _durationController.text = c.complaintDurationValue.toString();
      _durationUnit = c.complaintDurationUnit;
      _bcvaRe = c.bcvaRe ?? '';
      _bcvaLe = c.bcvaLe ?? '';
      _iopReController.text = c.iopRe?.toString() ?? '';
      _iopLeController.text = c.iopLe?.toString() ?? '';
      _diagnosisController.text = c.diagnosis;
      _etiologyController.text = c.diagnosisOther ?? '';
      _followUpController.text = c.management ?? '';
      _extraNotesController.text = c.learningPoint ?? '';
      _chiefComplaintFallback = c.chiefComplaint;

      final meta = Map<String, dynamic>.from(
        _baseAnteriorSegment['uvea_meta'] as Map? ?? {},
      );
      _occupationController.text = (meta['occupation'] ?? '').toString();
      _addressController.text = (meta['address'] ?? '').toString();
      _laterality = meta['laterality'] as String?;
      _previousUveitis = _boolFrom(meta['previous_uveitis']);
      _symptoms
        ..clear()
        ..addAll((meta['symptoms'] as List?)?.cast<String>() ?? const []);
      if (_symptoms.isEmpty && _chiefComplaintFallback.trim().isNotEmpty) {
        final tokens = _chiefComplaintFallback
            .split(RegExp(r'[,/\n]'))
            .map((item) => item.trim().toLowerCase())
            .where((item) => item.isNotEmpty)
            .toList();
        for (final option in _symptomOptions) {
          if (tokens.contains(option.toLowerCase())) {
            _symptoms.add(option);
          }
        }
      }
      _systemicIllnesses
        ..clear()
        ..addAll(
            (meta['systemic_illness'] as List?)?.cast<String>() ?? const []);
      _systemicOtherController.text =
          (meta['systemic_other'] ?? '').toString();
      _drugHistoryController.text =
          (meta['drug_history'] ?? '').toString();
      _traumaController.text = (meta['trauma_surgery'] ?? '').toString();
      _familyHistoryController.text =
          (meta['family_history'] ?? '').toString();

      if (_systemicIllnesses.isEmpty) {
        final parsed = _splitSystemicHistory(c.systemicHistory);
        _systemicIllnesses.addAll(parsed.items);
        if (_systemicOtherController.text.trim().isEmpty) {
          _systemicOtherController.text = parsed.other;
        }
      }

      final uveaAnterior =
          Map<String, dynamic>.from(_baseAnteriorSegment['uvea'] as Map? ?? {});
      _anteriorRe.loadFrom(
        Map<String, dynamic>.from(uveaAnterior['RE'] as Map? ?? {}),
      );
      _anteriorLe.loadFrom(
        Map<String, dynamic>.from(uveaAnterior['LE'] as Map? ?? {}),
      );

      final uveaFundus =
          Map<String, dynamic>.from(_baseFundus['uvea'] as Map? ?? {});
      _fundusRe.loadFrom(
        Map<String, dynamic>.from(uveaFundus['RE'] as Map? ?? {}),
      );
      _fundusLe.loadFrom(
        Map<String, dynamic>.from(uveaFundus['LE'] as Map? ?? {}),
      );

      final location =
          Map<String, dynamic>.from(_baseFundus['uvea_location'] as Map? ?? {});
      _uveaLocation['RE'] = location['RE'] as String?;
      _uveaLocation['LE'] = location['LE'] as String?;

      final investigations = Map<String, dynamic>.from(
        _baseFundus['uvea_investigations'] as Map? ?? {},
      );
      _labTestsController.text =
          (investigations['lab_tests'] ?? '').toString();
      _imaging
        ..clear()
        ..addAll((investigations['imaging'] as List?)?.cast<String>() ??
            const []);

      final notes =
          Map<String, dynamic>.from(_baseFundus['uvea_notes'] as Map? ?? {});
      if (_extraNotesController.text.trim().isEmpty) {
        _extraNotesController.text = (notes['extra_notes'] ?? '').toString();
      }
      if (_followUpController.text.trim().isEmpty) {
        _followUpController.text = (notes['follow_up_plan'] ?? '').toString();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load case: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCase = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.tryParse(_ageController.text.trim());
    final duration = int.tryParse(_durationController.text.trim());
    if (age == null || age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid age')),
      );
      return;
    }
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid duration')),
      );
      return;
    }
    if (_symptoms.isEmpty && _chiefComplaintFallback.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one symptom')),
      );
      return;
    }
    final chiefComplaint = _symptoms.isNotEmpty
        ? _symptoms.join(', ')
        : _chiefComplaintFallback.trim();
    final systemicHistory = _buildSystemicHistory();

    final anterior = Map<String, dynamic>.from(_baseAnteriorSegment);
    anterior['uvea'] = {
      'RE': _anteriorRe.toMap(),
      'LE': _anteriorLe.toMap(),
    };
    anterior['uvea_meta'] = _buildUveaMeta();

    final fundus = Map<String, dynamic>.from(_baseFundus);
    fundus['uvea'] = {
      'RE': _fundusRe.toMap(),
      'LE': _fundusLe.toMap(),
    };
    fundus['uvea_location'] = {
      for (final entry in _uveaLocation.entries)
        if ((entry.value ?? '').trim().isNotEmpty) entry.key: entry.value,
    };
    fundus['uvea_investigations'] = _buildInvestigations();
    fundus['uvea_notes'] = _buildUveaNotes();

    final data = <String, dynamic>{
      'date_of_examination': _formatDate(_examDate),
      'patient_name': _patientNameController.text.trim(),
      'uid_number': _uidController.text.trim(),
      'mr_number': _mrnController.text.trim(),
      'patient_gender': _gender,
      'patient_age': age,
      'chief_complaint': chiefComplaint,
      'complaint_duration_value': duration,
      'complaint_duration_unit': _durationUnit,
      'systemic_history': systemicHistory,
      'bcva_re': _bcvaRe.isEmpty ? null : _bcvaRe,
      'bcva_le': _bcvaLe.isEmpty ? null : _bcvaLe,
      'iop_re': num.tryParse(_iopReController.text.trim()),
      'iop_le': num.tryParse(_iopLeController.text.trim()),
      'anterior_segment': anterior,
      'fundus': fundus,
      'diagnosis': _diagnosisController.text.trim(),
      'diagnosis_other': _etiologyController.text.trim(),
      'management': _followUpController.text.trim(),
      'learning_point': _extraNotesController.text.trim(),
      'keywords': _buildKeywords(),
      'status': 'draft',
    };

    try {
      final mutation = ref.read(clinicalCaseMutationProvider.notifier);
      if (widget.caseId == null) {
        final id = await mutation.create(data);
        if (mounted) {
          context.go('/cases/uvea/$id');
        }
      } else {
        await mutation.update(widget.caseId!, data);
        if (mounted) {
          context.go('/cases/uvea/${widget.caseId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _buildUveaMeta() {
    return {
      'occupation': _occupationController.text.trim(),
      'address': _addressController.text.trim(),
      'symptoms': _symptoms.toList(),
      'laterality': _laterality,
      'previous_uveitis': _previousUveitis,
      'systemic_illness': _systemicIllnesses.toList(),
      'systemic_other': _systemicOtherController.text.trim(),
      'drug_history': _drugHistoryController.text.trim(),
      'trauma_surgery': _traumaController.text.trim(),
      'family_history': _familyHistoryController.text.trim(),
    };
  }

  Map<String, dynamic> _buildInvestigations() {
    return {
      'lab_tests': _labTestsController.text.trim(),
      'imaging': _imaging.toList(),
    };
  }

  Map<String, dynamic> _buildUveaNotes() {
    return {
      'extra_notes': _extraNotesController.text.trim(),
      'follow_up_plan': _followUpController.text.trim(),
    };
  }

  List<String> _buildKeywords() {
    final keywords = <String>['uvea'];
    final diagnosis = _diagnosisController.text.trim();
    if (diagnosis.isNotEmpty &&
        keywords.every((k) => k.toLowerCase() != diagnosis.toLowerCase())) {
      keywords.add(diagnosis);
    }
    return keywords.take(5).toList();
  }

  List<String> _buildSystemicHistory() {
    final items = _systemicIllnesses.toList();
    final other = _systemicOtherController.text.trim();
    if (items.contains('Other')) {
      items.removeWhere((item) => item == 'Other');
      if (other.isNotEmpty) {
        items.add('Others: $other');
      }
    }
    return items;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a number';
    return null;
  }

  String? _otherValidator(String? selection, String? value) {
    if (selection != 'Other') return null;
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _hypopyonValidator(bool? selected, String? value) {
    if (selected != true) return null;
    if (value == null || value.trim().isEmpty) return 'Required';
    if (double.tryParse(value.trim()) == null) return 'Enter a number';
    return null;
  }

  _SystemicHistorySplit _splitSystemicHistory(List<dynamic> items) {
    String other = '';
    final cleaned = <String>[];
    for (final item in items) {
      final value = item.toString();
      if (value.toLowerCase().startsWith('others:')) {
        other = value.substring(7).trim();
      } else if (value.isNotEmpty) {
        cleaned.add(value);
      }
    }
    return _SystemicHistorySplit(cleaned, other);
  }
}

class _SystemicHistorySplit {
  const _SystemicHistorySplit(this.items, this.other);
  final List<String> items;
  final String other;
}

class _UveaAnteriorEyeState {
  String? conjunctiva;
  final TextEditingController conjunctivaOther = TextEditingController();
  bool? keratitis;
  String? kpsType;
  String? kpsDistribution;
  String? acCells;
  String? flare;
  bool? fm;
  bool? hypopyon;
  final TextEditingController hypopyonHeight = TextEditingController();
  String? irisNodules;
  final TextEditingController irisNodulesOther = TextEditingController();
  String? irisSynechiae;
  bool? irisRubeosis;
  String? glaucoma;
  final TextEditingController glaucomaOther = TextEditingController();
  String? lensStatus;

  void dispose() {
    conjunctivaOther.dispose();
    hypopyonHeight.dispose();
    irisNodulesOther.dispose();
    glaucomaOther.dispose();
  }

  void loadFrom(Map<String, dynamic> data) {
    conjunctiva = data['conjunctiva'] as String?;
    conjunctivaOther.text = (data['conjunctiva_other'] ?? '').toString();
    keratitis = _boolFrom(data['corneal_keratitis']);
    kpsType = data['kps_type'] as String?;
    kpsDistribution = data['kps_distribution'] as String?;
    acCells = data['ac_cells'] as String?;
    flare = data['flare'] as String?;
    fm = _boolFrom(data['fm']);
    hypopyon = _boolFrom(data['hypopyon']);
    hypopyonHeight.text = (data['hypopyon_height_mm'] ?? '').toString();
    irisNodules = data['iris_nodules'] as String?;
    irisNodulesOther.text = (data['iris_nodules_other'] ?? '').toString();
    irisSynechiae = data['iris_synechiae'] as String?;
    irisRubeosis = _boolFrom(data['iris_rubeosis']);
    glaucoma = data['glaucoma'] as String?;
    glaucomaOther.text = (data['glaucoma_other'] ?? '').toString();
    lensStatus = data['lens_status'] as String?;
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{};
    _addIfNotEmpty(data, 'conjunctiva', conjunctiva);
    if (conjunctiva == 'Other') {
      _addIfNotEmpty(data, 'conjunctiva_other', conjunctivaOther.text.trim());
    }
    _addIfNotEmpty(data, 'corneal_keratitis', keratitis);
    _addIfNotEmpty(data, 'kps_type', kpsType);
    _addIfNotEmpty(data, 'kps_distribution', kpsDistribution);
    _addIfNotEmpty(data, 'ac_cells', acCells);
    _addIfNotEmpty(data, 'flare', flare);
    _addIfNotEmpty(data, 'fm', fm);
    _addIfNotEmpty(data, 'hypopyon', hypopyon);
    if (hypopyon == true) {
      _addIfNotEmpty(data, 'hypopyon_height_mm', hypopyonHeight.text.trim());
    }
    _addIfNotEmpty(data, 'iris_nodules', irisNodules);
    if (irisNodules == 'Other') {
      _addIfNotEmpty(
        data,
        'iris_nodules_other',
        irisNodulesOther.text.trim(),
      );
    }
    _addIfNotEmpty(data, 'iris_synechiae', irisSynechiae);
    _addIfNotEmpty(data, 'iris_rubeosis', irisRubeosis);
    _addIfNotEmpty(data, 'glaucoma', glaucoma);
    if (glaucoma == 'Other') {
      _addIfNotEmpty(data, 'glaucoma_other', glaucomaOther.text.trim());
    }
    _addIfNotEmpty(data, 'lens_status', lensStatus);
    return data;
  }
}

class _UveaFundusEyeState {
  final TextEditingController avfVitreous = TextEditingController();
  bool? snowballs;
  String? opticDisc;
  String? vessels;
  String? vesselsType;
  String? retinitis;
  String? choroiditis;
  bool? snowbanking;
  bool? exudativeRd;
  final TextEditingController backgroundOther = TextEditingController();
  bool? maculaCme;
  bool? maculaExudates;
  final TextEditingController maculaOther = TextEditingController();

  void dispose() {
    avfVitreous.dispose();
    backgroundOther.dispose();
    maculaOther.dispose();
  }

  void loadFrom(Map<String, dynamic> data) {
    avfVitreous.text = (data['avf_vitreous'] ?? '').toString();
    snowballs = _boolFrom(data['media_snowballs']);
    opticDisc = data['optic_disc'] as String?;
    vessels = data['vessels'] as String?;
    vesselsType = data['vessels_type'] as String?;
    retinitis = data['background_retinitis'] as String?;
    choroiditis = data['background_choroiditis'] as String?;
    snowbanking = _boolFrom(data['background_snowbanking']);
    exudativeRd = _boolFrom(data['background_exudative_rd']);
    backgroundOther.text = (data['background_other'] ?? '').toString();
    maculaCme = _boolFrom(data['macula_cme']);
    maculaExudates = _boolFrom(data['macula_exudates']);
    maculaOther.text = (data['macula_other'] ?? '').toString();
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{};
    _addIfNotEmpty(data, 'avf_vitreous', avfVitreous.text.trim());
    _addIfNotEmpty(data, 'media_snowballs', snowballs);
    _addIfNotEmpty(data, 'optic_disc', opticDisc);
    _addIfNotEmpty(data, 'vessels', vessels);
    if (vessels == 'Vasculitis') {
      _addIfNotEmpty(data, 'vessels_type', vesselsType);
    }
    _addIfNotEmpty(data, 'background_retinitis', retinitis);
    _addIfNotEmpty(data, 'background_choroiditis', choroiditis);
    _addIfNotEmpty(data, 'background_snowbanking', snowbanking);
    _addIfNotEmpty(data, 'background_exudative_rd', exudativeRd);
    _addIfNotEmpty(data, 'background_other', backgroundOther.text.trim());
    _addIfNotEmpty(data, 'macula_cme', maculaCme);
    _addIfNotEmpty(data, 'macula_exudates', maculaExudates);
    _addIfNotEmpty(data, 'macula_other', maculaOther.text.trim());
    return data;
  }
}

void _addIfNotEmpty(Map<String, dynamic> map, String key, dynamic value) {
  if (value == null) return;
  if (value is String && value.trim().isEmpty) return;
  map[key] = value;
}

bool? _boolFrom(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'yes' || lower == 'present') return true;
    if (lower == 'no' || lower == 'absent') return false;
  }
  return null;
}
