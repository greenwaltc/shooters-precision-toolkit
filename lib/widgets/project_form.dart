// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';

import '../config/project_configuration.dart';
import '../model/project_form_model.dart';
import '../sample_size_catalog.dart';
import '../styles/components/app_text_field_decoration.dart';
import '../styles/components/grouped_field_panel.dart';
import '../styles/components/matrix_grid_style.dart';
import '../styles/components/section_title.dart';
import '../styles/layout/app_layout.dart';
import '../styles/layout/app_viewport.dart';
import '../styles/tokens/app_spacing.dart';
import '../styles/tokens/app_text_styles.dart';
import 'anomr_matrix/widgets/grid_scroll_cue.dart';
import 'project_form/controllers/factor_input_controllers.dart';
import 'project_form/models/factor_field_hints.dart';
import 'project_form/services/project_form_validator.dart';

/// Project setup form for experiment design, risk, and sample-size choices.
class ProjectForm extends StatefulWidget {
  const ProjectForm({super.key, required this.formModel, this.onSubmit});

  /// Mutable setup state shared with the selected project.
  final ProjectFormModel formModel;

  /// Called after validation succeeds.
  final Future<void> Function()? onSubmit;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _fieldsScrollController = ScrollController();
  final projectTitleController = TextEditingController();
  late final List<FactorInputControllers> _factorControllers;
  bool _isHydratingControllers = false;

  /// Distance (in pixels) from an edge before a scroll cue is hidden.
  static const double _scrollCueEpsilon = 1;

  bool _showTopScrollCue = false;
  bool _showBottomScrollCue = false;

  @override
  void initState() {
    super.initState();

    projectTitleController.text = widget.formModel.projectTitle;
    projectTitleController.addListener(_syncProjectTitle);

    _factorControllers = List.generate(
      ExperimentStructure.fourFactors.factorCount,
      (index) => FactorInputControllers(),
    );
    _hydrateFactorControllers();

    for (var index = 0; index < _factorControllers.length; index++) {
      _factorControllers[index].addListener(() => _syncFactorDefinition(index));
    }

    _scheduleScrollCueUpdate();
  }

  @override
  void dispose() {
    _fieldsScrollController.dispose();
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

    if (!_formKey.currentState!.validate()) {
      _scrollToFirstInvalidField();
      return;
    }

    await widget.onSubmit?.call();
  }

  void _scrollToFirstInvalidField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final invalidField = _findFirstInvalidField(_formKey.currentContext);
      if (invalidField == null) return;

      Scrollable.ensureVisible(
        invalidField,
        alignment: 0.2,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  Element? _findFirstInvalidField(BuildContext? root) {
    if (root == null) return null;

    Element? firstInvalidField;

    void visit(Element element) {
      if (firstInvalidField != null) return;

      if (element is StatefulElement) {
        final state = element.state;
        if (state is FormFieldState<String> && !state.isValid) {
          firstInvalidField = element;
          return;
        }
      }

      element.visitChildren(visit);
    }

    root.visitChildElements(visit);
    return firstInvalidField;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AppLayoutBuilder(
        builder: (context, layout) => _buildFormLayout(context, layout),
      ),
    );
  }

  /// Splits the form into a scrollable field region and a statically pinned
  /// submit button so the submit action is always visible.
  Widget _buildFormLayout(BuildContext context, AppLayoutMetrics layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildScrollableFields(context, layout)),
        _buildSubmitButton(layout),
      ],
    );
  }

  Widget _buildScrollableFields(BuildContext context, AppLayoutMetrics layout) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _scheduleScrollCueUpdate();
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (_) {
              _scheduleScrollCueUpdate();
              return false;
            },
            child: SingleChildScrollView(
              controller: _fieldsScrollController,
              padding: AppViewport.scrollBottomPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildFormTitle(context),
                  const SizedBox(height: AppSpacing.md),
                  _buildResponsiveFieldGroups(layout),
                ],
              ),
            ),
          ),
        ),
        if (_showTopScrollCue)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GridScrollCue(
              edge: MatrixScrollCueEdge.top,
              scheme: scheme,
            ),
          ),
        if (_showBottomScrollCue)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GridScrollCue(
              edge: MatrixScrollCueEdge.bottom,
              scheme: scheme,
            ),
          ),
      ],
    );
  }

  void _scheduleScrollCueUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final controller = _fieldsScrollController;
      if (!controller.hasClients) return;

      final position = controller.position;
      final showTop = position.pixels > _scrollCueEpsilon;
      final showBottom =
          position.pixels < position.maxScrollExtent - _scrollCueEpsilon;

      if (showTop != _showTopScrollCue || showBottom != _showBottomScrollCue) {
        setState(() {
          _showTopScrollCue = showTop;
          _showBottomScrollCue = showBottom;
        });
      }
    });
  }

  Widget _buildFormTitle(BuildContext context) {
    return Center(
      child: Text(
        'Project Setup',
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResponsiveFieldGroups(AppLayoutMetrics layout) {
    final setupFields = _buildSetupFields();
    final sampleFields = _buildSampleFields();

    if (!layout.useTwoColumnForms) {
      return _fieldColumn([...setupFields, ...sampleFields]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _fieldColumn(setupFields)),
        const SizedBox(width: AppSpacing.xxxxl),
        Expanded(flex: 4, child: _fieldColumn(sampleFields)),
      ],
    );
  }

  List<Widget> _buildSetupFields() {
    return [
      _buildProjectNameInput(),
      const SectionTitle('Choose the Structure of Your Experiment'),
      _buildExperimentStructureOptions(),
      _buildFactorDefinitionContainer(),
    ];
  }

  List<Widget> _buildSampleFields() {
    return [
      const SectionTitle(
        'Choose your risk level (chance of being wrong if test indicates '
        'a real difference in factor states)',
      ),
      _buildRiskLevelOptions(),
      const SectionTitle('Choose your sample size'),
      _buildSampleSizeOptions(),
      if (_canShowImputationOption()) _buildImputeMissingDataCheckbox(),
    ];
  }

  Widget _fieldColumn(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  bool _canShowImputationOption() {
    return ProjectConfiguration.current.featureFlags.isEnabled(
      FeatureFlag.imputeMissingData,
    );
  }

  Widget _buildProjectNameInput() {
    return _buildTextField(
      controller: projectTitleController,
      labelText: 'Project Name',
      prefixIcon: Icons.title,
      validator: (value) => ProjectFormValidator.requiredField(
        value,
        'Project name is required.',
      ),
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
    final hints = factorFieldHintsByIndex[index];

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
          hintText: hints.factorName,
          validator: (value) => _validateFactorName(index, value),
        ),
        _buildTextField(
          controller: controllers.firstStateName,
          labelText: 'Name one state of that factor',
          hintText: hints.firstState,
          validator: (value) => _validateFactorState(
            value: value,
            comparedController: controllers.secondStateName,
          ),
        ),
        _buildTextField(
          controller: controllers.secondStateName,
          labelText: 'Name the other state of that factor',
          hintText: hints.secondState,
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
      factorCount: widget.formModel.experimentStructure.factorCount,
      riskLevel: widget.formModel.riskLevel,
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
    return Padding(
      padding: AppSpacing.radioItemVertical,
      child: RadioListTile<SampleSizeOption>(
        value: option,
        title: Text(
          option.formOptionLabel(widget.formModel.experimentStructure),
        ),
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
    final detectableLabel = option.detectableDifferenceLabel(riskLevel);

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
      title: const Text('Impute missing data with the grand mean'),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (value) {
        setState(() {
          widget.formModel.setImputeMissingData(value ?? false);
        });
      },
    );
  }

  Widget _buildSubmitButton(AppLayoutMetrics layout) {
    final button = ElevatedButton(
      onPressed: _onSubmitClicked,
      child: const Text('Submit'),
    );

    return Padding(
      padding: AppSpacing.fieldPadding,
      child: layout.useStackedActions
          ? SizedBox(width: double.infinity, child: button)
          : Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160),
                child: button,
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String hintText = '',
    IconData? prefixIcon,
    required FormFieldValidator<String> validator,
  }) {
    return Padding(
      padding: AppSpacing.fieldPadding,
      child: TextFormField(
        controller: controller,
        decoration: buildAppTextFieldDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          controller: controller,
        ),
        textInputAction: TextInputAction.next,
        validator: validator,
      ),
    );
  }

  String? _validateFactorName(int index, String? value) {
    return ProjectFormValidator.factorName(
      index: index,
      value: value,
      controllers: _factorControllers,
      factorCount: widget.formModel.experimentStructure.factorCount,
    );
  }

  String? _validateFactorState({
    required String? value,
    required TextEditingController comparedController,
  }) {
    return ProjectFormValidator.factorState(
      value: value,
      comparedController: comparedController,
    );
  }
}
