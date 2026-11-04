import 'package:flutter/material.dart';

import '../styles/layout/app_layout.dart';
import '../widgets/app_bar_actions.dart';
import '../widgets/app_brand_bar.dart';
import '../widgets/app_copyright_footer.dart';

/// Contact information placeholder until the private contact form is available.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) => AppLayoutBuilder(
    builder: (context, layout) {
      final actions = [
        AppBarActionBar.instructions(context),
        AppBarActionBar.donations(context),
      ];
      final metrics = AppBarActionsMetrics.of(
        context,
        layout: layout,
        items: actions,
        hasLeading: true,
      );
      final titleMetrics = AppBrandTitleMetrics.of(
        context,
        label: 'Contact',
        titleMaxWidth: metrics.titleMaxWidth,
      );
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: titleMetrics.toolbarHeight,
          title: AppBrandTitle(label: 'Contact', metrics: titleMetrics),
          actions: AppBarActionBar.build(
            context,
            layout: layout,
            items: actions,
            hasLeading: true,
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(layout.pageGutter),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Denton Bramwell',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A contact form for questions and feedback will be available here soon.',
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppCopyrightFooter(),
      );
    },
  );
}
