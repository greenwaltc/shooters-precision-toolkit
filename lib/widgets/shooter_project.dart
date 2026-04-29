import 'package:flutter/material.dart';
import 'package:shooters_precision_toolkit/widgets/project_form.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';

class ShooterProject extends StatefulWidget {
  const ShooterProject({super.key});

  @override
  State<ShooterProject> createState() => _ShooterProjectState();
}

class _ShooterProjectState extends State<ShooterProject> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProjectFormModel(),
        builder: (context, child) {
          return Consumer<ProjectFormModel>(
            builder: (context, formModel, child) {
              return ProjectForm(formModel: formModel,);
            }
          );
        }
    );
  }
}
