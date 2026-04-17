import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool sending = false;

  Future<void> _resend() async {
    setState(() => sending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama maili tekrar gönderildi.')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _check() async {
    await FirebaseAuth.instance.currentUser?.reload();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Doğrula'),
        actions: [
          TextButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            child: const Text('Çıkış'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? '-'}'),
            const SizedBox(height: 10),
            const Text('Devam etmek için emailini doğrula (Spam/Junk dahil).'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sending ? null : _resend,
                child: Text(sending ? 'Gönderiliyor...' : 'Maili Tekrar Gönder'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _check,
                child: const Text('Doğruladım, Kontrol Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
