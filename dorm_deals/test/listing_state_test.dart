import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/state/listing_state.dart';

void main() {
  Listing createListing({
    String id = '',
    String title = 'COMP3130 Notes',
    DateTime? createdAt,
  }) {
    return Listing(
      id: id,
      title: title,
      description: 'Notes for COMP3130, from weeks 1-13.',
      price: 20,
      category: ItemCategory.notes,
      pickupLocation: 'MQ Library',
      sellerId: 'seller-1',
      sellerName: 'student@test.com',
      createdAt: createdAt ?? DateTime(2026, 5, 18),
    );
  }

  test(
    'loadListings reads listings from Firestore in newest listing first order',
    () async {
      final firestore = FakeFirebaseFirestore();

      await firestore
          .collection('listings')
          .add(
            createListing(
              title: 'Old Listing',
              createdAt: DateTime(2026, 5, 18),
            ).toFirestore(),
          );
      await firestore
          .collection('listings')
          .add(
            createListing(
              title: 'New Listing',
              createdAt: DateTime(2026, 5, 20),
            ).toFirestore(),
          );

      final state = ListingState(firestore: firestore);

      await state.loadListings();

      expect(state.isLoading, false);
      expect(state.errorMessage, null);
      expect(state.listings, hasLength(2));
      expect(state.listings.first.title, 'New Listing');
    },
  );

  test('addListing writes a listing and refreshes local state', () async {
    final firestore = FakeFirebaseFirestore();
    final state = ListingState(firestore: firestore);

    await state.addListing(createListing());

    final snapshot = await firestore.collection('listings').get();

    expect(snapshot.docs, hasLength(1));
    expect(state.listings, hasLength(1));
    expect(state.listings.first.title, 'COMP3130 Notes');
  });

  test('updateListing updates Firestore and local state', () async {
    final firestore = FakeFirebaseFirestore();
    final doc = await firestore
        .collection('listings')
        .add(createListing().toFirestore());

    final state = ListingState(firestore: firestore);
    await state.loadListings();

    final updatedListing = state.listings.first.copyWith(
      id: doc.id,
      title: 'Updated Notes',
      price: 30,
    );

    await state.updateListing(updatedListing);

    final updatedDoc = await firestore.collection('listings').doc(doc.id).get();

    expect(updatedDoc.data()!['title'], 'Updated Notes');
    expect(updatedDoc.data()!['price'], 30);
    expect(state.listings.first.title, 'Updated Notes');
  });

  test(
    'deleteListing removes listing from Firestore and local state',
    () async {
      final firestore = FakeFirebaseFirestore();
      final doc = await firestore
          .collection('listings')
          .add(createListing().toFirestore());

      final state = ListingState(firestore: firestore);
      await state.loadListings();

      await state.deleteListing(state.listings.first.copyWith(id: doc.id));

      final deletedDoc = await firestore
          .collection('listings')
          .doc(doc.id)
          .get();

      expect(deletedDoc.exists, false);
      expect(state.listings, isEmpty);
    },
  );
}
