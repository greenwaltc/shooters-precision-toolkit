import 'package:bramwells_precision_test_kit/shared/foundation/external_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('external destinations require an approved HTTPS host and port', () {
    final hosts = {'www.paypal.com', 'statisticsbyjim.com'};
    final policy = ExternalLinkPolicy(allowedHosts: hosts);
    hosts.add('untrusted.test');
    for (final url in [
      'http://www.paypal.com/',
      'https://www.paypal.com.untrusted.test/',
      'https://www.paypal.com:8443/',
      'https://user@www.paypal.com/',
      'https://www.paypal.com@untrusted.test/',
      'https://untrusted.test/',
      'javascript:alert(1)',
      '//www.paypal.com/',
    ]) {
      expect(policy.permits(Uri.parse(url)), isFalse, reason: url);
    }
    expect(policy.permits(Uri.parse('https://www.paypal.com/')), isTrue);
    expect(policy.permits(Uri.parse('https://statisticsbyjim.com/')), isTrue);
  });
}
