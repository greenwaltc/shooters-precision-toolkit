import 'package:flutter/material.dart';

class ProjectFormModel extends ChangeNotifier {
  String projectTitle = '';
  // String

  ProjectFormModel();

  void setProjectTitle(String title) {
    projectTitle = title;
    notifyListeners();
  }
}

