import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../../foundation/external_links.dart';
import '../../l10n/app_copy.dart';
import '../theme/layout/app_layout.dart';
import '../theme/tokens/app_radius.dart';
import '../theme/tokens/app_spacing.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Presents the help markdown in a draggable, scrollable bottom sheet.
Future<void> showHelpInstructionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    enableDrag: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return AppLayoutBuilder(
            builder: (context, layout) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: layout.helpInstructionsMaxWidth,
                  ),
                  child: HelpInstructionsSheet(
                    scrollController: scrollController,
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

/// Bottom-sheet shell that hosts the scrollable help content.
class HelpInstructionsSheet extends StatelessWidget {
  /// Creates the instructions sheet using the scroll controller supplied by its
  /// parent.
  const HelpInstructionsSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(context.l10n.help, style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: context.l10n.close,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: HelpInstructions(scrollController: scrollController)),
      ],
    );
  }
}

/// Markdown renderer for bundled help instructions.
class HelpInstructions extends StatefulWidget {
  /// Creates the bundled instructions view. An optional [scrollController]
  /// controls its scroll position.
  const HelpInstructions({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<HelpInstructions> createState() => _HelpInstructionsState();
}

class _HelpInstructionsState extends State<HelpInstructions> {
  /// Held in state rather than rebuilt in `build` so the [FutureBuilder] is
  /// not restarted on every rebuild. `rootBundle` caches the decoded string,
  /// so re-opening help does not re-read the asset.
  late final Future<String> _instructions;

  @override
  void initState() {
    super.initState();
    _instructions = rootBundle.loadString('assets/help_instructions.md');
  }

  ScrollController? get scrollController => widget.scrollController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _instructions,
      builder: _buildSnapshot,
    );
  }

  Widget _buildSnapshot(BuildContext context, AsyncSnapshot<String> snapshot) {
    if (snapshot.hasData) {
      return _buildMarkdown(snapshot.data!);
    }
    if (snapshot.hasError) {
      return Center(child: Text(context.l10n.errorLoadingMarkdown));
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildMarkdown(String data) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxxxl,
      ),
      child: Markdown(
        data: data,
        selectable: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onTapLink: _openLink,
        styleSheet: _markdownStyleSheet(),
        imageBuilder: _buildMarkdownImage,
      ),
    );
  }

  MarkdownStyleSheet _markdownStyleSheet() {
    return MarkdownStyleSheet(
      a: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }

  // Bundled instructions must not trigger a third-party image request.
  Widget _buildMarkdownImage(Uri uri, String? title, String? alt) =>
      Text(alt ?? title ?? '');

  Future<void> _openLink(String text, String? url, String? title) async {
    if (url != null) {
      try {
        if (await context.read<ExternalLinks>().open(Uri.parse(url))) {
          return;
        }
      } on Exception {
        // Platform/link failures are reported below while the sheet is mounted.
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.unableToOpenThisLink)),
        );
      }
    }
  }
}
