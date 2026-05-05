// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../model/detectable_difference.dart';
import '../model/project_form_model.dart';
import '../styles/components/app_text_field_decoration.dart';
import '../styles/components/grouped_field_panel.dart';
import '../styles/components/section_title.dart';
import '../styles/tokens/app_spacing.dart';
import '../styles/tokens/app_text_styles.dart';

class ProjectForm extends StatefulWidget {
  final ProjectFormModel formModel;
  final Future<void> Function()? onSubmit;

  const ProjectForm({super.key, required this.formModel, this.onSubmit});

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final projectTitleController = TextEditingController();
  late final List<_FactorInputControllers> _factorControllers;
  bool _isHydratingControllers = false;

  @override
  void initState() {
    super.initState();

    projectTitleController.text = widget.formModel.projectTitle;
    projectTitleController.addListener(_syncProjectTitle);

    _factorControllers = List.generate(
      ExperimentStructure.fourFactors.factorCount,
      (index) => _FactorInputControllers(),
    );
    _hydrateFactorControllers();

    for (var index = 0; index < _factorControllers.length; index++) {
      _factorControllers[index].addListener(() => _syncFactorDefinition(index));
    }
  }

  @override
  void dispose() {
    projectTitleController.dispose();
    for (final controllers in _factorControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ProjectForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.formModel != widget.formModel) {
      projectTitleController.text = widget.formModel.projectTitle;
      _hydrateFactorControllers();
    }
  }

  void _hydrateFactorControllers() {
    _isHydratingControllers = true;
    final definitions = widget.formModel.factorDefinitions;

    for (var index = 0; index < _factorControllers.length; index++) {
      final definition = index < definitions.length
          ? definitions[index]
          : const FactorDefinition();
      _factorControllers[index].setValues(definition);
    }
    _isHydratingControllers = false;
  }

  void _syncProjectTitle() {
    widget.formModel.setProjectTitle(projectTitleController.text);
  }

  void _syncFactorDefinition(int index, {bool trimValues = false}) {
    if (_isHydratingControllers) return;
    if (index >= widget.formModel.experimentStructure.factorCount) return;

    final controllers = _factorControllers[index];
    widget.formModel.setFactorDefinition(
      index: index,
      name: _controllerValue(controllers.factorName, trimValues),
      firstState: _controllerValue(controllers.firstStateName, trimValues),
      secondState: _controllerValue(controllers.secondStateName, trimValues),
    );
  }

  String _controllerValue(TextEditingController controller, bool trimValues) {
    return trimValues ? controller.text.trim() : controller.text;
  }

  void _syncFormModel({bool trimValues = false}) {
    widget.formModel.setProjectTitle(
      _controllerValue(projectTitleController, trimValues),
    );

    for (
      var index = 0;
      index < widget.formModel.experimentStructure.factorCount;
      index++
    ) {
      _syncFactorDefinition(index, trimValues: trimValues);
    }
  }

  Future<void> _onSubmitClicked() async {
    _syncFormModel(trimValues: true);

    if (!_formKey.currentState!.validate()) return;

    await widget.onSubmit?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: AppSpacing.scrollBottom,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Text(
                'Analysis of Mean Ranges Project Setup',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildProjectNameInput(),
            const SectionTitle('Choose the Structure of Your Experiment'),
            _buildExperimentStructureOptions(),
            _buildFactorDefinitionContainer(),
            const SectionTitle(
              'Choose Your Risk Level (chance of being wrong if test indicates '
              'a real difference in factor states)',
            ),
            _buildRiskLevelOptions(),
            const SectionTitle('Choose your sample size'),
            _buildSampleSizeOptions(),
            _buildImputeMissingDataCheckbox(),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectNameInput() {
    return _buildTextField(
      controller: projectTitleController,
      labelText: 'Project Name',
      prefixIcon: Icons.title,
      validator: (value) => _requiredField(value, 'Project name is required.'),
    );
  }

  Widget _buildExperimentStructureOptions() {
    return RadioGroup<ExperimentStructure>(
      groupValue: widget.formModel.experimentStructure,
      onChanged: (structure) {
        if (structure == null) return;

        setState(() {
          widget.formModel.setExperimentStructure(structure);
          _clearHiddenFactorControllers();
        });
      },
      child: Column(
        children: ExperimentStructure.values.map((structure) {
          return RadioListTile<ExperimentStructure>(
            value: structure,
            title: Text(structure.label),
            selected: widget.formModel.experimentStructure == structure,
          );
        }).toList(),
      ),
    );
  }

  void _clearHiddenFactorControllers() {
    for (
      var index = widget.formModel.experimentStructure.factorCount;
      index < _factorControllers.length;
      index++
    ) {
      _factorControllers[index].clear();
    }
  }

  Widget _buildFactorDefinitionContainer() {
    final factorCount = widget.formModel.experimentStructure.factorCount;

    return GroupedFieldPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < factorCount; index++) ...[
            _buildFactorFields(index),
            if (index < factorCount - 1) const Divider(height: AppSpacing.xxxl),
          ],
        ],
      ),
    );
  }

  Widget _buildFactorFields(int index) {
    final controllers = _factorControllers[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.factorTitle,
          child: Text(
            'Factor ${index + 1}',
            style: AppTextStyles.factorLabel(context),
          ),
        ),
        _buildTextField(
          controller: controllers.factorName,
          labelText: 'Name Factor',
          prefixIcon: Icons.tune,
          validator: (value) => _validateFactorName(index, value),
        ),
        _buildTextField(
          controller: controllers.firstStateName,
          labelText: 'Name one state of that factor',
          prefixIcon: Icons.radio_button_checked,
          validator: (value) => _validateFactorState(
            value: value,
            comparedController: controllers.secondStateName,
          ),
        ),
        _buildTextField(
          controller: controllers.secondStateName,
          labelText: 'Name the other state of that factor',
          prefixIcon: Icons.radio_button_unchecked,
          validator: (value) => _validateFactorState(
            value: value,
            comparedController: controllers.firstStateName,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskLevelOptions() {
    return RadioGroup<RiskLevel>(
      groupValue: widget.formModel.riskLevel,
      onChanged: (level) {
        if (level == null) return;

        setState(() => widget.formModel.setRiskLevel(level));
      },
      child: Column(
        children: RiskLevel.values.map((level) {
          return RadioListTile<RiskLevel>(
            value: level,
            title: Text(level.label),
            selected: widget.formModel.riskLevel == level,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSampleSizeOptions() {
    final options = SampleSizeCatalog.optionsFor(
      widget.formModel.experimentStructure,
    );

    return RadioGroup<SampleSizeOption>(
      groupValue: widget.formModel.sampleSizeOption,
      onChanged: (option) {
        if (option == null) return;

        setState(() => widget.formModel.setSampleSizeOption(option));
      },
      child: Column(children: options.map(_buildSampleSizeOption).toList()),
    );
  }

  Widget _buildSampleSizeOption(SampleSizeOption option) {
    final structure = widget.formModel.experimentStructure;

    return Padding(
      padding: AppSpacing.radioItemVertical,
      child: RadioListTile<SampleSizeOption>(
        value: option,
        title: Text(option.labelFor(structure)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: _buildDetectableDifferenceTable(option),
        ),
        selected: widget.formModel.sampleSizeOption == option,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildDetectableDifferenceTable(SampleSizeOption option) {
    final headerStyle = AppTextStyles.formTableHeader(context);
    final riskLevel = widget.formModel.riskLevel;
    final detectableLabel = DetectableDifference.formatFraction(
      DetectableDifference.fractionForOption(
        option: option,
        riskLevel: riskLevel,
      ),
    );

    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
      children: [
        _buildTableRow(
          'Risk Level',
          'Detects Difference of',
          textStyle: headerStyle,
        ),
        _buildTableRow(riskLevel.label, detectableLabel),
      ],
    );
  }

  TableRow _buildTableRow(
    String riskLevel,
    String detectableDifference, {
    TextStyle? textStyle,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: AppSpacing.tableCellVertical,
          child: Text(riskLevel, style: textStyle),
        ),
        Padding(
          padding: AppSpacing.tableCellVertical,
          child: Text(detectableDifference, style: textStyle),
        ),
      ],
    );
  }

  Widget _buildImputeMissingDataCheckbox() {
    return CheckboxListTile(
      value: widget.formModel.imputeMissingData,
      title: const Text('Impute missing data'),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (value) {
        setState(() {
          widget.formModel.setImputeMissingData(value ?? false);
        });
      },
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: AppSpacing.fieldPadding,
      child: ElevatedButton(
        onPressed: _onSubmitClicked,
        child: const Text('Submit'),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required FormFieldValidator<String> validator,
  }) {
    return Padding(
      padding: AppSpacing.fieldPadding,
      child: TextFormField(
        controller: controller,
        decoration: buildAppTextFieldDecoration(
          labelText: labelText,
          prefixIcon: Icon(prefixIcon),
          controller: controller,
        ),
        textInputAction: TextInputAction.next,
        validator: validator,
      ),
    );
  }

  String? _requiredField(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? _validateFactorName(int index, String? value) {
    final requiredError = _requiredField(value, 'Factor name is required.');
    if (requiredError != null) return requiredError;

    final normalizedValue = value!.trim().toLowerCase();
    final hasDuplicate = _factorControllers
        .take(widget.formModel.experimentStructure.factorCount)
        .indexed
        .any((entry) {
          final otherIndex = entry.$1;
          final otherValue = entry.$2.factorName.text.trim().toLowerCase();
          return otherIndex != index && otherValue == normalizedValue;
        });

    return hasDuplicate ? 'Each factor name must be unique.' : null;
  }

  String? _validateFactorState({
    required String? value,
    required TextEditingController comparedController,
  }) {
    final requiredError = _requiredField(value, 'Factor state is required.');
    if (requiredError != null) return requiredError;

    final normalizedValue = value!.trim().toLowerCase();
    final comparedValue = comparedController.text.trim().toLowerCase();

    if (normalizedValue == comparedValue) {
      return 'Factor states must be different.';
    }

    return null;
  }
}

class _FactorInputControllers {
  final factorName = TextEditingController();
  final firstStateName = TextEditingController();
  final secondStateName = TextEditingController();

  void addListener(VoidCallback listener) {
    factorName.addListener(listener);
    firstStateName.addListener(listener);
    secondStateName.addListener(listener);
  }

  void setValues(FactorDefinition definition) {
    factorName.text = definition.name;
    firstStateName.text = definition.firstState;
    secondStateName.text = definition.secondState;
  }

  void clear() {
    factorName.clear();
    firstStateName.clear();
    secondStateName.clear();
  }

  void dispose() {
    factorName.dispose();
    firstStateName.dispose();
    secondStateName.dispose();
  }
}
