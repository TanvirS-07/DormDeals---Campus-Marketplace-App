import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ItemCategory {
  textbook('Textbook'),
  notes('Notes'),
  electronics('Electronics'),
  essentials('Uni Essentials'),
  stationery('Stationery');

  const ItemCategory(this.label);

  final String label;
}

const categoryIcons = {
  ItemCategory.textbook: Icons.menu_book,
  ItemCategory.notes: Icons.description,
  ItemCategory.electronics: Icons.laptop_mac,
  ItemCategory.essentials: Icons.backpack,
  ItemCategory.stationery: Icons.edit_note,
};

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.pickupLocation,
    required this.sellerId,
    required this.sellerName,
    required this.createdAt,

    // These are optional because a user might create a listing without adding a photo or using their location.
    this.image,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final ItemCategory category;
  final String pickupLocation;
  final String sellerId;
  final String sellerName;
  final DateTime createdAt;
  final String? image;
  final double? latitude;
  final double? longitude;

  String? get validationError {
    if (title.trim().length < 5) {
      return 'Give your listing a clearer title, like "COMP3130 Notes".';
    }
    if (description.trim().length < 15) {
      return 'Add a few details about the condition of the item, or what is included.';
    }
    if (price <= 0) {
      return 'Price must be greater than \$0.';
    }
    if (price > 10000) {
      return 'That price seems too high for DormDeals. Please contact support for listings of this price!';
    }
    if (pickupLocation.trim().isEmpty) {
      return 'Add a pickup spot on or near campus.';
    }
    return null;
  }

  Listing copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    ItemCategory? category,
    String? pickupLocation,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    String? image,
    double? latitude,
    double? longitude,
  }) {
    return Listing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      image: image ?? this.image,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Converts a Listing object into a format Firestore can understand and store.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category.name,
      'pickupLocation': pickupLocation,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Converts a Firestore document back into a Listing object.
  factory Listing.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;

    return Listing(
      id: document.id,
      title: data['title'],
      description: data['description'],
      // Firestore sometimes returns this as int, so it is converted to double.
      price: (data['price'] as num).toDouble(),
      category: ItemCategory.values.firstWhere(
        (category) => category.name == data['category'],
      ),
      pickupLocation: data['pickupLocation'],
      sellerId: data['sellerId'],
      sellerName: data['sellerName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      image: data['image'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }
}
