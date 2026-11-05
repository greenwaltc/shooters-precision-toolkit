/// The host and transport rules for opening external links.
final class ExternalLinkPolicy {
  /// Copies the set of hosts the app is allowed to open.
  ExternalLinkPolicy({required Set<String> allowedHosts})
    : allowedHosts = Set.unmodifiable(allowedHosts);
  final Set<String> allowedHosts;

  /// Accepts an HTTPS URL on port 443 with no user credentials and an exact
  /// allowed host.
  bool permits(Uri uri) =>
      uri.scheme == 'https' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      allowedHosts.contains(uri.host);
}

/// A platform operation for opening an external URL.
abstract interface class ExternalLinks {
  /// Attempts to open [uri] and returns whether the platform accepted the
  /// request.
  ///
  /// An implementation can refuse a destination under its link policy.
  Future<bool> open(Uri uri);
}
