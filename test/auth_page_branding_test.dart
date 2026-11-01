import 'package:bramwells_precision_test_kit/auth/auth_page.dart';
import 'package:bramwells_precision_test_kit/auth/auth_service.dart';
import 'package:bramwells_precision_test_kit/widgets/app_atmosphere.dart';
import 'package:bramwells_precision_test_kit/widgets/app_brand_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

void main() {
  for (final size in [
    const Size(280, 653),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final verification in [false, true]) {
      testWidgets('auth branding at $size, verification=$verification', (
        tester,
      ) async {
        rootBundle.clear();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          Provider<AuthService>.value(
            value: AuthService(_Auth()),
            child: AuthPage(verification: verification),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AppAtmosphere), findsOneWidget);
        expect(find.byType(ProjectsBannerAppBar), findsOneWidget);
        expect(find.byType(AppBrandLogo), findsOneWidget);
        expect(
          find.byTooltip('Sign out'),
          verification ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);

        if (!verification) {
          final toggle = find.widgetWithText(TextButton, 'Create an account');
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(find.text('Confirm password'), findsOneWidget);
          expect(find.byType(AppAtmosphere), findsOneWidget);
          expect(find.byType(ProjectsBannerAppBar), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        // Cancel the page's cooldown timer before ending the test.
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
