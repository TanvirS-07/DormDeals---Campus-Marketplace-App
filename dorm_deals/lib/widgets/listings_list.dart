import 'package:flutter/material.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/widgets/listing_item.dart';

class ListingsList extends StatelessWidget {
  const ListingsList({super.key, required this.allListings});

  final List<Listing> allListings;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allListings.length,
      itemBuilder: (listContext, index) {
        return ListingItem(eachListing: allListings[index]);
      },
    );
  }
}
