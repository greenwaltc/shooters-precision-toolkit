import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';

class AnomrMatrix extends StatelessWidget {
  const AnomrMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    final formModel = context.read<ProjectFormModel>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
        
            Center(
              child: Text(formModel.projectTitle),
            ),
        
            // PlutoGrid(columns: columns, rows: rows)
        
          ],
        ),
      )
    );
  }
}
