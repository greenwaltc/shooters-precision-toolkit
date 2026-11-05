/// Shipped product policy. Owner: application maintainer. Public, reviewed values;
/// changes take effect with the next artifact. These are not remote flags.
abstract final class BehaviorPolicy {
  /// Maximum project title length accepted by the project storage rules.
  static const maxProjectTitleLength = 200;

  /// Upper bound for reading and writing a portable project file, in bytes.
  static const maxProjectFileBytes = 256 * 1024;

  static const initialCloudLoadTimeout = Duration(seconds: 15);
  static const saveDebounce = Duration(seconds: 2);
  static const emailCooldown = Duration(seconds: 60);
  static const emailCountdownRefresh = Duration(seconds: 1);
  static const pasteErrorVisibility = Duration(seconds: 3);
  static const selectionGuard = Duration(milliseconds: 150);
  static const historyCapacity = 100;
  static const resultDecimalPlaces = 4;
  static const axisDecimalPlaces = 2;
  static const jpegQuality = 92;
  static const projectsPageSize = 25;
  static const externalLinkHosts = {'www.paypal.com', 'statisticsbyjim.com'};
  static const donationsOrigin = 'www.paypal.com';
  static const donationsPath = '/paypalme/dentonbramwell';
}
