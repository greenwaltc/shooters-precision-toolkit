import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shooters_precision_toolkit/widgets/spreadsheet_setup_alert_dialog.dart';

class SpreadsheetSetupButton extends StatelessWidget {
  const SpreadsheetSetupButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              showDialog(context: context, builder: (BuildContext context) {
                return SpreadsheetSetupAlertDialog();
              });
            },
            child: const Text('Set Up Variables'),
          ),
        ),
      ],
    );
  }
}
