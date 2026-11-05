# Standards adoption and verification

This records the staged implementation of the engineering standards. The Firebase
migration guide is excluded from this change. Operational guides remain applicable.

| Stage | Status | Exit checks |
| --- | --- | --- |
| Tests and coding | Complete | Strict analysis; 232 tests in seeds 4729 and 827; 82.67% source-inclusive coverage; 8 emulator contracts; browser clipboard and assembled journey passed |
| Configuration and injection | Complete | 239 unit/widget tests; 82.63% coverage; manifest/argument/checksum tests; native identity checks; 8 emulator tests and browser journey passed |
| UI quality | Implemented; manual release exceptions recorded | 278 tests; 82.67% coverage; strict analysis; label/target/contrast/motion checks; desktop/mobile browser journeys and reviewed screenshots. See [UI acceptance](ui_acceptance.md). |
| Architecture | Complete | Feature boundaries; immutable snapshots and cache authority; pure calculations; typed failures; 287 tests, 82.15% coverage, 8 emulator tests, clipboard and both browser journeys passed. See the [architecture map](../reference/architecture_map.md). |
| Remaining standards | Implemented; release exceptions recorded | Redaction and session tests, isolated rules checks, locked generation and dependencies, build identity and private maps, dev/prod Hosting smoke checks and native build gates. See [final verification](testing_evidence.md) and [security operations](../guides/security_operations.md). |

Automation cannot establish physical-device TalkBack/VoiceOver behavior, remote
repository protection settings, or release performance on hardware unavailable to
the runner. These checks must be recorded with their actual results; they must not
be inferred from passing widget tests.

Both iOS simulator flavors require the matching Xcode platform component on this
workstation. No deployment, infrastructure apply, or migration-guide edit was
part of this adoption.
