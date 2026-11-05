# UI acceptance and remaining release evidence

English (`en`) is the supported product language. All application prose, including
validation, semantics, chart/export labels and errors, comes from `lib/shared/l10n/app_en.arb`.
Flutter's pinned SDK generates `lib/shared/l10n/generated`; do not edit generated Dart.
Context-aware views select the app locale; single-language non-widget validation
and export adapters explicitly use the English resource. Add a translated ARB and
complete locale acceptance before advertising another supported language.

Display dates and numbers use `intl` and the selected locale. Storage remains UTC
ISO-8601 and canonical numeric data. Group-size entry accepts English decimal
notation and fractions; formatted display labels are never used as stored values.
Charts expose a text summary and numerical results for every factor state.

## Automated acceptance

Minimum supported logical width: **280 px** for projects, auth, Test Design, matrix,
results and dialogs. The responsive suite exercises 280, 320, 390, 430, 719, 720,
721, 768, 844, 1023, 1024, 1025 and 1440 px, including short/landscape heights.
Normal and 200% scaling preserve reachable actions. Larger platform scales are
honored rather than capped; dense content can scroll. Mobile matrix actions retain
one row and the randomize control stays beside the title. At enlarged desktop text
sizes the toolbar can reflow to keep controls and the grid usable.

`test/shared/ui/ui_accessibility_test.dart` checks action labels, Android touch target
size, text contrast, generated messages/numbers, and reduced-motion behavior.
Existing browser tests exercise actual clipboard events and keyboard selection.
The assembled browser journey captures screenshots under
`build/test-results/screenshots`, including a 390×844 run when invoked with
`BROWSER_DIMENSION=390x844 task test:integration:web`. These are review artifacts,
not automatically approved golden baselines.

The Contact form uses the shared surface card, theme inputs, and action button.
Automated checks cover its labels, targets, contrast, and the full send and retry
interaction at 390 logical pixels. Before release, verify keyboard and
screen-reader operation for the fields, validation messages, and send status.

## Recorded exceptions and release checks

Owner for these acceptance items: **application maintainer (Cameron Greenwalt)**.
Review date: **2026-12-31**, or before publishing a release, whichever comes first.

| Scope | Reason / consequence | Compensating checks and required evidence |
| --- | --- | --- |
| Footer credit text | Explicit product requirement keeps this decorative line on one line and permits shrinking it on small screens; it does not grow at the full content scale. | Full text remains in semantics and tooltip; critical controls/content honor accessibility scaling. Review legibility on release devices. |
| TalkBack / VoiceOver and native hardware | Physical Android/iOS devices and an assistive-technology operator are unavailable in this runner. Widget semantics cannot establish spoken order or native usability. | Automated labels/targets/contrast, browser keyboard and resize tests. Before release, record device, OS, app build and actual screen-reader results for sign-in, design, matrix entry/copy, results, dialogs and sign-out. |
| Release performance on representative hardware | Debug widget/browser timings are not profile/release evidence. | Keep the existing compressed transfer gate. Before release measure cold startup (p95 ≤5 s), action response (p95 ≤100 ms), frames (p95 ≤16.7 ms at 60 Hz), and retained memory after 20 project open/close cycles (growth ≤50 MB). Record target, build, dataset, samples and traces; investigate regressions. These budgets are acceptance targets, not claimed measurements. |

These entries record the scope, reason, consequences, owner, review date and
compensating checks for unavailable manual acceptance. Passing automated tests is
not a claim that the manual checks or performance budgets have passed.
