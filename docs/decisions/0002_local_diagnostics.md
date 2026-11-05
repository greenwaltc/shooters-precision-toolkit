# ADR 0002: Local diagnostic events and private build symbols

- Status: Accepted
- Date: 2026-11-04
- Owner: Application maintainer

## Context

Release failures need to be correlated with source and environment. Vendor
exceptions can include credentials or project payloads. The application currently
uses Firebase Spark and has no approved remote telemetry collector.

## Decision

Install framework and uncaught error hooks at bootstrap and pass an explicit
diagnostic interface to operation owners. Emit only classified local records
with bounded app frame locations. Use a generated build identity to match the
private source maps retained by the release pipeline. Keep customer payloads,
URLs and vendor error text outside the reporting contract.

## Alternatives and consequences

A remote crash reporter would improve fleet visibility but adds a collection,
retention, and access policy. Raw browser logs are simpler but make unsafe details
easy to disclose. Local records let an operator reproduce incidents without
introducing a new service; they cannot supply automatic aggregate alerts.
[Security operations](../guides/security_operations.md) records the compensating checks
and review condition. Diagnostic sink failures never determine app behavior.
