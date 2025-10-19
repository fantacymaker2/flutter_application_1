import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Google Sign-In (works for Web + Android/iOS)
  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // ✅ For Web
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // ✅ For Android / iOS
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null; // user cancelled

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? user = userCredential.user;

      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);
        final userSnap = await userRef.get();

        if (!userSnap.exists) {
          await userRef.set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'createdAt': DateTime.now().toIso8601String(),
            'orderHistory': [],
          });
        }
      }

      return user;
    } catch (e) {
      print("Error signing in with Google: $e");
      rethrow;
    }
  }

  /// 🔹 Email Sign-Up
  Future<User?> signUpWithEmail(
      String email, String password, String fullName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': fullName,
          'photoURL': null,
          'createdAt': DateTime.now().toIso8601String(),
          'orderHistory': [],
        });
      }

      return user;
    } catch (e) {
      print("Error signing up with email: $e");
      rethrow;
    }
  }

  /// 🔹 Email Sign-In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Error signing in with email: $e");
      rethrow;
    }
  }

  /// 🔹 Save Order to Firestore
  Future<String> saveOrder(Map<String, dynamic> orderData) async {
    try {
      final docRef = await _firestore.collection('orders').add({
        ...orderData,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'Processing',
        'paymentConfirmed': false,
      });

      print("Order saved with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("Error saving order: $e");
      rethrow;
    }
  }
}
