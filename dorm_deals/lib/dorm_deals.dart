import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dorm_deals/widgets/listings_list.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/widgets/new_listing.dart';

class DormDeals extends StatefulWidget {
  const DormDeals({super.key, this.loadListingsOnStart = true});

  final bool loadListingsOnStart;

  @override
  State<DormDeals> createState() {
    return _DormDealsState();
  }
}

class _DormDealsState extends State<DormDeals> {
  @override
  void initState() {
    super.initState();

    if (!widget.loadListingsOnStart) {
      return;
    }

    // Delay the initial load until after the first build so Provider is available from context.
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      Provider.of<ListingState>(context, listen: false).loadListings();
    });
  }

  void _openAddListingOverlay() {
    showDialog(
      context: context,
      builder: (dialogContext) => const Dialog(child: NewListing()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingState = Provider.of<ListingState>(context);
    final myListings = listingState.listings;

    // Chooses the main screen content based on the current Firestore loading state.
    Widget bodyContent;

    if (listingState.isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (listingState.errorMessage != null) {
      bodyContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(listingState.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                listingState.loadListings();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    } else if (myListings.isEmpty) {
      bodyContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No listings yet!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Be the first to post a listing.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const ValueKey('empty-state-add-listing-button'),
              onPressed: _openAddListingOverlay,
              icon: const Icon(Icons.add),
              label: const Text('Create Listing'),
            ),
          ],
        ),
      );
    } else {
      bodyContent = ListingsList(allListings: myListings);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/dorm_deals_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('DormDeals'),
          ],
        ),
        actions: [
          IconButton(
            key: const ValueKey('appbar-add-listing-button'),
            onPressed: _openAddListingOverlay,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            key: const ValueKey('logout-button'),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}
