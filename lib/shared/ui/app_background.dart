import 'package:flutter/material.dart';

import 'app_atmosphere.dart';
import 'theme/layout/app_viewport.dart';

/// Shared photographic background and viewport treatment for app and auth.
class AppBackground extends StatelessWidget {
  /// Displays [child] over the shared app background.
  const AppBackground({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: AppViewport.withSupportedTextScale(MediaQuery.of(context)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).colorScheme.surface),
        const AppAtmosphere(),
        Padding(
          padding: EdgeInsets.only(
            bottom: AppViewport.emulatorBannerInset(context),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ],
    ),
  );
}
