import '../../../shared/foundation/behavior_policy.dart';
import '../../../shared/foundation/file_loader.dart';
import '../../../shared/foundation/file_saver.dart';
import '../api/project_snapshot.dart';
import '../domain/project_file_codec.dart';

/// Coordinates file picking, validation, and saving for portable projects.
final class ProjectFileTransfer {
  /// Uses the supplied platform adapters for user-mediated file access.
  const ProjectFileTransfer({required this.loader, required this.saver});

  final FileLoader loader;
  final FileSaver saver;

  /// Prompts for a project file and validates it before returning a snapshot.
  ///
  /// Returns null on cancellation. Read and validation failures propagate to
  /// the caller so it can give the user a useful next step.
  Future<ProjectSnapshot?> pickProject(String title) async {
    final bytes = await loader.load(
      title: title,
      extension: ProjectFileCodec.extension,
      maxBytes: BehaviorPolicy.maxProjectFileBytes,
    );
    return bytes == null ? null : ProjectFileCodec.decode(bytes);
  }

  /// Offers the current project state for saving under a safe file name.
  ///
  /// Returns the platform's result or null on cancellation. Export and save
  /// failures propagate to the caller.
  Future<String?> exportProject(ProjectDocument project, String title) {
    final snapshot = project.freeze();
    final slug = snapshot.displayName.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-');
    final name = slug.split('-').where((part) => part.isNotEmpty).join('-');
    return saver.save(
      title: title,
      name:
          '${name.isEmpty ? 'project' : 'project-$name'}.${ProjectFileCodec.extension}',
      bytes: ProjectFileCodec.encode(snapshot),
      extension: ProjectFileCodec.extension,
    );
  }
}
