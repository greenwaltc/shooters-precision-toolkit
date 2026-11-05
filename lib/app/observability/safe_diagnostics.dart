import 'dart:convert';

import '../../shared/foundation/app_failure.dart';
import '../../shared/foundation/diagnostics.dart';
import '../config/app_config.dart';

/// Local structured diagnostics only. Never serializes an exception, URL,
/// user identifier, request body or arbitrary stack text. No offline buffer.
final class SafeDiagnostics implements Diagnostics {
  /// Creates a reporter that sends sanitized events to [write].
  ///
  /// Pass null for [configuration] when startup could not load a valid
  /// configuration.
  SafeDiagnostics({
    required AppConfig? configuration,
    required void Function(String) write,
  }) : _write = write,
       _metadata = Map.unmodifiable({
         'environment': configuration == null
             ? 'invalid'
             : configuration.useEmulators
             ? 'local'
             : configuration.environment.name,
         'configSchema': AppConfig.schemaVersion,
         'version':
             configuration?.build.version ?? BuildIdentity.unknown.version,
         'buildId': configuration?.build.id ?? BuildIdentity.unknown.id,
         'revision':
             configuration?.build.revision ?? BuildIdentity.unknown.revision,
         'flutterSdk':
             configuration?.build.flutterSdk ??
             BuildIdentity.unknown.flutterSdk,
       });

  final void Function(String) _write;
  final Map<String, String> _metadata;
  bool _emitting = false;
  int _sequence = 0;
  static const _maximumFrames = 16;
  static const _maximumStackCharacters = 24000;
  // Only known source-location grammar is retained. Full source URLs, query
  // strings, filenames outside the app, and frame prose are discarded.
  static final _locations = RegExp(
    r'(?:package:|packages/)bramwells_precision_test_kit/([a-z0-9_/]{1,160}\.dart:\d{1,7}(?::\d{1,7})?)|\b(main\.dart\.js:\d{1,7}:\d{1,7})',
  );

  @override
  void record(
    DiagnosticEvent event, {
    Object? error,
    StackTrace? stack,
    Duration? elapsed,
  }) {
    if (_emitting) {
      return;
    }
    _emitting = true;
    try {
      final trace = stack?.toString() ?? '';
      final frames = _locations
          .allMatches(
            trace.substring(0, trace.length.clamp(0, _maximumStackCharacters)),
          )
          .take(_maximumFrames)
          .map((match) => match.group(1) ?? match.group(2)!)
          .toList();
      _write(
        jsonEncode({
          ..._metadata,
          'event': event.name,
          'component': event.component,
          'severity': event.severity,
          'outcome': event.outcome,
          'sequence': ++_sequence,
          if (elapsed != null)
            'elapsedMs': elapsed.inMilliseconds.clamp(0, 3600000),
          if (error != null)
            'failure': error is AppFailure
                ? error.kind.name
                : FailureKind.unknown.name,
          if (frames.isNotEmpty) 'frames': frames,
        }),
      );
    } catch (_) {
      // Reporting cannot fail an application operation or recursively report.
    } finally {
      _emitting = false;
    }
  }
}
