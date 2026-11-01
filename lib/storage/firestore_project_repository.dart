import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/saved_project.dart';
import 'project_repository.dart';

export 'project_repository.dart';

class FirestoreProjectRepository implements ProjectRepository {
  FirestoreProjectRepository({required this.db, required this.uid});
  final FirebaseFirestore db;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _projects =>
      db.collection('users').doc(uid).collection('projects');

  @override
  String newProjectId() => _projects.doc().id;

  static const pageSize = 25;

  Query<Map<String, dynamic>> get _recentQuery =>
      _projects.orderBy('updatedAt', descending: true);

  @override
  Stream<List<CloudProject>> watchProjects() => _recentQuery
      .limit(pageSize)
      .snapshots(includeMetadataChanges: true)
      .map((query) => query.docs.map(_decode).toList());

  Future<List<CloudProject>> fetchOlderProjects({
    required DocumentSnapshot<Map<String, dynamic>> after,
  }) async {
    final page = await _recentQuery
        .startAfterDocument(after)
        .limit(pageSize)
        .get();
    return page.docs.map(_decode).toList();
  }

  @override
  Stream<CloudProject?> watchProject(String id) => _projects
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .map((doc) => doc.exists ? _decode(doc) : null);

  CloudProject _decode(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null ||
        data['schemaVersion'] != 1 ||
        data['revision'] is! int ||
        data['createdAt'] is! Timestamp) {
      throw FormatException('Unsupported project ${doc.id}');
    }
    final created = (data['createdAt'] as Timestamp).toDate().toUtc();
    final updated =
        (data['updatedAt'] as Timestamp?)?.toDate().toUtc() ??
        created; // Pending server timestamps can be null.
    final json = Map<String, dynamic>.from(data)
      ..remove('schemaVersion')
      ..remove('revision')
      ..['id'] = doc.id
      ..['createdAt'] = created.toIso8601String()
      ..['updatedAt'] = updated.toIso8601String();
    return CloudProject(
      SavedProject.fromJson(json),
      data['revision'] as int,
      doc.metadata.hasPendingWrites,
      snapshot: doc,
    );
  }

  Map<String, dynamic> _encode(Map<String, dynamic> snapshot, int revision) {
    final data = Map<String, dynamic>.from(snapshot)
      ..remove('id')
      ..['createdAt'] = Timestamp.fromDate(
        DateTime.parse(snapshot['createdAt'] as String),
      )
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['schemaVersion'] = 1
      ..['revision'] = revision;
    return data;
  }

  @override
  Future<int> saveProject(
    SavedProject project, {
    required int expectedRevision,
  }) async {
    // Freeze mutable form/matrix data before an async transaction can retry.
    final snapshot = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(project.toJson())) as Map,
    );
    final ref = _projects.doc(project.id);
    return db.runTransaction<int>((transaction) async {
      final current = await transaction.get(ref);
      final actualRevision = current.exists
          ? current.data()!['revision'] as int
          : 0;
      if (actualRevision != expectedRevision) {
        throw ProjectConflict(project.id);
      }
      final data = _encode(snapshot, actualRevision + 1);
      if (current.exists) {
        data['createdAt'] = current.data()!['createdAt'];
      }
      transaction.set(ref, data);
      return actualRevision + 1;
    });
  }

  @override
  Future<void> deleteProject(String id, {required int expectedRevision}) =>
      db.runTransaction<void>((tx) async {
        final ref = _projects.doc(id);
        final current = await tx.get(ref);
        if (!current.exists) return;
        if (current.data()!['revision'] != expectedRevision) {
          throw ProjectConflict(id);
        }
        tx.delete(ref);
      });

  Future<bool> importLegacyProject(
    SavedProject project,
    String migrationKey,
  ) async {
    final targetId = 'legacy_$migrationKey';
    final marker = db
        .collection('users')
        .doc(uid)
        .collection('imports')
        .doc(migrationKey);
    final target = _projects.doc(targetId);
    final snapshot = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(project.toJson())) as Map,
    );
    return db.runTransaction<bool>((tx) async {
      final imported = await tx.get(marker);
      if (imported.exists) return false;
      final existing = await tx.get(target);
      if (existing.exists) {
        throw StateError(
          'Migration target already exists without its receipt.',
        );
      }
      tx.set(target, _encode(snapshot, 1));
      tx.set(marker, {
        'schemaVersion': 1,
        'projectId': targetId,
        'completedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }
}
