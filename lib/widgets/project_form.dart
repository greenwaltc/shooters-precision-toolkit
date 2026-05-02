import 'package:flutter/material.dart';
import 'package:shooters_precision_toolkit/widgets/form_text_input.dart';

import '../model/project_form_model.dart';

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
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Text(
                'Analysis of Mean Ranges Project Setup',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8.0),
            _buildProjectNameInput(),
            _buildSectionTitle('Choose the Structure of Your Experiment'),
            _buildExperimentStructureOptions(),
            _buildFactorDefinitionContainer(),
            _buildSectionTitle(
              'Choose Your Risk Level (chance of being wrong if test indicates '
              'a real difference in factor states)',
            ),
            _buildRiskLevelOptions(),
            _buildSectionTitle('Choose your sample size'),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 20.0, 8.0, 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey, width: 1.5),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < factorCount; index++) ...[
              _buildFactorFields(index),
              if (index < factorCount - 1) const Divider(height: 24.0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFactorFields(int index) {
    final controllers = _factorControllers[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 4.0),
          child: Text(
            'Factor ${index + 1}',
            style: Theme.of(context).textTheme.titleSmall,
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
    final options = SampleSizeOption.optionsFor(
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RadioListTile<SampleSizeOption>(
        value: option,
        title: Text(option.labelFor(structure)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: _buildDetectableDifferenceTable(option),
        ),
        selected: widget.formModel.sampleSizeOption == option,
        isThreeLine: true,
      ),
    );
  }

  Widget _buildDetectableDifferenceTable(SampleSizeOption option) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
      children: [
        _buildTableRow(
          'Risk Level',
          'Detects Difference of',
          textStyle: headerStyle,
        ),
        _buildTableRow(
          widget.formModel.riskLevel.label,
          option.detectableDifferenceFor(widget.formModel.riskLevel),
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(riskLevel, style: textStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
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
      padding: const EdgeInsets.all(8.0),
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
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        decoration: buildTextInputDecoration(
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
