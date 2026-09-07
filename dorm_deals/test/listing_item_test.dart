import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/widgets/listing_item.dart';

void main() {
  Listing createListing({
    String sellerId = 'seller-1',
    double? latitude,
    double? longitude,
  }) {
    return Listing(
      id: 'listing-1',
      title: 'COMP3130 Notes',
      description: 'Notes for COMP3130, from weeks 1-13.',
      price: 25.0,
      category: ItemCategory.notes,
      pickupLocation: '12 Second Way, Room 318',
      sellerId: sellerId,
      sellerName: 'student123@test.com',
      createdAt: DateTime(2026, 5, 19),
      latitude: latitude,
      longitude: longitude,
    );
  }

  testWidgets('Listing shows listing details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListingItem(
            eachListing: createListing(),
            currentUserId: 'seller-1',
          ),
        ),
      ),
    );

    expect(find.text('COMP3130 Notes'), findsOneWidget);
    expect(find.text('Notes for COMP3130, from weeks 1-13.'), findsOneWidget);
    expect(find.text('\$25.00'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('12 Second Way, Room 318'), findsOneWidget);
    expect(find.text('student123@test.com'), findsOneWidget);
  });

  testWidgets('Listing shows edit and delete buttons for the seller', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListingItem(
            eachListing: createListing(),
            currentUserId: 'seller-1',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('Listing hides edit and delete buttons from other users', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListingItem(
            eachListing: createListing(),
            currentUserId: 'seller-2',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('Listing shows View on Map when location is saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListingItem(
            eachListing: createListing(latitude: -33.7750, longitude: 151.1133),
            currentUserId: 'seller-1',
          ),
        ),
      ),
    );

    expect(find.text('View on Map'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
  });
}
