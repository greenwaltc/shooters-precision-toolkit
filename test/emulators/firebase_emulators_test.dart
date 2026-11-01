@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:bramwells_precision_test_kit/auth/auth_page.dart';
import 'package:bramwells_precision_test_kit/auth/auth_service.dart';
import 'package:bramwells_precision_test_kit/firebase/firebase_bootstrap.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/model/saved_project.dart';
import 'package:bramwells_precision_test_kit/storage/firestore_project_repository.dart';
import 'package:bramwells_precision_test_kit/widgets/project_form_page.dart';
import 'package:bramwells_precision_test_kit/widgets/project_home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

void main() {
  // Browser widget tests don't run the application's generated plugin registrant.
  final registrar = Registrar();
  FirebaseCoreWeb.registerWith(registrar);
  FirebaseAuthWeb.registerWith(registrar);
  FirebaseFirestoreWeb.registerWith(registrar);

  late FirebaseServices emulatorServices;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    // Fail before any account operation if this was invoked with cloud settings.
    expect(useEmulators, isTrue, reason: 'Run through task emulators:test.');
    emulatorServices = await bootstrapFirebase().timeout(
      const Duration(seconds: 30),
    );
    expect(emulatorServices.app.options.projectId, localFirebaseProjectId);
  });

  setUp(rootBundle.clear);

  testWidgets('Flutter boots with local Auth and Firestore services', (
    tester,
  ) async {
    const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    expect(useEmulators, isTrue, reason: 'Run through task emulators:test.');
    SharedPreferences.setMockInitialValues({});

    final services = await tester.runAsync(() async {
      final services = emulatorServices;
      // ignore: avoid_print
      print('Firebase initialized for the local demo project.');
      expect(services.app.options.projectId, localFirebaseProjectId);
      final email =
          'smoke-${DateTime.now().microsecondsSinceEpoch}@example.test';
      final credential = await services.auth
          .createUserWithEmailAndPassword(
            email: email,
            password: 'Local-test-password-123!',
          )
          .timeout(const Duration(seconds: 15));
      // ignore: avoid_print
      print('Auth emulator accepted the test account.');
      try {
        final token = await credential.user!.getIdToken();
        final claims =
            jsonDecode(
                  utf8.decode(
                    base64Url.decode(base64Url.normalize(token!.split('.')[1])),
                  ),
                )
                as Map<String, dynamic>;
        expect(claims['aud'], localFirebaseProjectId);

        // The checked-in bootstrap policy denies client access until migration
        // rules are implemented. A server rejection proves emulator connectivity.
        final document = services.db.doc('emulatorSmoke/connection');
        final permissionDenied = isA<FirebaseException>().having(
          (error) => error.code,
          'code',
          'permission-denied',
        );
        await expectLater(
          document.set({'smoke': true}).timeout(const Duration(seconds: 15)),
          throwsA(permissionDenied),
        );
        await expectLater(
          document
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 15)),
          throwsA(permissionDenied),
        );
      } finally {
        await credential.user!.delete();
        await services.auth.signOut();
      }
      return services;
    });

    if (services == null) return; // runAsync already reports the failure.
    await tester.pumpWidget(FirebaseApplication(services: services));
    // Firebase's initial JS auth callback needs a real browser event turn;
    // pumpAndSettle only advances the widget test's fake clock.
    await tester.runAsync(() async {
      final user = await services.auth.userChanges().first.timeout(
        const Duration(seconds: 5),
      );
      expect(user, isNull);
    });
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(ProjectHomePage), findsNothing);
    expect(find.textContaining('Unable to start the app'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets(
    'emulator verification opens workspace; logout removes private routes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        // ignore: avoid_print
        print('Browser workspace error: ${details.exceptionAsString()}');
        previousErrorHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousErrorHandler);
      final services = emulatorServices;
      final auth = AuthService(services.auth);
      final email =
          'gate-${DateTime.now().microsecondsSinceEpoch}@example.test';
      const password = 'Local-test-password-123!';
      String? createdProjectId;
      try {
        await tester.runAsync(
          () => auth
              .register(email, password)
              .timeout(const Duration(seconds: 15)),
        );
        expect(services.auth.currentUser!.emailVerified, isFalse);
        await tester.pumpWidget(FirebaseApplication(services: services));
        await _waitForAuth(tester, services, signedIn: true);
        expect(find.text('Verify your email'), findsOneWidget);
        expect(find.byType(ProjectHomePage), findsNothing);

        await tester.runAsync(() async {
          // Read only this uniquely named test account's local verification code.
          final response = await web.window
              .fetch(
                'http://127.0.0.1:9099/emulator/v1/projects/$localFirebaseProjectId/oobCodes'
                    .toJS,
              )
              .toDart
              .timeout(const Duration(seconds: 5));
          expect(response.ok, isTrue);
          final data = (await response.json().toDart).dartify() as Map;
          final codes = (data['oobCodes'] as List).cast<Map>().where(
            (code) =>
                code['email'] == email && code['requestType'] == 'VERIFY_EMAIL',
          );
          expect(codes, isNotEmpty);
          await services.auth.applyActionCode(codes.last['oobCode'] as String);
          // Simulate returning from the external verification page: refresh the
          // profile without calling the verification screen's refresh helper.
          // AuthGate must refresh token claims before mounting the workspace.
          await services.auth.currentUser!.reload();
        });
        await _waitForAuth(tester, services, signedIn: true);
        await tester.runAsync(() async {
          final token = await services.auth.currentUser!.getIdTokenResult();
          expect(token.claims?['email_verified'], isTrue);
        });
        expect(find.byType(ProjectHomePage), findsOneWidget);
        expect(find.byType(AuthPage), findsNothing);

        final create = find.widgetWithIcon(FilledButton, Icons.add);
        await tester.ensureVisible(create);
        // This browser widget runner does not bundle Material's InkSparkle
        // shader. Exercise real callbacks here; pointer/menu behavior is
        // covered by the regular workspace widget tests.
        final store = tester.element(create).read<ProjectStore>();
        tester.widget<FilledButton>(create).onPressed!();
        createdProjectId = store.selectedProject?.id;
        await _pumpUntil(
          tester,
          () =>
              store.selectedProject != null &&
              store.saveStateFor(store.selectedProject!.id) ==
                  ProjectSaveState.saved,
          'project creation was not acknowledged by Firestore',
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProjectFormPage), findsOneWidget);
        final oldNavigator = Navigator.of(
          tester.element(find.byType(ProjectFormPage)),
        );
        await tester.enterText(
          find.byType(TextFormField).first,
          'Emulator private draft',
        );
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.logout))
            .onPressed!();
        await tester.pump();
        await _waitForAuth(tester, services, signedIn: false);
        expect(oldNavigator.mounted, isFalse);
        expect(find.byType(AuthPage), findsOneWidget);
        expect(find.byType(ProjectFormPage), findsNothing);
        expect(find.byType(ProjectHomePage), findsNothing);
        expect(find.byType(AlertDialog), findsNothing);
        final loginNavigator = tester.state<NavigatorState>(
          find.byType(Navigator),
        );
        expect(loginNavigator.canPop(), isFalse);
        await loginNavigator.maybePop();
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          // Never flush the emulator globally: interactive users may be testing too.
          try {
            await auth.signIn(email, password);
            if (createdProjectId != null) {
              await services.db
                  .collection('users')
                  .doc(services.auth.currentUser!.uid)
                  .collection('projects')
                  .doc(createdProjectId)
                  .delete();
            }
            await services.auth.currentUser!.delete();
          } on FirebaseException catch (error) {
            if (![
              'user-not-found',
              'invalid-credential',
            ].contains(error.code)) {
              rethrow;
            }
          } finally {
            await services.auth.signOut();
          }
        });
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
  test(
    'store preserves newer edits across real Firestore acknowledgements and conflicts',
    () async {
      final services = emulatorServices;
      final auth = AuthService(services.auth);
      final email =
          'save-state-${DateTime.now().microsecondsSinceEpoch}@example.test';
      ProjectStore? store;
      String? id;
      String? copyId;
      try {
        await auth.register(email, 'Local-test-password-123!');
        final response = await web.window
            .fetch(
              'http://127.0.0.1:9099/emulator/v1/projects/$localFirebaseProjectId/oobCodes'
                  .toJS,
            )
            .toDart;
        expect(response.ok, isTrue);
        final data = (await response.json().toDart).dartify() as Map;
        final code = (data['oobCodes'] as List).cast<Map>().lastWhere(
          (code) =>
              code['email'] == email && code['requestType'] == 'VERIFY_EMAIL',
        );
        await services.auth.applyActionCode(code['oobCode'] as String);
        expect(await auth.refreshVerification(), isTrue);
        final repository = FirestoreProjectRepository(
          db: services.db,
          uid: services.auth.currentUser!.uid,
        );
        final delayed = _DelayedAcknowledgementRepository(repository);
        final workspace = ProjectStore(
          repository: delayed,
          saveDebounce: const Duration(seconds: 2),
        );
        store = workspace;
        expect(workspace.loadState, WorkspaceLoadState.loading);
        await workspace.load();
        expect(workspace.loadError, isNull);
        expect(workspace.loadState, WorkspaceLoadState.empty);
        final project = await workspace.createProject();
        id = project.id;
        expect(workspace.loadState, WorkspaceLoadState.ready);
        project.formModel.setProjectTitle('Submitted snapshot');
        final editCounter = workspace.editStateFor(project.id)!.editCounter;
        final release = Completer<void>();
        final committed = Completer<int>();
        delayed.holdNextAcknowledgement = release.future;
        delayed.nextCommitted = committed;
        final saving = workspace.saveSelectedProject();
        expect(await committed.future, 2);
        // The server has committed revision 2, but the store has not received its
        // acknowledgement yet. A second edit must survive that acknowledgement.
        expect(workspace.editStateFor(project.id)!.isSaving, isTrue);
        project.formModel.setProjectTitle('Newer unsaved edit');
        expect(
          workspace.editStateFor(project.id)!.editCounter,
          greaterThan(editCounter),
        );
        release.complete();
        await saving;
        expect(workspace.revisionFor(project.id), 2);
        expect(workspace.editStateFor(project.id)!.isDirty, isTrue);
        await _waitForStore(
          () =>
              workspace.revisionFor(project.id) == 3 &&
              workspace.saveStateFor(project.id) == ProjectSaveState.saved,
          describe: () =>
              'follow-up: revision=${workspace.revisionFor(project.id)}, state=${workspace.saveStateFor(project.id)}, error=${workspace.saveErrorFor(project.id)}',
        );
        final ref = services.db
            .collection('users')
            .doc(repository.uid)
            .collection('projects')
            .doc(project.id);
        final saved = (await ref.get(
          const GetOptions(source: Source.server),
        )).data()!;
        expect(
          (saved['formModel'] as Map)['projectTitle'],
          'Newer unsaved edit',
        );
        expect(saved['revision'], 3);

        project.formModel.setProjectTitle('Keep this local draft');
        final remote = SavedProject.fromJson(
          jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
        );
        remote.formModel.setProjectTitle('Competing cloud edit');
        await repository.saveProject(remote, expectedRevision: 3);
        await expectLater(
          repository.deleteProject(project.id, expectedRevision: 3),
          throwsA(isA<ProjectConflict>()),
        );
        await expectLater(
          workspace.saveSelectedProject(),
          throwsA(isA<ProjectConflict>()),
        );
        expect(workspace.editStateFor(project.id)!.hasConflict, isTrue);
        expect(workspace.editStateFor(project.id)!.isDirty, isTrue);
        expect(workspace.selectedProject!.displayName, 'Keep this local draft');
        await _waitForStore(() => workspace.canDiscardDraft(project.id));
        workspace.discardConflictingDraft(project.id);
        expect(workspace.selectedProject!.displayName, 'Competing cloud edit');
        expect(workspace.saveStateFor(project.id), ProjectSaveState.saved);
        expect(workspace.revisionFor(project.id), 4);

        // Ordinary edits are durable locally before the two-second upload.
        workspace.selectedProject!.formModel.setProjectTitle(
          'Debounced cloud edit',
        );
        await workspace.persistSelectedProject();
        final draft = (await workspace.draftStorage.readAll())[project.id]!;
        expect(draft.project.displayName, 'Debounced cloud edit');
        expect(draft.expectedRevision, 4);
        final beforeUpload = (await ref.get(
          const GetOptions(source: Source.server),
        )).data()!;
        expect(beforeUpload['revision'], 4);
        await _waitForStore(
          () =>
              workspace.revisionFor(project.id) == 5 &&
              workspace.saveStateFor(project.id) == ProjectSaveState.saved,
          describe: () =>
              'autosave: revision=${workspace.revisionFor(project.id)}, state=${workspace.saveStateFor(project.id)}, error=${workspace.saveErrorFor(project.id)}',
        );
        final afterUpload = (await ref.get(
          const GetOptions(source: Source.server),
        )).data()!;
        expect(
          (afterUpload['formModel'] as Map)['projectTitle'],
          'Debounced cloud edit',
        );
        expect(await workspace.draftStorage.readAll(), isEmpty);
        final local = workspace.selectedProject!;
        local.formModel.setProjectTitle('Recover as separate project');
        final competing = SavedProject.fromJson(
          jsonDecode(jsonEncode(local.toJson())) as Map<String, dynamic>,
        );
        competing.formModel.setProjectTitle('Other tab owns revision six');
        await repository.saveProject(competing, expectedRevision: 5);
        await _waitForStore(
          () => workspace.saveStateFor(project.id) == ProjectSaveState.conflict,
        );
        final copy = await workspace.saveConflictAsNewProject(project.id);
        copyId = copy.id;
        expect(copy.id, isNot(project.id));
        expect(workspace.revisionFor(copy.id), 1);
        expect(copy.displayName, 'Recover as separate project');
        final originalAfterCopy = (await ref.get(
          const GetOptions(source: Source.server),
        )).data()!;
        expect(originalAfterCopy['revision'], 6);
        expect(
          (originalAfterCopy['formModel'] as Map)['projectTitle'],
          'Other tab owns revision six',
        );
      } finally {
        store?.dispose();
        final user = services.auth.currentUser;
        if (user != null) {
          if (copyId != null) {
            await services.db
                .collection('users')
                .doc(user.uid)
                .collection('projects')
                .doc(copyId)
                .delete();
          }
          if (id != null) {
            await services.db
                .collection('users')
                .doc(user.uid)
                .collection('projects')
                .doc(id)
                .delete();
          }
          await user.delete();
        }
        await services.auth.signOut();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _waitForStore(
  bool Function() ready, {
  String Function()? describe,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(
    ready(),
    isTrue,
    reason: describe?.call() ?? 'store did not reach the expected save state',
  );
}

/// Writes go to the real emulator. Only delivery of one acknowledgement is held
/// to reproduce a user editing while an earlier save is still in flight.
class _DelayedAcknowledgementRepository implements ProjectRepository {
  _DelayedAcknowledgementRepository(this.delegate);
  final ProjectRepository delegate;
  Future<void>? holdNextAcknowledgement;
  Completer<int>? nextCommitted;

  @override
  String newProjectId() => delegate.newProjectId();
  @override
  Stream<List<CloudProject>> watchProjects() => delegate.watchProjects();
  @override
  Future<List<CloudProject>> fetchOlderProjects({
    required CloudProject after,
  }) => delegate.fetchOlderProjects(after: after);
  @override
  Stream<CloudProject?> watchProject(String id) => delegate.watchProject(id);
  @override
  Future<void> deleteProject(String id, {required int expectedRevision}) =>
      delegate.deleteProject(id, expectedRevision: expectedRevision);
  @override
  Future<int> saveProject(
    SavedProject project, {
    required int expectedRevision,
  }) async {
    final hold = holdNextAcknowledgement;
    final committed = nextCommitted;
    holdNextAcknowledgement = null;
    nextCommitted = null;
    final revision = await delegate.saveProject(
      project,
      expectedRevision: expectedRevision,
    );
    committed?.complete(revision);
    await hold;
    return revision;
  }
}

Future<void> _waitForAuth(
  WidgetTester tester,
  FirebaseServices services, {
  required bool signedIn,
}) async {
  await _pumpUntil(tester, () {
    final user = services.auth.currentUser;
    if ((user != null) != signedIn) return false;
    if (signedIn && user!.emailVerified) {
      return find.byType(ProjectHomePage).evaluate().isNotEmpty;
    }
    final pages = find.byType(AuthPage).evaluate();
    return pages.isNotEmpty &&
        (pages.single.widget as AuthPage).verification == signedIn;
  }, 'authentication screen did not follow the session state');
  await tester.pump();
  if (signedIn && services.auth.currentUser!.emailVerified) {
    final home = find.byType(ProjectHomePage);
    if (home.evaluate().isNotEmpty) {
      final store = tester.element(home).read<ProjectStore>();
      await _pumpUntil(
        tester,
        () => store.isLoaded || store.loadError != null,
        'workspace did not receive its initial Firestore snapshot',
      );
      expect(store.loadError, isNull);
    }
  }
  await tester.pumpAndSettle();
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() ready,
  String failure,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    // Deliver browser network callbacks, then advance the widget-test zone.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(ready(), isTrue, reason: failure);
}
