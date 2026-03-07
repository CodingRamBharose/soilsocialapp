import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final authProvider = context.read<AuthProvider>();
      final verified = await authProvider.checkEmailVerified();
      if (verified && mounted) {
        timer.cancel();
        context.go('/dashboard');
      }
    });
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;
    final authProvider = context.read<AuthProvider>();
    await authProvider.resendVerificationEmail();
    setState(() {
      _canResend = false;
      _countdown = 60;
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
        if (mounted) setState(() => _canResend = true);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 56,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l.translate('verifyEmail'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.translate('verifyEmailDesc'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.translate('waitingForVerification'),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _canResend ? _resendEmail : null,
                  child: Text(
                    _canResend
                        ? l.translate('resendEmail')
                        : l.translateWithArgs('resendIn', {
                            'seconds': '$_countdown',
                          }),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context.read<AuthProvider>().signOut();
                    context.go('/sign-in');
                  },
                  child: Text(l.translate('backToSignIn')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
