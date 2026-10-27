import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_recording/shared/ecosystem.dart';
import 'package:financial_recording/shared/widget/service_brand_icon.dart';

void main() {
  testWidgets(
    'switcher services load real bundled identities without initials',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: [
                for (final space in Ecosystem.spaces)
                  ServiceBrandIcon(service: space.id),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images.length, Ecosystem.spaces.length);
      expect(
        images
            .map((image) => (image.image as AssetImage).assetName)
            .toSet()
            .length,
        Ecosystem.spaces.length,
      );
      expect(find.byType(Text), findsNothing);
      expect(
        ServiceBrandIcon.assetFor('ruang'),
        'assets/brand_icons/services/toolkit.png',
      );
      expect(
        ServiceBrandIcon.assetFor('site'),
        'assets/brand_icons/services/site.png',
      );
    },
  );
  testWidgets(
    'unknown services use a generic icon and cannot request an arbitrary asset',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ServiceBrandIcon(service: '../private', label: 'Other service'),
        ),
      );
      expect(ServiceBrandIcon.assetFor('../private'), isNull);
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.apps_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
