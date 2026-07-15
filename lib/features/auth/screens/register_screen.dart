/// Register screen — Google Sign-In (primary) or Email/Password (secondary)
/// Phone verification happens at Shop Setup (for both Google & email users)
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/core/constants/app_constants.dart';
import 'package:tulasihotels/core/design/design_system.dart';
import 'package:tulasihotels/features/auth/providers/auth_provider.dart';
import 'package:tulasihotels/features/auth/providers/phone_auth_provider.dart';
import 'package:tulasihotels/features/auth/widgets/auth_layout.dart';
import 'package:tulasihotels/features/auth/widgets/auth_social_section.dart';
import 'package:tulasihotels/features/auth/widgets/password_strength_indicator.dart';
import 'package:tulasihotels/features/auth/widgets/windows_webview_login.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneOtpController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showEmailForm = false;
  String _passwordText = '';

  // Email OTP inline state
  bool _otpSent = false;
  bool _emailVerified = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isResendingOtp = false;
  String? _otpError;
  int _otpCooldownSeconds = 0;
  Timer? _otpCooldownTimer;

  // Phone OTP state
  bool _phoneVerified = false;
  String? _phoneError;

  void _startOtpCooldown() {
    _otpCooldownSeconds = 60;
    _otpCooldownTimer?.cancel();
    _otpCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _otpCooldownSeconds--;
        if (_otpCooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _phoneOtpController.dispose();
    _otpCooldownTimer?.cancel();
    super.dispose();
  }

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool get _isPhoneVerificationRequired => !_isWindowsDesktop;

  Future<void> _handleGoogleRegister() async {
    setState(() => _isGoogleLoading = true);
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .signInWithGoogle();

      if (success && mounted) {
        context.go('/shop-setup');
      } else if (!success && mounted) {
        final authState = ref.read(authNotifierProvider);
        if (authState.pendingAccountLink) {
          _showLinkPasswordDialog(authState.pendingLinkEmail ?? '');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  /// Show dialog to enter password for account linking
  void _showLinkPasswordDialog(String email) {
    final linkPasswordController = TextEditingController();
    bool obscure = true;
    bool linking = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Link Your Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An account with $email already exists. '
                'Enter your password to link Google sign-in.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: linkPasswordController,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: linking
                  ? null
                  : () {
                      ref
                          .read(authNotifierProvider.notifier)
                          .cancelPendingLink();
                      Navigator.pop(ctx);
                    },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: linking
                  ? null
                  : () async {
                      setDialogState(() => linking = true);
                      final success = await ref
                          .read(authNotifierProvider.notifier)
                          .completeLinkWithPassword(
                            linkPasswordController.text,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (success && mounted) {
                        context.go('/shop-setup');
                      } else if (mounted) {
                        final error = ref.read(authErrorProvider);
                        if (error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(error)));
                        }
                      }
                    },
              child: linking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Link & Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  /// Send OTP to verify email
  Future<void> _handleSendOtp() async {
    // Client-side rate limit: 60s cooldown between OTP sends
    if (_otpCooldownSeconds > 0) {
      setState(
        () => _otpError =
            'Please wait $_otpCooldownSeconds seconds before resending',
      );
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || name.length < 2) {
      setState(() => _otpError = 'Please enter a valid name first');
      return;
    }
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _otpError = 'Please enter a valid email first');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _otpError = null;
    });
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      // Don't enumerate auth methods — let Firebase handle duplicate
      // email errors during registration to prevent email enumeration
      // attacks.

      // Send OTP
      final sent = await ref
          .read(authNotifierProvider.notifier)
          .sendRegistrationOTP(email);

      if (!mounted) return;

      if (sent) {
        setState(() {
          _otpSent = true;
          _otpError = null;
        });
        _startOtpCooldown();
      } else {
        setState(() {
          _otpError =
              ref.read(authNotifierProvider).error ??
              'Could not send code. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  /// Verify the entered OTP
  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _otpError = 'Enter the 6-digit code');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpError = null;
    });

    try {
      final email = _emailController.text.trim();
      final ok = await ref
          .read(authNotifierProvider.notifier)
          .verifyRegistrationOTP(email, otp);

      if (!mounted) return;

      if (ok) {
        setState(() {
          _emailVerified = true;
          _otpError = null;
        });
      } else {
        setState(() {
          _otpError = ref.read(authNotifierProvider).error ?? 'Invalid code';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  /// Resend OTP
  Future<void> _handleResendOtp() async {
    setState(() {
      _isResendingOtp = true;
      _otpError = null;
    });

    try {
      final email = _emailController.text.trim();
      final sent = await ref
          .read(authNotifierProvider.notifier)
          .sendRegistrationOTP(email);

      if (!mounted) return;

      if (sent) {
        _otpController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New code sent! ✉️'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _otpError = 'Failed to resend. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isResendingOtp = false);
      }
    }
  }

  /// Send phone OTP
  Future<void> _handleSendPhoneOtp() async {
    if (_isWindowsDesktop) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Phone OTP is not supported on Windows app. Continue without it.',
          ),
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _phoneError = 'Enter a valid 10-digit phone number');
      return;
    }
    setState(() => _phoneError = null);
    unawaited(ref.read(phoneAuthProvider.notifier).sendOtp(phone));
  }

  /// Verify phone OTP
  Future<void> _handleVerifyPhoneOtp() async {
    if (_isWindowsDesktop) {
      setState(() => _phoneVerified = true);
      return;
    }

    final otp = _phoneOtpController.text.trim();
    if (otp.length != 6) {
      setState(() => _phoneError = 'Enter the 6-digit code');
      return;
    }
    setState(() => _phoneError = null);
    final ok = await ref.read(phoneAuthProvider.notifier).verifyOtp(otp);
    if (ok && mounted) {
      setState(() => _phoneVerified = true);
    }
  }

  /// Create account (only after email is verified)
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_emailVerified) return;

    setState(() => _isLoading = true);
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            emailVerified: true,
          );

      if (success && mounted) {
        // Save phone number if verified during registration
        if (!_isWindowsDesktop &&
            _phoneVerified &&
            _phoneController.text.trim().isNotEmpty) {
          final phone = '${AppConstants.countryCode}${_phoneController.text.trim()}';
          final synced = await ref
              .read(authNotifierProvider.notifier)
              .updatePhoneVerified(phone: phone);
          if (!synced && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Phone verification sync is delayed. Please verify once in Settings after login.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created & verified! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/shop-setup');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final error = ref.watch(authErrorProvider);

    // Windows: show embedded WebView when desktop login URL is set
    if (_isWindowsDesktop && authState.desktopLoginUrl != null) {
      return WindowsWebViewLogin(
        url: authState.desktopLoginUrl!,
        linkCode: authState.desktopLinkCode,
        expiresAt: authState.desktopLinkExpiresAt,
        onCancel: () {
          ref.read(authNotifierProvider.notifier).cancelDesktopAuth();
        },
      );
    }

    return AuthLayout(
      title: 'Create Account',
      subtitle: 'Get started with ${AppConstants.appName}',
      icon: Icons.person_add_outlined,
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error message
          if (error != null) ...[
            _buildErrorBox(error),
            const SizedBox(height: AppSizes.md),
          ],

          // ── Google + OR + Email Toggle ──
          AuthSocialSection(
            isGoogleLoading: _isGoogleLoading,
            isOtherLoading: _isLoading,
            showEmailForm: _showEmailForm,
            emailButtonLabel: 'Register with Email',
            onGooglePressed: _handleGoogleRegister,
            onEmailToggle: () => setState(() => _showEmailForm = true),
          ),

          // ── Email Registration Form ──
          if (_showEmailForm)
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_emailVerified,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_otpSent,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon: _emailVerified
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[^@]+@[^@]+\.[^@]+',
                      ).hasMatch(value.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // ── Verify Email Button (before OTP sent) ──
                  if (!_otpSent && !_emailVerified)
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _isSendingOtp ? null : _handleSendOtp,
                        icon: _isSendingOtp
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(
                          _isSendingOtp ? 'Sending code...' : 'Verify Email',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── OTP Input Section (after OTP sent, before verified) ──
                  if (_otpSent && !_emailVerified) ...[
                    const SizedBox(height: AppSizes.sm),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Enter the 6-digit code sent to\n${_emailController.text.trim()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // OTP Input
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              hintText: '000000',
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.green.shade600,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Verify + Resend buttons
                          Row(
                            children: [
                              // Resend
                              TextButton.icon(
                                onPressed: _isResendingOtp
                                    ? null
                                    : _handleResendOtp,
                                icon: _isResendingOtp
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh, size: 16),
                                label: const Text('Resend'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              // Verify button
                              FilledButton.icon(
                                onPressed: _isVerifyingOtp
                                    ? null
                                    : _handleVerifyOtp,
                                icon: _isVerifyingOtp
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.verified, size: 18),
                                label: Text(
                                  _isVerifyingOtp
                                      ? 'Verifying...'
                                      : 'Verify Code',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Email Verified Banner ──
                  if (_emailVerified) ...[
                    const SizedBox(height: AppSizes.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Email verified successfully!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── OTP Error ──
                  if (_otpError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _otpError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // ── Phone Number Verification (only after email verified) ──
                  if (_emailVerified && _isPhoneVerificationRequired) ...[
                    const SizedBox(height: AppSizes.md),
                    _buildPhoneVerificationSection(),
                  ],

                  if (_emailVerified && !_isPhoneVerificationRequired) ...[
                    const SizedBox(height: AppSizes.md),
                    _buildWindowsPhoneInfo(),
                  ],

                  // ── Password (only after phone verified) ──
                  if (_phoneVerified || !_isPhoneVerificationRequired) ...[
                    const SizedBox(height: AppSizes.md),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        setState(() => _passwordText = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  // Password strength indicator
                  PasswordStrengthIndicator(password: _passwordText),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) =>
                        _emailVerified ? _handleRegister() : null,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  ], // end if (_phoneVerified)
                  const SizedBox(height: AppSizes.xl),

                  // Register button — only enabled after email & phone verified
                  SizedBox(
                    height: AppSizes.buttonHeight(context),
                    child: ElevatedButton.icon(
                      onPressed: (_isLoading ||
                              !_emailVerified ||
                              (_isPhoneVerificationRequired && !_phoneVerified))
                          ? null
                          : _handleRegister,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add, size: 22),
                      label: Text(
                        _isLoading
                            ? 'Creating account...'
                            : !_emailVerified
                            ? 'Verify email first'
                          : _isPhoneVerificationRequired && !_phoneVerified
                            ? 'Verify phone first'
                            : 'Create Account',
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Terms & Privacy
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'By creating an account, you agree to our ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse('https://tulasihotels.com/terms'),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Text(
                            'Terms',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Text(
                          ' & ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse('https://tulasihotels.com/privacy'),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSizes.lg),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneVerificationSection() {
    final phoneState = ref.watch(phoneAuthProvider);
    final isCodeSent = phoneState.status == PhoneAuthStatus.codeSent;
    final isSending = phoneState.status == PhoneAuthStatus.sending;
    final isVerifying = phoneState.status == PhoneAuthStatus.verifying;

    if (_phoneVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Phone +91 ${_phoneController.text.trim()} verified!',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone input + Send OTP
        if (!isCodeSent && !isVerifying) ...[
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '10-digit mobile number',
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '+91 ',
              counterText: '',
              suffixIcon: _phoneVerified
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: isSending ? null : _handleSendPhoneOtp,
              icon: isSending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sms_outlined, size: 18),
              label: Text(isSending ? 'Sending OTP...' : 'Verify Phone'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal.shade700,
                side: BorderSide(color: Colors.teal.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
          ),
        ],

        // OTP input (after code sent)
        if (isCodeSent || isVerifying) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  'Enter the 6-digit code sent to\n+91 ${_phoneController.text.trim()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneOtpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.teal.shade600,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: phoneState.canResend
                          ? () => ref.read(phoneAuthProvider.notifier).resendOtp()
                          : null,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        phoneState.resendCountdown > 0
                            ? 'Resend in ${phoneState.resendCountdown}s'
                            : 'Resend',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: isVerifying ? null : _handleVerifyPhoneOtp,
                      icon: isVerifying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified, size: 18),
                      label: Text(isVerifying ? 'Verifying...' : 'Verify'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Phone error
        if (_phoneError != null || phoneState.error != null) ...[
          const SizedBox(height: 8),
          Text(
            _phoneError ?? phoneState.error ?? '',
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildWindowsPhoneInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Phone OTP is not fully supported on Windows desktop app. '
              'Create your account now and verify phone later from web/mobile in Settings.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSizes.cardPadding),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
