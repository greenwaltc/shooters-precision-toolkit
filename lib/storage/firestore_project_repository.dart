import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/saved_project.dart';
import '../util/json_object.dart';
import 'project_repository.dart';

export 'project_repository.dart'
    show CloudProject, ProjectConflict, ProjectRepository;

class FirestoreProjectRepository implements ProjectRepository {
  FirestoreProjectRepository({required this.db, required this.uid});
  final FirebaseFirestore db;
  final String uid;

  // Firestore SDK maps are a dynamic interop boundary. _decode validates data
  // before exposing Object?-typed JSON to domain models.
  CollectionReference<Map<String, dynamic>> get _projects =>
      db.collection('users').doc(uid).collection('projects');

  @override
  String newProjectId() => _projects.doc().id;

  static const pageSize = ProjectRepository.pageSize;

  Query<Map<String, dynamic>> get _recentQuery =>
      _projects.orderBy('updatedAt', descending: true);

  @override
  Stream<List<CloudProject>> watchProjects() => _recentQuery
      .limit(pageSize)
      .snapshots(includeMetadataChanges: true)
      .map((query) => query.docs.map(_decode).toList());

  @override
  Future<List<CloudProject>> fetchOlderProjects({
    required CloudProject after,
  }) async {
    final cursor = after.snapshot;
    if (cursor == null) {
      throw StateError('A Firestore cursor is required.');
    }
    final page = await _recentQuery
        .startAfterDocument(cursor)
        .limit(pageSize)
        .get(const GetOptions(source: Source.server));
    return page.docs.map(_decode).toList();
  }

  @override
  Stream<CloudProject?> watchProject(String id) => _projects
      .doc(id)
      .snapshots(includeMetadataChanges: true)
      .map((doc) => doc.exists ? _decode(doc) : null);

  CloudProject _decode(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final revision = data?['revision'];
    final createdAt = data?['createdAt'];
    final updatedAt = data?['updatedAt'];
    if (data == null ||
        data['schemaVersion'] != 1 ||
        revision is! int ||
        revision < 1 ||
        createdAt is! Timestamp ||
        (updatedAt != null && updatedAt is! Timestamp)) {
      throw FormatException('Unsupported project ${doc.id}');
    }
    final created = createdAt.toDate().toUtc();
    // Pending server timestamps can be null until Firestore acknowledges a write.
    final updated = updatedAt is Timestamp
        ? updatedAt.toDate().toUtc()
        : created;
    final json = Map<String, Object?>.from(data)
      ..remove('schemaVersion')
      ..remove('revision')
      ..['id'] = doc.id
      ..['createdAt'] = created.toIso8601String()
      ..['updatedAt'] = updated.toIso8601String();
    return CloudProject(
      SavedProject.fromJson(json),
      revision,
      doc.metadata.hasPendingWrites,
      snapshot: doc,
    );
  }

  Map<String, Object?> _encode(Map<String, Object?> snapshot, int revision) {
    final data = Map<String, Object?>.from(snapshot)
      ..remove('id')
      ..['createdAt'] = Timestamp.fromDate(
        DateTime.parse(
          optionalJsonValue<String>(snapshot, 'createdAt') ??
              (throw const FormatException('Missing project creation date.')),
        ),
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
    final snapshot = decodeJsonObject(jsonEncode(project.toJson()));
    final ref = _projects.doc(project.id);
    final revision = await db.runTransaction<int?>((transaction) async {
      final current = await transaction.get(ref);
      final currentData = current.data();
      final actualRevision = current.exists ? _revision(currentData) : 0;
      if (actualRevision != expectedRevision) {
        // Return the conflict through the SDK boundary. On web, throwing a Dart
        // domain exception inside a JS transaction wraps it as a NativeError.
        return null;
      }
      final data = _encode(snapshot, actualRevision + 1);
      if (current.exists) {
        data['createdAt'] = currentData?['createdAt'];
      }
      transaction.set(ref, data);
      return actualRevision + 1;
    });
    if (revision == null) {
      throw ProjectConflict(project.id);
    }
    return revision;
  }

  @override
  Future<void> deleteProject(String id, {required int expectedRevision}) async {
    final deleted = await db.runTransaction<bool>((tx) async {
      final ref = _projects.doc(id);
      final current = await tx.get(ref);
      if (!current.exists) {
        return true;
      }
      if (_revision(current.data()) != expectedRevision) {
        return false;
      }
      tx.delete(ref);
      return true;
    });
    if (!deleted) {
      throw ProjectConflict(id);
    }
  }

  int _revision(Map<String, Object?>? data) {
    final revision = data?['revision'];
    if (revision is! int || revision < 1) {
      throw const FormatException('Invalid cloud project revision.');
    }
    return revision;
  }
}
