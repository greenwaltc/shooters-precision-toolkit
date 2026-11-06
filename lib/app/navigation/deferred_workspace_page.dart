import 'package:flutter/material.dart';

import '../../shared/l10n/app_copy.dart';

/// Loads the code for a workspace page when the user opens its route.
class DeferredWorkspacePage extends StatefulWidget {
  /// Runs [load] before calling [builder]. The user can retry a failed load.
  const DeferredWorkspacePage({
    super.key,
    required this.load,
    required this.builder,
  });

  final Future<void> Function() load;
  final WidgetBuilder builder;

  @override
  State<DeferredWorkspacePage> createState() => _DeferredWorkspacePageState();
}

class _DeferredWorkspacePageState extends State<DeferredWorkspacePage> {
  late Future<void> _load = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _load,
    builder: (context, snapshot) {
      final finished = snapshot.connectionState == ConnectionState.done;
      if (finished && !snapshot.hasError) {
        return widget.builder(context);
      }
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: finished && snapshot.hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.unableToCompleteThatActionPleaseTryAgain,
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () {
                        final load = widget.load();
                        setState(() {
                          _load = load;
                        });
                      },
                      child: Text(context.l10n.retry),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
