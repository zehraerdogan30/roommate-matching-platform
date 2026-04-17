import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'verify_email_screen.dart';
import '../profile/profile_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../matches/matches_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snap.data;
        if (user == null) return const LoginScreen();
        if (!user.emailVerified) return const VerifyEmailScreen();

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, docSnap) {
            if (!docSnap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final data = docSnap.data!.data() ?? {};
            final profileCompleted = data['profileCompleted'] == true;
            final answersCompleted = data['answersCompleted'] == true;

            if (!profileCompleted) return const ProfileScreen();
            if (!answersCompleted) return const OnboardingScreen();

            return const MatchesScreen();
          },
        );
      },
    );
  }
}
