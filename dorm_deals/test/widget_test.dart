import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/dorm_deals.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  testWidgets('DormDeals page shows empty state and main actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ListingState(firestore: FakeFirebaseFirestore()),
        child: const MaterialApp(home: DormDeals(loadListingsOnStart: false)),
      ),
    );

    expect(find.text('DormDeals'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('appbar-add-listing-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('logout-button')), findsOneWidget);
    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(find.text('No listings yet!'), findsOneWidget);
    expect(find.text('Be the first to post a listing.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('empty-state-add-listing-button')),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'Create Listing'),
      findsOneWidget,
    );
  });
}
