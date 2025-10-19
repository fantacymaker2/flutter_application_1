import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String fullName;
  final String email;

  const VerifyEmailPage({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _checking = false;
  bool _resending = false;

  Future<void> _checkVerification() async {
    setState(() => _checking = true);

    await FirebaseAuth.instance.currentUser!.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      // Add user to Firestore only after verification
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': widget.fullName,
        'email': widget.email,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Please check your inbox or spam folder.'),
        ),
      );
    }

    setState(() => _checking = false);
  }

  Future<void> _resendVerification() async {
    setState(() => _resending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent again! Please check your inbox or spam folder.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_read, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Verify Your Email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'We’ve sent a verification link to your email.\nPlease verify it, then tap below.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _checking ? null : _checkVerification,
                child: _checking
                    ? const CircularProgressIndicator()
                    : const Text('I have verified my email'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _resending ? null : _resendVerification,
                child: _resending
                    ? const CircularProgressIndicator()
                    : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 20),
              const Text(
                '💡 Tip: If you don’t see the email, please check your Spam or Junk folder.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
