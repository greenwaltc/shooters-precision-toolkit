// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bramwells_precision_test_kit/navigation/app_page_transitions.dart';

/// Regression: covering a page with a modal must not dispose that page.
///
/// The mobile Group Size sheet awaits [showModalBottomSheet] and then writes
/// into matrix state. If the page transition drops the covered route from the
/// tree, that State is disposed and the sheet result is discarded.
void main() {
  testWidgets(
    'modal result still applies on a page using AppPageTransitions',
    (tester) async {
      final saved = ValueNotifier<String?>(null);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            pageTransitionsTheme: buildAppPageTransitionsTheme(),
          ),
          onGenerateRoute: (settings) {
            return AppPageRoute<void>(
              settings: settings,
              builder: (_) => _ModalHost(saved: saved),
            );
          },
          initialRoute: '/',
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1.25');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved.value, '1.25');
      expect(find.text('Saved: 1.25'), findsOneWidget);
    },
  );
}

class _ModalHost extends StatefulWidget {
  const _ModalHost({required this.saved});

  final ValueNotifier<String?> saved;

  @override
  State<_ModalHost> createState() => _ModalHostState();
}

class _ModalHostState extends State<_ModalHost> {
  Future<void> _openSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final controller = TextEditingController();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller),
              TextButton(
                onPressed: () =>
                    Navigator.pop(sheetContext, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    widget.saved.value = result;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextButton(onPressed: _openSheet, child: const Text('Open sheet')),
          Text('Saved: ${widget.saved.value ?? '(none)'}'),
        ],
      ),
    );
  }
}
