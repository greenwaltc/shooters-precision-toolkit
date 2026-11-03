import '../firebase/firebase_bootstrap.dart' show localFirebaseProjectId;

/// Runtime return URLs follow the initialized Firebase project, including local
/// emulators. Search metadata retains the separate production canonical origin.
String siteUrlForFirebaseProject(String projectId) => switch (projectId) {
  localFirebaseProjectId => 'http://127.0.0.1:7357',
  'bramwellsprecisiontestkitdev' => 'https://dev.bramwelltest.com',
  'bramwells-precision-test-kit' => 'https://bramwelltest.com',
  _ => throw StateError('Unknown Firebase project.'),
};
