import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'pages/auth_service.dart';
import 'pages/homepage.dart';
import 'pages/auth_screen.dart';
import 'firebase_options.dart';
import 'pages/forgot_password.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Live translation',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/home': (context) =>
              const LiveTranslationPage(), // Updated reference
          '/forgot-password': (context) => const ForgotPasswordPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: auth.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          return snapshot.hasData
              ? const LiveTranslationPage() // Updated reference
              : const AuthScreen(); // Or your LoginPage()
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
