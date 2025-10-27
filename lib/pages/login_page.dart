import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'menu_page.dart';
import 'admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  
  bool _agreeTerms = false;
  String? _errorMessage;

  // ───────────────────────────────
  // SIGN IN WITH GOOGLE
  // ───────────────────────────────
  Future<void> _signInWithGoogle() async {
  setState(() => _loading = true);
  try {
    // For both Web & Mobile
    UserCredential userCred;

    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      // ───────────────────────────────
      // MOBILE FLOW
      // ───────────────────────────────
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      userCred = await _auth.signInWithCredential(credential);
    } else {
      // ───────────────────────────────
      // WEB FLOW (like signInWithPopup)
      // ───────────────────────────────
      await _auth.signOut();
      GoogleAuthProvider provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      userCred = await _auth.signInWithPopup(provider);
    }

    final user = userCred.user!;
    final userRef = _db.collection('users').doc(user.uid);
    final userSnap = await userRef.get();

    // ───────────────────────────────
    // FIRESTORE USER CREATION (LIKE REACT)
    // ───────────────────────────────
    if (!userSnap.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'No Name',
        'photoURL': user.photoURL,
        'createdAt': DateTime.now().toIso8601String(),
        'orderHistory': [],
      });
      debugPrint("✅ New user created in Firestore: ${user.email}");
    } else {
      debugPrint("ℹ️ Existing user logged in: ${user.email}");
    }

    _navigateUser(user);
  } catch (e) {
    _showSnack('Google sign-in failed: $e', isError: true);
    debugPrint('Google sign-in error: $e');
  } finally {
    setState(() => _loading = false);
  }
}

  // ───────────────────────────────
  // SIGN IN WITH EMAIL
  // ───────────────────────────────
  Future<void> _signInWithEmail() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = result.user!;
      _navigateUser(user);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.code == 'user-not-found'
            ? 'No user found for that email.'
            : e.code == 'wrong-password'
                ? 'Incorrect password.'
                : e.message ?? 'Login failed.';
      });
      _showSnack(_errorMessage!, isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ───────────────────────────────
  // SIGN UP FUNCTION
  // ───────────────────────────────
  Future<void> _signUpWithEmail(
      String name, String email, String password) async {
    setState(() => _loading = true);
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user!;
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': name,
        'createdAt': DateTime.now().toIso8601String(),
        'orderHistory': [],
      });
      _showSnack('Account created successfully!');
    } catch (e) {
      _showSnack('Signup failed: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ───────────────────────────────
  // NAVIGATE BASED ON ROLE
  // ───────────────────────────────
  void _navigateUser(User user) {
    final isAdmin = user.email == 'admin@graceburger.com';
    Widget nextPage =
        isAdmin ? const AdminDashboard() : const MenuPage();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  // ───────────────────────────────
  // SHOW TOAST / SNACKBAR
  // ───────────────────────────────
  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? Colors.red : Colors.green,
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ───────────────────────────────
  // BUILD UI
  // ───────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/burger_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.6)),

          Center(
            child: SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                color: Colors.white.withOpacity(0.95),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Grace Burger Login",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),

                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: _loading ? null : _signInWithEmail,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("Sign In"),
                      ),

                      const SizedBox(height: 10),

                      OutlinedButton.icon(
                        onPressed: _loading ? null : _signInWithGoogle,
                        icon: Image.asset('assets/google.png', height: 18),
                        label: const Text("Sign in with Google"),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () {
                          _showSignUpDialogFunc();
                        },
                        child: const Text("Create an Account"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────
  // SIGNUP DIALOG (LIKE REACT MODAL)
  // ───────────────────────────────
  void _showSignUpDialogFunc() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: const Text("Create Account"),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Full Name"),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: "Confirm Password"),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (val) {
                        setStateDialog(() => _agreeTerms = val ?? false);
                      },
                    ),
                    const Expanded(
                      child: Text(
                          "I agree to the Terms of Service and Privacy Policy"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (!_agreeTerms) {
                  _showSnack("Please agree to the terms.", isError: true);
                  return;
                }
                if (passCtrl.text != confirmCtrl.text) {
                  _showSnack("Passwords do not match.", isError: true);
                  return;
                }
                Navigator.pop(context);
                _signUpWithEmail(
                  nameCtrl.text.trim(),
                  emailCtrl.text.trim(),
                  passCtrl.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text("Create Account"),
            ),
          ],
        );
      }),
    );
  }
}
