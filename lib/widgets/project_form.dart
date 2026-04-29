import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shooters_precision_toolkit/widgets/anomr_matrix.dart';
import 'package:shooters_precision_toolkit/widgets/form_text_input.dart';
import 'package:provider/provider.dart';

import '../model/project_form_model.dart';

class ProjectForm extends StatefulWidget {
  final ProjectFormModel formModel;

  const ProjectForm({super.key, required this.formModel});

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();

  final projectTitleController = TextEditingController();
  final roundsPerConfigController = TextEditingController();
  final configurationsController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    projectTitleController.dispose();
    super.dispose();
  }

  void _onSubmitClicked() {
    widget.formModel.setProjectTitle(projectTitleController.text);

    final projectFormModel = widget.formModel;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: projectFormModel,
          child: AnomrMatrix(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Center(child: Text("New Project Form")),

          // Project Title Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: buildTextInputDecoration(
                labelText: 'Project Title',
                prefixIcon: Icon(Icons.title),
                controller: projectTitleController,
              ),
              controller: projectTitleController,
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Enter up to three configurations and categories for each.",
              ),
            ),
          ),

          // Configuration 1
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: buildTextInputDecoration(
                labelText: 'Configuration 1 Name',
                hintText: "Primer Type",
                prefixIcon: Icon(Icons.circle),
                // controller: ,
              ),
              // controller: projectTitleController,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: buildTextInputDecoration(
                labelText: 'Categories (comma-separated)',
                hintText: "standard,magnum,match",
                prefixIcon: Icon(Icons.add_box),
                // controller: ,
              ),
              // controller: projectTitleController,
            ),
          ),

          // Rounds per configuration input
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Enter number of rounds (shots fired) per configuration.",
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: buildTextInputDecoration(
                labelText: "Rounds per Configuration",
                hintText: "e.g. 5",
                prefixIcon: Icon(Icons.numbers),
                controller: roundsPerConfigController,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              controller: roundsPerConfigController,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  // If the form is valid, display a snackbar. In the real world,
                  // you'd often call a server or save the information in a database.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Processing Data')),
                  );
                }

                _onSubmitClicked();
              },

              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
