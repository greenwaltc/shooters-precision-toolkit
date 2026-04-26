import 'package:flutter/material.dart';

import '../util/show_toast.dart';

class SpreadsheetSetupAlertDialog extends StatefulWidget {
  const SpreadsheetSetupAlertDialog({super.key});

  @override
  State<SpreadsheetSetupAlertDialog> createState() =>
      _SpreadsheetSetupAlertDialogState();
}

class _SpreadsheetSetupAlertDialogState
    extends State<SpreadsheetSetupAlertDialog> {
  // Store the data for each row
  final List<Map<String, TextEditingController>> _rows = [];

  void _addNewRow() {
    if (_rows.length >= 3) {
      showToast(context, "Maximum of 3 categorical variables allowed.");
      return;
    }

    setState(() {
      _rows.add({
        'name': TextEditingController(),
        'categories': TextEditingController(),
      });
    });
  }

  void _removeRow(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
              'Warning: If you already have data in the spreadsheet, deleting a variable may result in data loss. Do you wish to proceed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final removedRow = _rows.removeAt(index);
                  removedRow['name']?.dispose();
                  removedRow['categories']?.dispose();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    for (var row in _rows) {
      row['name']?.dispose();
      row['categories']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Spreadsheet Setup'),
      content: SizedBox(
        width: double.maxFinite, // Ensures the dialog can expand horizontally
        child: Form(
          child: SingleChildScrollView(
            // Allows scrolling if many rows are added
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Variables",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                // Map existing rows to UI
                ..._rows.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: row['name'],
                              decoration: const InputDecoration(
                                labelText: 'Variable Name',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: row['categories'],
                              decoration: const InputDecoration(
                                labelText: 'Variable Categories',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeRow(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // The "Plus" button row
                // This row is displayed even when _rows has at least 3 items to allow triggering the toast.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.blue,
                        size: 32,
                      ),
                      onPressed: _addNewRow,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Access data via _rows[index]['name']!.text
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
