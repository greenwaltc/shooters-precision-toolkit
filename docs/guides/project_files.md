# Portable project files

Select **Export** in the Data Matrix to save the project's current test design,
measurements, and randomized order as JSON. On Projects, select **Import** and
choose a file exported by a compatible app build. A valid file creates a
separate cloud project with the same title and a fresh ID and timestamps. The
new project appears in the list once its cloud write is acknowledged.

The UTF-8 file contains the fields serialized by
[`ProjectSnapshot`](../../lib/features/experiments/api/project_snapshot.dart)
plus an integer `schemaVersion`. The limit is 256 KiB. The file contains project
data in plain text, so share and store it as you would the measurements it
contains.

## Maintaining the file contract

The [version stamp](../../lib/features/experiments/domain/project_file_version.dart)
records the current supported version and a fingerprint of the serialization
and validation code, the sample catalog, and the relevant file limits. The app
accepts the current version. A future release that needs to keep reading older
files should add an explicit version-specific reader and fixtures.

After editing the contract, format the Dart sources and run
`task project-schema:update`. The task increments the version when the
fingerprint changes. Repeating it with identical inputs preserves the version.
Commit the generated stamp with the source changes. `task check` and both
Hosting validation workflows verify the fingerprint. Pull-request CI also checks
that a changed contract has a higher version than the target branch. To update
against a newer target, use `task project-schema:update BASE=origin/main`,
substituting the branch the pull request targets.

The file version is independent of the Firestore document version. Imported
snapshots go through the existing workspace save path.
