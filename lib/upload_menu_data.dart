import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final cloudinary = CloudinaryPublic(
  'dlw9ywu22', // your Cloudinary cloud name
  'o0ppripn',  // your unsigned upload preset
  cache: false,
);

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDvG7XOkScfjB-vaY8Zz9nnBl2qhBVcrxQ",
      authDomain: "grace-burger-47413.firebaseapp.com",
      projectId: "grace-burger-47413",
      storageBucket: "grace-burger-47413.firebasestorage.app",
      messagingSenderId: "954033012645",
      appId: "1:954033012645:web:a367649f22fc86da45724c",
      measurementId: "G-FRESJT7TDM",
    ),
  );

  final firestore = FirebaseFirestore.instance;

  final categories = [
    'Burgers',
    'Sandwiches',
    'Hot Dogs',
    'Rice Meals',
    'Sides',
    'Beverages',
  ];

  print('🚀 Starting upload of product images...\n');

  for (final category in categories) {
    final itemsSnapshot =
        await firestore.collection('menu').doc(category).collection('items').get();

    for (final doc in itemsSnapshot.docs) {
      final name = doc['name'] as String;
      final slug = name
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '-')
          .trim();

      final filePath = 'assets/images/products/$slug.jpg';
      final file = File(filePath);

      if (!file.existsSync()) {
        print('⚠️ No image found for "$name" ($filePath)');
        continue;
      }

      try {
        // Upload to Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            filePath,
            folder: 'menu_items',
          ),
        );

        final imageUrl = response.secureUrl;

        // Update Firestore document with the image URL
        await doc.reference.update({'imageUrl': imageUrl});

        print('✅ Updated "$name" → $imageUrl');
      } catch (e) {
        print('❌ Failed for "$name": $e');
      }
    }
  }

  print('\n🎉 All image URLs added successfully!');
}
