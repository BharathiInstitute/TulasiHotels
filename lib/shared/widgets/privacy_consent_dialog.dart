/// Privacy & Terms consent dialog — DPDP Act compliant.
/// Shows once on first login. Re-shows if consent version changes.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulasihotels/core/services/error_logging_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyConsentDialog {
  /// Current consent version. Bump this string whenever Privacy Policy or
  /// Terms of Service are updated — all users will see the dialog again.
  static const String currentVersion = '1.0';

    static const String _privacyUrl =
      'https://restaurants.tulasierp.com/src/pages/privacy.html';
    static const String _termsUrl =
      'https://restaurants.tulasierp.com/src/pages/terms.html';
  static const String _prefsKey = 'privacy_consent_version';

  /// Shows the consent dialog if the user hasn't accepted the current version.
  /// [uid] — Firebase user ID
  /// [consentVersion] — version already stored on the user doc (null = never consented)
  static Future<void> showIfRequired(
    BuildContext context, {
    required String uid,
    required String? consentVersion,
  }) async {
    // Already on current version (from Firestore) — nothing to show
    if (consentVersion == currentVersion) return;

    // Fallback: check local cache (covers Firestore write failures)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localVersion = prefs.getString('${_prefsKey}_$uid');
      if (localVersion == currentVersion) return;
    } catch (_) {}

    if (!context.mounted) return;

    // Non-dismissable: user must accept to continue
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PrivacyConsentContent(uid: uid),
    );
  }
}

class _PrivacyConsentContent extends StatefulWidget {
  final String uid;
  const _PrivacyConsentContent({required this.uid});

  @override
  State<_PrivacyConsentContent> createState() => _PrivacyConsentContentState();
}

class _PrivacyConsentContentState extends State<_PrivacyConsentContent> {
  bool _privacyAccepted = false;
  bool _termsAccepted = false;
  bool _isSaving = false;

  bool get _canSubmit => _privacyAccepted && _termsAccepted;

  Future<void> _submit() async {
    if (!_canSubmit || _isSaving) return;
    setState(() => _isSaving = true);

    // Save to local cache first (always works, even offline)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${PrivacyConsentDialog._prefsKey}_${widget.uid}',
        PrivacyConsentDialog.currentVersion,
      );
    } catch (_) {}

    // Also save to Firestore (best-effort)
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'consentVersion': PrivacyConsentDialog.currentVersion,
        'consentedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('⚠️ Consent: save failed: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        severity: ErrorSeverity.warning,
        metadata: {'context': 'privacy consent save'},
      ).ignore();
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Prevent back-button dismissal
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Privacy & Terms', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DPDP notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'In accordance with India\'s Digital Personal Data Protection (DPDP) Act 2023, '
                  'we need your consent before processing your personal data.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Policy checkbox
              CheckboxListTile(
                value: _privacyAccepted,
                onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      const TextSpan(text: 'I have read and agree to the '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>
                              _openUrl(PrivacyConsentDialog._privacyUrl),
                      ),
                    ],
                  ),
                ),
              ),

              // Terms checkbox
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                    children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>
                              _openUrl(PrivacyConsentDialog._termsUrl),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                'You must accept both to use Tulasi Restaurants.',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('I Accept & Continue'),
          ),
        ],
      ),
    );
  }
}
