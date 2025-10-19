import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/verify_email_page.dart';
import 'pages/menu_page.dart';
import 'pages/admin_home_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDvG7XOkScfjB-vaY8Zz9nnBl2qhBVcrxQ",
      authDomain: "grace-burger-47413.firebaseapp.com",
      projectId: "grace-burger-47413",
      storageBucket: "grace-burger-47413.firebasestorage.app",
      messagingSenderId: "954033012645",
      appId: "1:954033012645:web:a367649f22fc86da45724c",
      measurementId: "G-FRESJT7TDM"
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/menu': (context) => const MenuPage(),
        '/adminhome': (context) => const AdminHomePage(),
      },
    );
  }
}
