/// Staff login screen — email + 4-digit PIN for staff authentication
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tulasihotels/features/staff/providers/staff_provider.dart';
import 'package:tulasihotels/features/staff/services/staff_permissions.dart';
import 'package:tulasihotels/features/staff/services/staff_service.dart';
import 'package:tulasihotels/features/staff/services/attendance_service.dart';
import 'package:tulasihotels/router/app_router.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen> {
  final _emailCtrl = TextEditingController();
  String _pin = '';
  bool _isLoading = false;
  String? _error;
  bool _emailSubmitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submitEmail() {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _emailSubmitted = true;
      _error = null;
    });
  }

  void _backToEmail() {
    setState(() {
      _emailSubmitted = false;
      _pin = '';
      _error = null;
    });
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = null;
    });

    if (_pin.length == 4) {
      _verifyLogin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  void _onClear() {
    setState(() {
      _pin = '';
      _error = null;
    });
  }

  Future<void> _verifyLogin() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      final staff = await StaffService.verifyEmailAndPin(email, _pin);

      if (staff == null) {
        setState(() {
          _error = 'Invalid email or PIN. Please try again.';
          _pin = '';
          _isLoading = false;
        });
        return;
      }

      // Set logged-in staff and persist session
      ref.read(loggedInStaffProvider.notifier).login(staff);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome, ${staff.name}! (${staff.role.displayName})',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to permission-appropriate home screen
        context.go(StaffPermissions.homeRoute(staff));
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _pin = '';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_emailSubmitted) {
              _backToEmail();
            } else {
              context.canPop() ? context.pop() : context.go(AppRoutes.billing);
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Staff icon
                Icon(
                  Icons.badge_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Staff Login',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _emailSubmitted
                      ? 'Enter your 4-digit PIN'
                      : 'Enter your email to continue',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                if (!_emailSubmitted) ...[
                  // Step 1: Email entry
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    onSubmitted: (_) => _submitEmail(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _submitEmail,
                      child: const Text('Continue'),
                    ),
                  ),
                ] else ...[
                  // Step 2: Show email + PIN entry
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _emailCtrl.text.trim(),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _backToEmail,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PIN dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _pin.length;
                      return Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Number pad
                  _NumberPad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    onClear: _onClear,
                    enabled: !_isLoading,
                  ),
                ],

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Loading indicator
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),

                const SizedBox(height: 24),

                // Quick clock-out button for already logged-in staff
                // Import AttendanceService at the top if not already imported
                // import 'package:your_project_path/core/services/attendance_service.dart';
                Consumer(
                  builder: (context, ref, _) {
                    final loggedIn = ref.watch(loggedInStaffProvider);
                    if (loggedIn == null) return const SizedBox();
                    return OutlinedButton.icon(
                      onPressed: () async {
                        await AttendanceService.clockOut(loggedIn.id);
                        ref.read(loggedInStaffProvider.notifier).logout();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${loggedIn.name} clocked out'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: Text('Clock out ${loggedIn.name}'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Number Pad ────────────────────────────────────────────────

class _NumberPad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool enabled;

  const _NumberPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 8),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 8),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PadButton(label: 'C', onTap: enabled ? onClear : null),
            const SizedBox(width: 12),
            _PadButton(label: '0', onTap: enabled ? () => onDigit('0') : null),
            const SizedBox(width: 12),
            _PadButton(
              icon: Icons.backspace_outlined,
              onTap: enabled ? onBackspace : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits
          .map(
            (d) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _PadButton(
                label: d,
                onTap: enabled ? () => onDigit(d) : null,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _PadButton({this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 72,
      height: 56,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 24)
                : Text(
                    label ?? '',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
