import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../shared/l10n/app_copy.dart';
import '../../../../../shared/ui/theme/app_design.dart';
import '../../../../../shared/ui/theme/tokens/app_spacing.dart';

/// An inline editor that keeps the caret and draft text in the tapped cell.
class MobileRangeCell extends StatefulWidget {
  /// Shows [value] and forwards edits through [onChanged]. On blur,
  /// [finishEditing] returns the committed value to display.
  const MobileRangeCell({
    super.key,
    required this.value,
    required this.onFocused,
    required this.onChanged,
    required this.finishEditing,
  });

  final String value;
  final VoidCallback onFocused;
  final ValueChanged<String> onChanged;
  final String Function(String) finishEditing;

  @override
  State<MobileRangeCell> createState() => _MobileRangeCellState();
}

class _MobileRangeCellState extends State<MobileRangeCell>
    with WidgetsBindingObserver {
  late final _controller = TextEditingController(text: widget.value);
  final _focus = FocusNode();

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
      _revealAfterLayout();
    } else {
      WidgetsBinding.instance.removeObserver(this);
      _controller.text = widget.finishEditing(_controller.text);
    }
  }

  @override
  void didChangeMetrics() => _revealAfterLayout();

  /// The keyboard can resize both the page and PlutoGrid's scroll viewport.
  /// Reveal the cell after those scrollables finish laying out at the new size.
  void _revealAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focus.hasFocus) {
        unawaited(
          Scrollable.ensureVisible(
            context,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Semantics(
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
          onKeyEvent: (_, _) => KeyEventResult.skipRemainingHandlers,
          child: DefaultTextEditingShortcuts(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
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
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
