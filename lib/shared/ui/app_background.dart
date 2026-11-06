import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_copy.dart';
import 'app_atmosphere.dart';
import 'emulator_presentation.dart';
import 'theme/layout/app_viewport.dart';
import 'theme/tokens/app_spacing.dart';

/// Shared photographic background and viewport treatment for app and auth.
class AppBackground extends StatelessWidget {
  /// Displays [child] over the shared app background.
  const AppBackground({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final viewport = AppViewport.withSupportedTextScale(MediaQuery.of(context));
    final content = child ?? const SizedBox.shrink();
    final emulator = kIsWeb && context.watch<EmulatorPresentation>().enabled;
    final scheme = Theme.of(context).colorScheme;
    return MediaQuery(
      data: viewport,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: scheme.surface),
          const AppAtmosphere(),
          if (emulator)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: MediaQuery(
                    data: viewport.removePadding(removeBottom: true),
                    child: content,
                  ),
                ),
                Material(
                  color: scheme.errorContainer,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        context.l10n.emulatorModeWarning,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            content,
        ],
      ),
    );
  }
}
