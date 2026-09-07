import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/widgets/new_listing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListingItem extends StatelessWidget {
  const ListingItem({super.key, required this.eachListing, this.currentUserId});

  final Listing eachListing;
  final String? currentUserId;

  void _openEditListingOverlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          Dialog(child: NewListing(existingListing: eachListing)),
    );
  }

  void _launchMaps() async {
    final latitude = eachListing.latitude;
    final longitude = eachListing.longitude;

    if (latitude == null || longitude == null) {
      return;
    }

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    await launchUrl(googleMapsUrl);
  }

  // Turned _confirmDeleteListing into a method because its used in two layouts now and writing that out would get messy :P
  void _confirmDeleteListing(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final listingState = Provider.of<ListingState>(
                context,
                listen: false,
              );
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);

              try {
                await listingState.deleteListing(eachListing);

                if (!dialogContext.mounted) return;
                navigator.pop();

                messenger.showSnackBar(
                  const SnackBar(content: Text('Listing deleted.')),
                );
              } catch (error) {
                if (!dialogContext.mounted) return;
                navigator.pop();

                messenger.showSnackBar(
                  SnackBar(content: Text('Could not delete listing: $error')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _listingDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eachListing.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(eachListing.description),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.person_outline, size: 18),
            const SizedBox(width: 4),
            Expanded(child: Text(eachListing.sellerName)),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '\$${eachListing.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(categoryIcons[eachListing.category], size: 18),
            const SizedBox(width: 6),
            Text(eachListing.category.label),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18),
            const SizedBox(width: 4),
            Expanded(child: Text(eachListing.pickupLocation)),
          ],
        ),
        if (eachListing.latitude != null && eachListing.longitude != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _launchMaps,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('View on Map'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedInUserId =
        currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    // Only the seller who created the listing can see edit and delete actions.
    final isOwner = signedInUserId == eachListing.sellerId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen =
            constraints.maxWidth <
            500; // cards look broken on small screens so listing items stack on mobile

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eachListing.image != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 200,
                            child: Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: Image.network(
                                eachListing.image!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.fallback,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _listingDetails(context),
                      if (isOwner) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                _openEditListingOverlay(context);
                              },
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () {
                                _confirmDeleteListing(context);
                              },
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eachListing.image != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 240,
                            height: 200,
                            child: Container(
                              color: Theme.of(context).colorScheme.surface,
                              child: Image.network(
                                eachListing.image!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.fallback,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(child: _listingDetails(context)),
                      if (isOwner)
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                _openEditListingOverlay(context);
                              },
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () {
                                _confirmDeleteListing(context);
                              },
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
