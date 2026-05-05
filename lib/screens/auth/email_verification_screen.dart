import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _pollTimer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Start polling every 3 seconds to detect verification
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final verified = await auth.isEmailVerified();
    if (verified && mounted) {
      _pollTimer?.cancel();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.sendEmailVerification();
    setState(() => _sending = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verification email resent. Check your inbox.'),
      ));
    }
  }

  Future<void> _manualCheck() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final verified = await auth.isEmailVerified();
    if (verified && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Email not verified yet. Please check your inbox.'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final email = auth.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your email'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'A verification link has been sent to',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please open the email and follow the link to verify your address. The app will detect verification automatically.',
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _sending ? null : _resend,
              child: _sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Resend verification email'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _manualCheck,
              child: const Text('I have verified — continue'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await auth.signOut();
                if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: const Text('Cancel and sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
