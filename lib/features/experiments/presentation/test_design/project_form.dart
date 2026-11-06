import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/l10n/app_copy.dart';
import '../../../../shared/ui/product_configuration.dart';
import '../../../../shared/ui/scroll_cue.dart';
import '../../../../shared/ui/theme/app_design.dart';
import '../../../../shared/ui/theme/components/app_text_field_decoration.dart';
import '../../../../shared/ui/theme/components/grouped_field_panel.dart';
import '../../../../shared/ui/theme/components/scroll_cue_style.dart';
import '../../../../shared/ui/theme/components/section_title.dart';
import '../../../../shared/ui/theme/layout/app_layout.dart';
import '../../../../shared/ui/theme/layout/app_viewport.dart';
import '../../../../shared/ui/theme/tokens/app_spacing.dart';
import '../../../../shared/ui/theme/tokens/app_text_styles.dart';
import '../../domain/sample_size_catalog.dart';
import 'controllers/factor_input_controllers.dart';
import 'project_form_model.dart';
import 'services/project_form_validator.dart';
import 'widgets/test_design_help_button.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Test Design form for experiment design, risk, and sample-size choices.
class ProjectForm extends StatefulWidget {
  /// Creates the experiment-design form around [formModel].
  ///
  /// [onSubmit], when supplied, lets the parent decide what happens when the
  /// user submits it from the bottom of the form. Scroll cues are hidden while
  /// a text field is focused in the mobile layout.
  /// Set [readOnly] to show the design without allowing changes or submission.
  /// [onReadOnlyFieldActivate] can request editing access when a form control
  /// is activated.
  const ProjectForm({
    super.key,
    required this.formModel,
    this.onSubmit,
    this.readOnly = false,
    this.onReadOnlyFieldActivate,
  });

  /// Mutable setup state shared with the selected project.
  final ProjectFormModel formModel;

  /// Called after validation succeeds.
  final Future<void> Function()? onSubmit;

  /// Whether editing controls and submission are disabled.
  final bool readOnly;

  /// Called when the user activates a field or option while read-only.
  final VoidCallback? onReadOnlyFieldActivate;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _fieldsScrollController = ScrollController();
  final _textFieldFocusNodes = <TextEditingController, FocusNode>{};
  final projectTitleController = TextEditingController();
  late final List<FactorInputControllers> _factorControllers;
  bool _isHydratingControllers = false;

  /// Distance (in pixels) from an edge before a scroll cue is hidden.
  static const double _scrollCueEpsilon = 1;

  final _scrollCues = ValueNotifier((top: false, bottom: false));
  bool _scrollCueUpdateScheduled = false;

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
    _scrollCues.dispose();
    for (final node in _textFieldFocusNodes.values) {
      node.dispose();
    }
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
      _isHydratingControllers = true;
      projectTitleController.text = widget.formModel.projectTitle;
      _hydrateFactorControllers();
    }
  }

  void _hydrateFactorControllers() {
    _isHydratingControllers = true;

    for (var index = 0; index < _factorControllers.length; index++) {
      _factorControllers[index].setValues(
        widget.formModel.storedFactorDefinitionAt(index),
      );
    }
    _isHydratingControllers = false;
  }

  void _syncProjectTitle() {
    if (!_isHydratingControllers && !widget.readOnly) {
      widget.formModel.setProjectTitle(projectTitleController.text);
    }
  }

  void _syncFactorDefinition(int index, {bool trimValues = false}) {
    if (_isHydratingControllers || widget.readOnly) {
      return;
    }
    if (index >= widget.formModel.experimentStructure.factorCount) {
      return;
    }

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
      if (!mounted) {
        return;
      }

      final invalidField = _findFirstInvalidField(_formKey.currentContext);
      if (invalidField == null) {
        return;
      }

      Scrollable.ensureVisible(
        invalidField,
        alignment: 0.2,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppDesign.motionMedium,
        curve: Curves.easeInOut,
      );
    });
  }

  Element? _findFirstInvalidField(BuildContext? root) {
    if (root == null) {
      return null;
    }

    Element? firstInvalidField;

    void visit(Element element) {
      if (firstInvalidField != null) {
        return;
      }

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
    return Theme(
      data: Theme.of(context).copyWith(
        visualDensity: MediaQuery.sizeOf(context).width >= 1024
            ? VisualDensity.compact
            : Theme.of(context).visualDensity,
        listTileTheme: AppLayoutMetrics.of(context).isMobile
            ? Theme.of(context).listTileTheme.copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
              )
            : Theme.of(context).listTileTheme,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AppLayoutBuilder(
          builder: (context, layout) => _buildScrollableForm(context, layout),
        ),
      ),
    );
  }

  Widget _buildScrollableForm(BuildContext context, AppLayoutMetrics layout) {
    final editingText =
        layout.isMobile &&
        !widget.readOnly &&
        _textFieldFocusNodes.values.any((node) => node.hasFocus);

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
                  _buildSubmitButton(layout),
                ],
              ),
            ),
          ),
        ),
        if (!editingText)
          Positioned.fill(
            child: ValueListenableBuilder(
              valueListenable: _scrollCues,
              builder: (context, cues, _) => Stack(
                children: [
                  if (cues.top)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: ScrollCue(edge: ScrollCueEdge.top),
                    ),
                  if (cues.bottom)
                    const Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ScrollCue(edge: ScrollCueEdge.bottom),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _scheduleScrollCueUpdate() {
    if (_scrollCueUpdateScheduled) {
      return;
    }
    _scrollCueUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCueUpdateScheduled = false;
      if (!mounted) {
        return;
      }

      final controller = _fieldsScrollController;
      if (!controller.hasClients) {
        return;
      }

      final position = controller.position;
      _scrollCues.value = (
        top: position.pixels > _scrollCueEpsilon,
        bottom: position.pixels < position.maxScrollExtent - _scrollCueEpsilon,
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Widget _buildFormTitle(BuildContext context) {
    return Align(
      alignment: AppLayoutMetrics.of(context).isMobile
          ? AlignmentDirectional.centerStart
          : Alignment.center,
      child: Text(
        context.l10n.testDesign,
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
      _buildSectionHeading(
        context.l10n.chooseTheStructureOfYourExperiment,
        context.l10n.experimentStructure,
        TestDesignHelpTopic.structure,
      ),
      _buildExperimentStructureOptions(),
      _buildFactorDefinitionContainer(),
    ];
  }

  List<Widget> _buildSampleFields() {
    return [
      _buildSectionHeading(
        context.l10n.chooseYourRiskLevelChanceOfBeingWrong,
        context.l10n.riskLevelMessage,
        TestDesignHelpTopic.risk,
      ),
      _buildRiskLevelOptions(),
      _buildSectionHeading(
        context.l10n.chooseYourSampleSize,
        context.l10n.sampleSize,
        TestDesignHelpTopic.sampleSize,
      ),
      _buildSampleSizeOptions(),
      if (_canShowImputationOption()) _buildImputeMissingDataCheckbox(),
    ];
  }

  Widget _buildSectionHeading(
    String title,
    String section,
    TestDesignHelpTopic topic,
  ) {
    return Row(
      children: [
        Expanded(child: Semantics(header: true, child: SectionTitle(title))),
        TestDesignHelpButton(section: section, topic: topic),
      ],
    );
  }

  Widget _fieldColumn(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  bool _canShowImputationOption() {
    return ProjectConfigurationScope.of(
      context,
    ).featureFlags.isEnabled(FeatureFlag.imputeMissingData);
  }

  Widget _buildProjectNameInput() {
    final label = context.l10n.projectName;
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: projectTitleController,
            labelText: label,
            prefixIcon: Icons.title,
            validator: (value) => ProjectFormValidator.requiredField(
              value,
              context.l10n.projectNameIsRequired,
            ),
          ),
        ),
        TestDesignHelpButton(
          section: label,
          topic: TestDesignHelpTopic.projectName,
        ),
      ],
    );
  }

  bool get _canActivateOptions =>
      !widget.readOnly || widget.onReadOnlyFieldActivate != null;

  void _changeOption<T>(T? value, ValueChanged<T> update) {
    if (widget.readOnly) {
      widget.onReadOnlyFieldActivate?.call();
    } else if (value != null) {
      setState(() => update(value));
    }
  }

  Widget _buildExperimentStructureOptions() {
    return GroupedFieldPanel(
      child: RadioGroup<ExperimentStructure>(
        groupValue: widget.formModel.experimentStructure,
        onChanged: (structure) =>
            _changeOption(structure, widget.formModel.setExperimentStructure),
        child: Column(
          children: ExperimentStructure.values.map((structure) {
            return RadioListTile<ExperimentStructure>(
              dense: MediaQuery.sizeOf(context).width >= 1024,
              minTileHeight: MediaQuery.sizeOf(context).width >= 1024
                  ? 40
                  : null,
              materialTapTargetSize: MediaQuery.sizeOf(context).width >= 1024
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
              visualDensity: MediaQuery.sizeOf(context).width >= 1024
                  ? VisualDensity.compact
                  : null,
              value: structure,
              enabled: _canActivateOptions,
              toggleable: widget.readOnly,
              title: Text(structure.label),
            );
          }).toList(),
        ),
      ),
    );
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
    final label = context.l10n.factorNumber(index + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: AppSpacing.factorTitle,
                child: Semantics(
                  header: true,
                  child: Text(label, style: AppTextStyles.factorLabel(context)),
                ),
              ),
            ),
            TestDesignHelpButton(
              section: label,
              topic: TestDesignHelpTopic.factorStates,
            ),
          ],
        ),
        _buildTextField(
          controller: controllers.factorName,
          labelText: context.l10n.nameFactor,
          validator: (value) => _validateFactorName(index, value),
        ),
        Padding(
          padding: AppLayoutMetrics.of(context).isMobile
              ? EdgeInsets.zero
              : AppSpacing.factorStateFieldIndent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: controllers.firstStateName,
                labelText: context.l10n.nameOneStateOfThatFactor,
                validator: (value) => _validateFactorState(
                  value: value,
                  comparedController: controllers.secondStateName,
                ),
              ),
              _buildTextField(
                controller: controllers.secondStateName,
                labelText: context.l10n.nameTheOtherStateOfThatFactor,
                validator: (value) => _validateFactorState(
                  value: value,
                  comparedController: controllers.firstStateName,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiskLevelOptions() {
    return GroupedFieldPanel(
      child: RadioGroup<RiskLevel>(
        groupValue: widget.formModel.riskLevel,
        onChanged: (level) =>
            _changeOption(level, widget.formModel.setRiskLevel),
        child: Column(
          children: RiskLevel.values.map((level) {
            return RadioListTile<RiskLevel>(
              dense: MediaQuery.sizeOf(context).width >= 1024,
              minTileHeight: MediaQuery.sizeOf(context).width >= 1024
                  ? 40
                  : null,
              materialTapTargetSize: MediaQuery.sizeOf(context).width >= 1024
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
              visualDensity: MediaQuery.sizeOf(context).width >= 1024
                  ? VisualDensity.compact
                  : null,
              value: level,
              enabled: _canActivateOptions,
              toggleable: widget.readOnly,
              title: Text(level.label),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSampleSizeOptions() {
    final options = SampleSizeCatalog.optionsFor(
      factorCount: widget.formModel.experimentStructure.factorCount,
      riskLevel: widget.formModel.riskLevel,
    );

    return GroupedFieldPanel(
      child: RadioGroup<SampleSizeOption>(
        groupValue: widget.formModel.sampleSizeOption,
        onChanged: (option) =>
            _changeOption(option, widget.formModel.setSampleSizeOption),
        child: Column(children: options.map(_buildSampleSizeOption).toList()),
      ),
    );
  }

  Widget _buildSampleSizeOption(SampleSizeOption option) {
    return RadioListTile<SampleSizeOption>(
      dense: MediaQuery.sizeOf(context).width >= 1024,
      minTileHeight: 56,
      value: option,
      enabled: _canActivateOptions,
      toggleable: widget.readOnly,
      title: Text(option.formOptionLabel(widget.formModel.experimentStructure)),
      subtitle: Text(
        context.l10n.detectsDifference(
          option.detectableDifferenceLabel(widget.formModel.riskLevel),
        ),
      ),
    );
  }

  Widget _buildImputeMissingDataCheckbox() {
    return Row(
      children: [
        Expanded(
          child: CheckboxListTile(
            value: widget.formModel.imputeMissingData,
            title: Text(context.l10n.imputeMissingDataWithTheGrandMean),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: _canActivateOptions
                ? (value) => _changeOption(
                    value ?? false,
                    widget.formModel.setImputeMissingData,
                  )
                : null,
          ),
        ),
        TestDesignHelpButton(
          section: context.l10n.missingData,
          topic: TestDesignHelpTopic.missingData,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AppLayoutMetrics layout) {
    final button = FilledButton.icon(
      onPressed: widget.readOnly ? null : _onSubmitClicked,
      icon: const Icon(Icons.check_rounded),
      label: Text(context.l10n.submit),
    );

    return Padding(
      padding: AppSpacing.fieldPadding.copyWith(bottom: 0),
      child: layout.useStackedActions
          ? SizedBox(width: double.infinity, child: button)
          : Align(
              alignment: AlignmentDirectional.centerEnd,
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
    final requestEditing = widget.readOnly
        ? widget.onReadOnlyFieldActivate
        : null;
    final field = TextFormField(
      controller: controller,
      focusNode: _textFieldFocusNodes.putIfAbsent(
        controller,
        () => FocusNode()..addListener(_handleTextFieldFocusChanged),
      ),
      readOnly: widget.readOnly,
      onTap: requestEditing,
      decoration: buildAppTextFieldDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        controller: widget.readOnly ? null : controller,
      ),
      textInputAction: TextInputAction.next,
      validator: validator,
    );
    return Padding(
      padding: AppSpacing.fieldPadding,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: requestEditing == null
            ? null
            : (_, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                  requestEditing();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
        child: field,
      ),
    );
  }

  void _handleTextFieldFocusChanged() {
    setState(() {});
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
