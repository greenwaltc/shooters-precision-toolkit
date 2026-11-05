import 'package:url_launcher/url_launcher.dart';

import '../foundation/external_links.dart';

/// An external link launcher that checks destinations before handing them to
/// the platform.
final class UrlLauncherLinks implements ExternalLinks {
  /// Creates a launcher that refuses URLs outside [policy].
  const UrlLauncherLinks({required this.policy});
  final ExternalLinkPolicy policy;
  @override
  Future<bool> open(Uri uri) async {
    if (!policy.permits(uri)) {
      return false;
    }
    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}
