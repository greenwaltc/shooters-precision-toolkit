import 'package:bramwells_precision_test_kit/app/config/app_config.dart';
import 'package:bramwells_precision_test_kit/app/observability/safe_diagnostics.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/app_failure.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/diagnostics.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/json_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports only structured metadata and bounded app frame locations', () {
    final config = AppConfig.fromValues({
      'CONFIG_SCHEMA_VERSION': '1',
      'APP_ENV': 'prod',
      'BUILD_ID': 'abcdef012345-123456789abc',
      'BUILD_VERSION': '1.2.3+4',
      'BUILD_REVISION': 'abcdef0123456789abcdef0123456789abcdef01',
      'BUILD_FLUTTER_SDK': '3.47.9',
    });
    final output = <String>[];
    final diagnostics = SafeDiagnostics(
      configuration: config,
      write: output.add,
    );
    final stack = StackTrace.fromString(
      [
        'https://example.test/private?secret=private-token',
        ...List.generate(
          20,
          (i) =>
              'raw-user@example.test (package:bramwells_precision_test_kit/app/main.dart:${i + 1}:2)',
        ),
      ].join('\n'),
    );

    diagnostics.record(
      DiagnosticEvent.workspaceSaveFailed,
      error: StateError('private-token password raw-user@example.test'),
      stack: stack,
      elapsed: const Duration(milliseconds: 219),
    );

    final entry = decodeJsonObject(output.single);
    expect(entry, {
      'environment': 'prod',
      'configSchema': '1',
      'version': '1.2.3+4',
      'buildId': config.build.id,
      'revision': config.build.revision,
      'flutterSdk': '3.47.9',
      'event': 'workspaceSaveFailed',
      'component': 'workspace',
      'severity': 'warning',
      'outcome': 'failure',
      'sequence': 1,
      'elapsedMs': 219,
      'failure': 'unknown',
      'frames': List.generate(16, (i) => 'app/main.dart:${i + 1}:2'),
    });
  });

  test('writer failure and recursive recording cannot mask later events', () {
    final output = <String>[];
    late final SafeDiagnostics diagnostics;
    var attempts = 0;
    diagnostics = SafeDiagnostics(
      configuration: null,
      write: (line) {
        attempts++;
        diagnostics.record(DiagnosticEvent.frameworkError);
        if (attempts == 1) {
          throw StateError('unavailable sink');
        }
        output.add(line);
      },
    );
    diagnostics.record(DiagnosticEvent.startupFailed);
    diagnostics.record(
      DiagnosticEvent.authFailed,
      error: const AppFailure(FailureKind.denied),
    );

    expect(attempts, 2);
    expect(decodeJsonObject(output.single), containsPair('failure', 'denied'));
  });
}
