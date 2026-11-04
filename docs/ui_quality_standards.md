# UI quality, accessibility, and performance

Status and requirement language: [engineering standards](README.md).

## Consistent interaction and visual design

Use an application theme and named design tokens for colors, typography, spacing,
shape, and motion. Reusable components SHOULD express an interaction contract,
including loading, disabled, error, and focus behavior. Do not centralize unrelated
layouts merely because they share a few visual properties.

Every data-driven screen MUST define applicable loading, empty, content, stale,
and failure states. Errors should describe a useful next action. Preserve user
input after recoverable failures. Prevent accidental duplicate submissions and
communicate when a destructive or long-running operation is pending.

## Accessibility

Accessibility is part of feature acceptance. Prefer standard Flutter controls with
appropriate semantics; custom controls MUST expose their role, label, value,
state, and actions. Do not communicate meaning through color alone. Respect text
scaling, sufficient contrast, reduced-motion preferences, and platform touch-target
guidance. See [Flutter accessibility](https://docs.flutter.dev/ui/accessibility).

Project acceptance checks:

- Reach and operate important actions with keyboard input on supported desktop/web
  targets. Focus order must be logical and visible, including dialogs and errors.
- Test common flows with TalkBack and VoiceOver on their supported platforms.
  Ensure repeated decorative content does not overwhelm meaningful semantics.
- Check at normal and 200% text scaling, and at the largest applicable platform
  accessibility settings. Content must remain reachable without clipped actions.
- Give charts, images, and custom drawings meaningful textual summaries or
  alternative views when they carry information.
- Associate validation messages with inputs and expose important async status
  changes to assistive technology without excessive announcements.

Use Flutter's accessibility guideline tests for labels, target size, and contrast
where applicable, plus manual assistive-technology checks. Automated checks do not
prove the whole experience is accessible. See
[Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing).

## Responsive and adaptive layouts

Choose layout from available constraints and content needs. Do not infer layout
from device model or orientation alone. Support resizing, safe areas, keyboard
insets, touch, pointer, and keyboard as appropriate. Preserve navigation and
essential state through layout changes. Avoid stretching readable content across
an unlimited width. See
[Flutter adaptive design](https://docs.flutter.dev/ui/adaptive-responsive/best-practices).

For each major screen, record the minimum supported width and test just below and
above its layout breakpoints. Test long labels and empty/error states at those
sizes. Platform-specific interaction differences should be deliberate and covered
by tests, not scattered ad hoc platform checks.

## Localization and formatting

User-visible strings MUST come from localization resources, including validation,
semantics, and errors. Prefer Flutter's generated localization workflow with ARB
messages. Use placeholders and plural/select rules rather than concatenating
translated fragments. Format numbers and dates for the selected locale. See
[Flutter internationalization](https://docs.flutter.dev/ui/internationalization).

Keep storage formats and units independent of display formatting. Accept localized
input through a defined parser; do not feed display strings back into calculations.
Use directional layout APIs such as `EdgeInsetsDirectional` where direction
matters. Test long translations and right-to-left layout for supported locales.
Even an initially single-language application should avoid hard-coded UI prose.

## Performance and resource budgets

Measure performance on representative devices in profile/release conditions.
Debug-mode timings are not release acceptance evidence. Keep rebuild work small,
use lazy builders for long collections, and avoid unnecessary expensive layout or
paint operations. See [Flutter performance guidance](https://docs.flutter.dev/perf/best-practices).

Before shipping a substantial new flow, define measurable budgets for startup,
interaction latency, frames, memory, network usage, and binary/download size where
relevant. Record the device, build mode, dataset, percentile, and measurement
procedure. A 60 Hz display has about 16.7 ms per frame; 120 Hz has about 8.3 ms.
Use measured frame timing rather than assuming a smooth simulator proves success.

Bound caches and image decoding dimensions. Avoid retaining entire screens through
listeners or callbacks. Profile CPU-heavy work before choosing an off-main-thread
strategy, and verify that strategy on every supported target. Optimizations MUST
preserve behavior and include before/after evidence when they add complexity.

Add [widget or golden tests](testing_standards.md) for the visual contract and
performance regression checks for measured risks. A release review must identify
which device/layout/accessibility checks were completed and any recorded exception.
