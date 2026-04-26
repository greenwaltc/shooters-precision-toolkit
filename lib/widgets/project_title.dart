import 'package:flutter/material.dart';

class ProjectTitle extends StatefulWidget {
  const ProjectTitle({super.key});

  @override
  State<ProjectTitle> createState() => _ProjectTitleState();
}

class _ProjectTitleState extends State<ProjectTitle> {
  String _title = "Untitled";

  void _editTitle() {
    final TextEditingController controller = TextEditingController(text: _title);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Spreadsheet Title'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter title here",
            ),
            autofocus: true,
          ),
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
                  _title = controller.text.isNotEmpty ? controller.text : "Untitled";
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            _title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: _editTitle,
          ),
        ],
      ),
    );
  }
}
