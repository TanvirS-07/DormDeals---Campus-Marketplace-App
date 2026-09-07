import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ListingState extends ChangeNotifier {
  ListingState({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage? _storage;

  final List<Listing> _myListings = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Listing> get listings {
    return [..._myListings];
  }

  bool get isLoading {
    return _isLoading;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  // Loads listings newest-first and shows loading/error state for the home screen.
  Future<void> loadListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('listings')
          .orderBy('createdAt', descending: true)
          .get();
      _myListings.clear();

      for (final doc in snapshot.docs) {
        _myListings.add(Listing.fromFirestore(doc));
      }
    } catch (error) {
      _errorMessage = 'Could not load listings. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addListing(Listing newListing) async {
    await _firestore.collection('listings').add(newListing.toFirestore());

    await loadListings();
  }

  Future<void> deleteListing(Listing listing) async {
    // Delete the uploaded image from Storage before removing the listing document.
    if (listing.image != null) {
      final storage = _storage ?? FirebaseStorage.instance;
      await storage.refFromURL(listing.image!).delete();
    }

    await _firestore.collection('listings').doc(listing.id).delete();

    _myListings.removeWhere((item) => item.id == listing.id);

    notifyListeners();
  }

  Future<void> updateListing(Listing updatedListing) async {
    await _firestore
        .collection('listings')
        .doc(updatedListing.id)
        .update(updatedListing.toFirestore());

    final index = _myListings.indexWhere(
      (listing) => listing.id == updatedListing.id,
    );
    if (index == -1) {
      return;
    } else {
      _myListings[index] = updatedListing;
      notifyListeners();
    }
  }
}
