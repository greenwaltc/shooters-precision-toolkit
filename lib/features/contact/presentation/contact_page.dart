import 'package:flutter/material.dart';

import '../../../shared/l10n/app_copy.dart';
import '../../../shared/ui/app_bar_actions.dart';
import '../../../shared/ui/app_brand_bar.dart';
import '../../../shared/ui/app_copyright_footer.dart';
import '../../../shared/ui/theme/layout/app_layout.dart';
import '../../../shared/ui/theme/tokens/app_spacing.dart';

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
        label: context.l10n.contact,
        titleMaxWidth: metrics.titleMaxWidth,
      );
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: titleMetrics.toolbarHeight,
          title: AppBrandTitle(
            label: context.l10n.contact,
            metrics: titleMetrics,
          ),
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
                    context.l10n.contactDentonBramwell,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(context.l10n.aContactFormForQuestionsAndFeedbackWill),
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
