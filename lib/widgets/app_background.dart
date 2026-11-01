import 'package:flutter/material.dart';

import '../styles/layout/app_viewport.dart';
import 'app_atmosphere.dart';

/// Shared photographic background and viewport treatment for app and auth.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: AppViewport.applyWebSafeArea(MediaQuery.of(context)),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).colorScheme.surface),
        const AppAtmosphere(),
        child ?? const SizedBox.shrink(),
      ],
    ),
  );
}
