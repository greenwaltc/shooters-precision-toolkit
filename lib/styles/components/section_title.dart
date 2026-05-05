import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Heading shown above a form section. Standard padding + `titleMedium`
/// styling so all section titles read as siblings.
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.padding = AppSpacing.formSectionTitle,
  });

  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(title, style: AppTextStyles.sectionTitle(context)),
    );
  }
}
