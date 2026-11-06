import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/l10n/app_copy.dart';
import '../../../../../shared/ui/theme/app_design.dart';
import '../../../../../shared/ui/theme/tokens/app_spacing.dart';

/// An inline editor that keeps the caret and draft text in the tapped cell.
class MobileRangeCell extends StatefulWidget {
  /// Shows [value] and forwards edits through [onChanged]. On blur,
  /// [finishEditing] returns the committed value to display.
  ///
  /// [onNext] and [onPrevious] move focus to adjacent Group Size cells
  /// when the keyboard sends the corresponding navigation action.
  /// [keyboardVisible] centers the focused row in the grid's scroll area.
  const MobileRangeCell({
    super.key,
    required this.value,
    required this.keyboardVisible,
    required this.onFocused,
    required this.onChanged,
    required this.finishEditing,
    this.onNext,
    this.onPrevious,
  });

  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final String value;
  final bool keyboardVisible;
  final VoidCallback onFocused;
  final ValueChanged<String> onChanged;
  final String Function(String) finishEditing;

  @override
  State<MobileRangeCell> createState() => MobileRangeCellState();
}

/// Owns the text and focus for one inline editor.
class MobileRangeCellState extends State<MobileRangeCell>
    with WidgetsBindingObserver {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  /// Opens the editor for this row.
  void requestFocus() => _focus.requestFocus();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(MobileRangeCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
    if (_focus.hasFocus &&
        widget.keyboardVisible != oldWidget.keyboardVisible) {
      _revealAfterLayout();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      WidgetsBinding.instance.addObserver(this);
      widget.onFocused();
      // PlutoGrid requests focus for its own node when the grid gains focus.
      // Keep the tap's focus on the editable child instead.
      _focus.requestFocus();
      _revealAfterLayout(animateCenter: widget.keyboardVisible);
    } else {
      WidgetsBinding.instance.removeObserver(this);
      _controller.text = widget.finishEditing(_controller.text);
    }
  }

  @override
  void didChangeMetrics() => _revealAfterLayout();

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Flutter Web turns the input element's Return event into its configured
    // text input action. Handle raw Return only on native platforms.
    if (!kIsWeb &&
        event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      if (widget.onNext case final next?) {
        next();
      } else {
        _focus.unfocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.skipRemainingHandlers;
  }

  /// The keyboard can resize both the page and PlutoGrid's scroll viewport.
  /// Reveal the cell after layout, then center it in the vertical row scroller
  /// while typing. Leave the horizontal position alone once the cell is visible.
  void _revealAfterLayout({bool animateCenter = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.hasFocus) {
        return;
      }

      final rows = widget.keyboardVisible
          ? Scrollable.maybeOf(context, axis: Axis.vertical)
          : null;
      final cell = context.findRenderObject();
      final animate =
          animateCenter &&
          rows != null &&
          cell != null &&
          !MediaQuery.disableAnimationsOf(context);
      if (!animate) {
        unawaited(
          Scrollable.ensureVisible(
            context,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ),
        );
      }
      if (rows != null && cell != null) {
        unawaited(
          rows.position.ensureVisible(
            cell,
            alignment: 0.5,
            duration: animate ? AppDesign.motionMedium : Duration.zero,
            curve: Curves.easeInOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
    // A tap anywhere in the next editable cell must transfer focus without
    // dismissing the current editor on pointer down.
    groupId: MobileRangeCell,
    child: Semantics(
      label: context.l10n.groupSize,
      child: SizedBox.expand(
        child: ListenableBuilder(
          listenable: _focus,
          builder: (context, child) => DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: _focus.hasFocus
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: AppDesign.borderFocus,
                    )
                  : null,
            ),
            child: child,
          ),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            // Let the usual text shortcuts run first. Unhandled keys go to the
            // platform text input instead of being consumed by PlutoGrid.
            onKeyEvent: _handleKeyEvent,
            child: DefaultTextEditingShortcuts(
              // Keep the input at its natural height and center it in the cell.
              // The surrounding area still focuses the same editor when tapped.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _focus.requestFocus,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FocusTraversalGroup(
                    policy: _RangeRowTraversal(
                      onNext: widget.onNext,
                      onPrevious: widget.onPrevious,
                    ),
                    child: TextField(
                      groupId: MobileRangeCell,
                      controller: _controller,
                      focusNode: _focus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: widget.onNext == null
                          ? TextInputAction.done
                          : TextInputAction.next,
                      selectAllOnFocus: false,
                      onChanged: widget.onChanged,
                      onTapOutside: (_) => _focus.unfocus(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        filled: false,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Routes Flutter's keyboard traversal through the grid, which can mount an
/// adjacent editor after scrolling it into view.
class _RangeRowTraversal extends WidgetOrderTraversalPolicy {
  _RangeRowTraversal({this.onNext, this.onPrevious});

  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  bool next(FocusNode currentNode) => _move(onNext);

  @override
  bool previous(FocusNode currentNode) => _move(onPrevious);

  bool _move(VoidCallback? callback) {
    callback?.call();
    return callback != null;
  }
}
