# Architecture decision record template

Copy this template to `docs/decisions/NNNN_short_title.md` when a decision is needed.
Create the directory with its first real decision. Use a monotonically increasing
number and link the record from the affected standard or feature documentation.

## ADR NNNN: Decision title

- Status: Proposed / Accepted / Superseded / Rejected
- Date: YYYY-MM-DD
- Owner:
- Review participants:
- Related issue, design, or standard:
- Supersedes / superseded by:

## Context

Describe the problem, constraints, affected users/components, and measurable
requirements. Separate known facts from assumptions.

## Decision

State the selected approach and its scope. Identify public contracts, ownership,
dependency direction, configuration, and failure behavior when relevant.

## Alternatives and tradeoffs

Compare credible alternatives, including keeping the current arrangement. Explain
why the selected approach best fits the stated requirements.

## Consequences

Record benefits, costs, operational/security implications, and known limitations.
For a standards exception, identify the exact requirement, affected scope,
compensating checks, owner, and review/expiry date.

## Adoption and validation

Describe migration steps, compatibility, tests, rollout, rollback/recovery, and
the evidence that will establish success. Name any follow-up work and its owner.

## Revisit conditions

Specify the date or measurable change that should trigger reconsideration.
Supersede accepted records with a new ADR when direction changes; retain the
historical decision and link both records.
