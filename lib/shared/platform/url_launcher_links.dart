import 'package:url_launcher/url_launcher.dart';

import '../foundation/external_links.dart';

final class UrlLauncherLinks implements ExternalLinks {
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
