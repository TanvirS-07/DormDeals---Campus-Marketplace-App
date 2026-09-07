import 'package:flutter_test/flutter_test.dart';
import 'package:dorm_deals/models/listing.dart';

void main() {
  Listing createListing({
    String title = 'COMP3130 Notes',
    String description = 'Notes for COMP3130, from weeks 1-13.',
    double price = 20.0,
    String pickupLocation = '12 Second Way, Room 318',
  }) {
    return Listing(
      id: 'listing-1',
      title: title,
      description: description,
      price: price,
      category: ItemCategory.notes,
      pickupLocation: pickupLocation,
      sellerId: 'seller-1',
      sellerName: 'student123@test.com',
      createdAt: DateTime(2026, 5, 18),
    );
  }

  // Testing all components of listing.dart
  group('Listing Validation', () {
    test('returns null when listing details are valid', () {
      final listing = createListing();

      expect(listing.validationError, null);
    });

    test('returns an error when the listing title is too short', () {
      final listing = createListing(title: 'Book');

      expect(
        listing.validationError,
        'Give your listing a clearer title, like "COMP3130 Notes".',
      );
    });

    test('returns an error when the listing description is too short', () {
      final listing = createListing(description: 'Notes book');

      expect(
        listing.validationError,
        'Add a few details about the condition of the item, or what is included.',
      );
    });

    test('returns an error when the listing price is zero', () {
      final listing = createListing(price: 0);

      expect(listing.validationError, 'Price must be greater than \$0.');
    });

    test('returns an error when the listing price is too high', () {
      final listing = createListing(price: 15000);

      expect(
        listing.validationError,
        'That price seems too high for DormDeals. Please contact support for listings of this price!',
      );
    });

    test('returns an error when pickup location is missing', () {
      final listing = createListing(pickupLocation: '');

      expect(listing.validationError, 'Add a pickup spot on or near campus.');
    });
  });

  group('Listing copyWith', () {
    test('Updates only the values that are provided', () {
      final listing = createListing();

      final updatedListing = listing.copyWith(
        title: 'New Apple Macbook',
        price: 750.0,
      );

      expect(updatedListing.title, 'New Apple Macbook');
      expect(updatedListing.price, 750.0);
      expect(updatedListing.description, listing.description);
      expect(updatedListing.pickupLocation, listing.pickupLocation);
    });
  });
}
