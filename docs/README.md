# Engineering standards

Reviewed against upstream guidance: **2026-11-04**.

These documents define the intended engineering practices for a new Dart/Flutter
application. They were written independently of the application's implementation.
They are a target for future development and adoption, not a statement that the
current code, tooling, or delivery pipeline already complies.

## Reading guide

| Document | Scope |
| --- | --- |
| [Dart/Flutter coding standards](dart_flutter_coding_standards.md) | Style, types, API design, async work, widget lifecycle, and analyzer baseline. Combines style and coding standards. |
| [Testing standards](testing_standards.md) | Unit, widget, integration, golden, and regression tests; determinism and coverage. |
| [Architecture standards](architecture_standards.md) | Responsibilities, dependency direction, feature boundaries, state, and data contracts. |
| [Configuration and dependency injection](configuration_and_dependency_injection.md) | Typed configuration, build environments, runtime settings, composition, and practical examples. |
| [UI quality standards](ui_quality_standards.md) | Accessibility, localization, responsive behavior, and performance. |
| [Security, privacy, and observability](security_privacy_and_observability.md) | Trust boundaries, data protection, logs, errors, and operational signals. |
| [Development workflow](development_workflow.md) | Dependencies, code generation, review, CI, releases, and documentation. |
| [Architecture decision template](adr_template.md) | A reusable record for consequential decisions and exceptions. |

Start with architecture and configuration when designing a feature. Use the coding
and testing documents during implementation, and the workflow checklist before
review. Each specialist document owns its subject; cross-links avoid competing
definitions of the same rule.

Implementation and evidence: [adoption status](standards_adoption.md),
[application architecture](architecture_map.md), [configuration](app_configuration.md),
[test execution](testing_evidence.md), [security operations](security_operations.md),
and [UI acceptance](ui_acceptance.md).

## Requirement language and decisions

- **MUST / MUST NOT**: required for work claiming compliance with this baseline.
- **SHOULD / SHOULD NOT**: the default; document a concrete reason when departing.
- **MAY**: an option to use when it solves an actual requirement.

These are project standards, informed by official Dart/Flutter guidance and other
primary sources linked beside the relevant guidance. A project choice, such as
feature-oriented directories or a coverage target, is not presented as a universal
industry rule. No state management, networking, routing, or code generation package
is mandated by this baseline.

A departure from a MUST requires a recorded exception: scope, reason, consequences,
compensating checks, owner, and review date. Use an
[architecture decision record (ADR)](adr_template.md) for lasting or cross-cutting
decisions. A short review note is sufficient for a local SHOULD departure.

## Adoption and maintenance

1. Select and record a supported stable Flutter SDK and its bundled Dart version.
2. Add the analyzer, formatting, and CI checks described here in a separate change.
3. Apply this baseline to new work; track existing gaps in an explicit migration
   backlog rather than implying that publishing documentation fixes them.
4. Migrate by feature or boundary with behavioral regression coverage. Keep broad
   mechanical formatting separate from behavior changes.
5. Review these documents during SDK upgrades and at least every six months.
   Update examples and checks together when a standard changes.

Configuration snippets, commands, directory trees, and example names are reference
designs. They do not assert that the corresponding files or tasks exist today.
The existing [web release guide](web_releases.md) and
[Firebase migration guide](firebase_migration_guide.md) remain separate operational
documents; they were not used to derive this baseline.
