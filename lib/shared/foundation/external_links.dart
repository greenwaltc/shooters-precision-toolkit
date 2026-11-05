final class ExternalLinkPolicy {
  ExternalLinkPolicy({required Set<String> allowedHosts})
    : allowedHosts = Set.unmodifiable(allowedHosts);
  final Set<String> allowedHosts;
  bool permits(Uri uri) =>
      uri.scheme == 'https' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      allowedHosts.contains(uri.host);
}

abstract interface class ExternalLinks {
  Future<bool> open(Uri uri);
}
