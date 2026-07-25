// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../styles/layout/app_layout.dart';
import '../styles/tokens/app_radius.dart';
import '../styles/tokens/app_spacing.dart';

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
              Text('Help', style: theme.textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
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
  const HelpInstructions({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<HelpInstructions> createState() => _HelpInstructionsState();
}

class _HelpInstructionsState extends State<HelpInstructions> {
  /// Held in state rather than rebuilt in `build` so the [FutureBuilder] is
  /// not restarted on every rebuild. `rootBundle` caches the decoded string,
  /// so re-opening help does not re-read the asset.
  late final Future<String> _instructions = rootBundle.loadString(
    'assets/help_instructions.md',
  );

  ScrollController? get scrollController => widget.scrollController;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _instructions,
      builder: _buildSnapshot,
    );
  }

  Widget _buildSnapshot(BuildContext context, AsyncSnapshot<String> snapshot) {
    if (snapshot.hasData) return _buildMarkdown(snapshot.data!);
    if (snapshot.hasError) {
      return const Center(child: Text('Error loading markdown'));
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
      a: const TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    );
  }

  Widget _buildMarkdownImage(Uri uri, String? title, String? alt) {
    if (uri.path.endsWith('.svg')) {
      return SvgPicture.network(
        uri.path,
        placeholderBuilder: (context) => const CircularProgressIndicator(),
      );
    }

    return Image.network(
      uri.toString(),
      errorBuilder: (context, error, stack) =>
          const Icon(Icons.broken_image, color: Colors.grey),
      loadingBuilder: _buildImageLoadingState,
    );
  }

  Widget _buildImageLoadingState(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: _imageLoadingValue(loadingProgress),
      ),
    );
  }

  double? _imageLoadingValue(ImageChunkEvent loadingProgress) {
    final expectedTotalBytes = loadingProgress.expectedTotalBytes;
    if (expectedTotalBytes == null) return null;
    return loadingProgress.cumulativeBytesLoaded / expectedTotalBytes;
  }

  void _openLink(String text, String? url, String? title) {
    if (url != null) {
      launchUrl(Uri.parse(url));
    }
  }
}
