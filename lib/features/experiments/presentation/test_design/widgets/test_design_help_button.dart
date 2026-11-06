// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../../shared/l10n/app_copy.dart';

/// Bundled help topics for the settings on the Test Design form.
enum TestDesignHelpTopic {
  projectName('project_name'),
  structure('experiment_structure'),
  factorStates('factor_states'),
  risk('risk_level'),
  sampleSize('sample_size'),
  missingData('missing_data');

  const TestDesignHelpTopic(this._fileName);

  final String _fileName;

  /// The path to the English Markdown body in the app bundle.
  String get assetPath => 'assets/help/test_design/en/$_fileName.md';
}

/// A help icon that opens a scrollable modal for one Test Design setting.
class TestDesignHelpButton extends StatelessWidget {
  /// Uses [section] for the tooltip and dialog title and loads [topic] on tap.
  const TestDesignHelpButton({
    super.key,
    required this.section,
    required this.topic,
  });

  final String section;
  final TestDesignHelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.sectionHelp(section),
      icon: const Icon(Icons.help_outline),
      onPressed: () => _showHelp(context),
    );
  }

  Future<void> _showHelp(BuildContext context) async {
    final content = DefaultAssetBundle.of(context).loadString(topic.assetPath);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(section),
        scrollable: true,
        content: FutureBuilder<String>(
          future: content,
          builder: (context, snapshot) {
            if (snapshot.data case final markdown?) {
              return MarkdownBody(data: markdown);
            }
            if (snapshot.hasError) {
              return Text(context.l10n.sectionHelpLoadError);
            }
            return Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.l10n.loadingSectionHelp,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }
}
