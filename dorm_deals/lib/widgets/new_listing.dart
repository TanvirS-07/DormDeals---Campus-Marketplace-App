import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class NewListing extends StatefulWidget {
  const NewListing({super.key, this.existingListing});

  final Listing? existingListing;

  @override
  State<NewListing> createState() {
    return _NewListingState();
  }
}

class _NewListingState extends State<NewListing> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _pickupLocationController;
  late ItemCategory _chosenCategory;
  XFile? _selectedImage;
  bool _isSaving = false;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _pickupLocationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final listing = widget.existingListing;

    _titleController = TextEditingController(text: listing?.title ?? '');
    _descriptionController = TextEditingController(
      text: listing?.description ?? '',
    );
    _priceController = TextEditingController(
      text: listing == null ? '' : listing.price.toStringAsFixed(2),
    );
    _pickupLocationController = TextEditingController(
      text: listing?.pickupLocation ?? '',
    );
    _chosenCategory = listing?.category ?? ItemCategory.textbook;
    _latitude = listing?.latitude;
    _longitude = listing?.longitude;
  }

  void _pickImage() async {
    final imagePicker = ImagePicker();

    final selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 75,
    );

    if (selectedImage == null) {
      return;
    }

    final imageBytes = await selectedImage.readAsBytes();

    // Keep uploaded images small enough for fast listing display and small storage sizes.
    if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo is too large. Please choose an image under 5 MB.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedImage = selectedImage;
    });
  }

  void _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Request location only when the user chooses to attach their current pickup point.
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions were denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied. Please enable them in settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  void _saveListing() async {
    final itemPrice = double.tryParse(_priceController.text);

    final listing = Listing(
      id: widget.existingListing?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: itemPrice ?? 0.0,
      category: _chosenCategory,
      pickupLocation: _pickupLocationController.text.trim(),
      sellerId: widget.existingListing?.sellerId ?? '',
      sellerName: widget.existingListing?.sellerName ?? '',
      createdAt: widget.existingListing?.createdAt ?? DateTime.now(),
      image: widget.existingListing?.image,
      latitude: _latitude,
      longitude: _longitude,
    );

    final validationError = listing.validationError;

    if (validationError != null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Invalid Listing'),
          content: Text(validationError),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save and create a listing.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final oldImageUrl = widget.existingListing?.image;
      String? imageUrl = oldImageUrl;
      String? newlyUploadedImageUrl;

      if (_selectedImage != null) {
        final imageBytes = await _selectedImage!.readAsBytes();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('listing_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putData(imageBytes);
        imageUrl = await storageRef.getDownloadURL();
        newlyUploadedImageUrl = imageUrl;
      }

      final listingWithImage = listing.copyWith(
        sellerId: widget.existingListing?.sellerId ?? currentUser.uid,
        sellerName:
            widget.existingListing?.sellerName ??
            currentUser.email ??
            'Student Seller',
        image: imageUrl,
      );

      if (widget.existingListing == null) {
        await Provider.of<ListingState>(
          context,
          listen: false,
        ).addListing(listingWithImage);
      } else {
        await Provider.of<ListingState>(
          context,
          listen: false,
        ).updateListing(listingWithImage);
      }

      // After Firestore points to the new photo, remove the old image file so they do not take up storage.
      if (widget.existingListing != null &&
          newlyUploadedImageUrl != null &&
          oldImageUrl != null &&
          oldImageUrl != newlyUploadedImageUrl) {
        await FirebaseStorage.instance.refFromURL(oldImageUrl).delete();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving listing: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 50,
              decoration: const InputDecoration(labelText: 'Listing Title'),
            ),
            TextField(
              controller: _descriptionController,
              minLines: 1,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                prefixText: '\$',
                labelText: 'Price',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pickupLocationController,
              decoration: const InputDecoration(labelText: 'Pickup Location'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _latitude == null || _longitude == null
                        ? 'Use Current Location'
                        : 'Location Set',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Item Category:'),
                const SizedBox(width: 12),
                DropdownButton<ItemCategory>(
                  value: _chosenCategory,
                  items: ItemCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                      )
                      .toList(),
                  onChanged: (newCategory) {
                    if (newCategory == null) {
                      return;
                    }

                    setState(() {
                      _chosenCategory = newCategory;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add Photo'),
                ),
                const SizedBox(width: 12),
                if (_selectedImage != null) const Text('Photo selected'),
                if (_selectedImage == null &&
                    widget.existingListing?.image != null)
                  const Text('Photo already uploaded'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveListing,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.existingListing == null
                              ? 'Create Listing'
                              : 'Save Changes',
                        ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
