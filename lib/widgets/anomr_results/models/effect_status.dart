/// Per-factor outcome of comparing the two state means against the
/// detectable-difference bounds derived from the project risk level.
enum EffectStatus {
  significant('Detectable difference'),
  notDetected('No detectable difference'),
  marginal('Marginal'),
  insufficient('Insufficient data');

  const EffectStatus(this.label);

  final String label;
}
