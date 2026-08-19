import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulasihotels/core/services/error_logging_service.dart';

/// Dialog that shows an NPS (Net Promoter Score) survey to eligible users.
class NpsSurveyDialog {
  static const _shownKey = 'nps_survey_shown';
  static final Map<String, Future<void>> _inFlight = {};
  /// Shows the NPS survey dialog if the user is eligible.
  ///
  /// Eligibility criteria:
  /// - Account is at least 7 days old
  /// - User hasn't completed a survey in the last 90 days
  static Future<void> showIfEligible(
    BuildContext context, {
    required String uid,
    required DateTime? accountCreatedAt,
  }) async {
    final existing = _inFlight[uid];
    if (existing != null) {
      await existing;
      return;
    }
    // Store the Future so route rebuilds share one survey operation.
    // ignore: unawaited_futures
    final Future<void> pending = _showIfEligible(
      context,
      uid: uid,
      accountCreatedAt: accountCreatedAt,
    );
    _inFlight[uid] = pending;
    try {
      await pending;
    } finally {
      if (identical(_inFlight[uid], pending)) _inFlight.remove(uid);
    }
  }

  static Future<void> _showIfEligible(
    BuildContext context, {
    required String uid,
    required DateTime? accountCreatedAt,
  }) async {
    if (accountCreatedAt == null) return;

    // Don't show if account is less than 7 days old
    final accountAge = DateTime.now().difference(accountCreatedAt);
    if (accountAge.inDays < 7) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('${_shownKey}_$uid') == true) return;
    } catch (_) {}

    // Check if user has already completed a recent survey
    try {
      final surveyDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('surveys')
          .doc('nps')
          .get();

      if (surveyDoc.exists) {
        if (surveyDoc.data()?['shownAt'] != null) return;
        final lastSurvey = surveyDoc.data()?['lastCompletedAt'] as Timestamp?;
        if (lastSurvey != null) {
          final daysSinceLast = DateTime.now()
              .difference(lastSurvey.toDate())
              .inDays;
          if (daysSinceLast < 90) return;
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ NPS: eligibility check failed: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        severity: ErrorSeverity.warning,
        metadata: {'context': 'NPS eligibility check'},
      ).ignore();
      return; // Don't show survey if we can't check eligibility
    }

    // Reserve the survey before displaying it so Skip and route rebuilds do
    // not cause the same survey to appear repeatedly.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_shownKey}_$uid', true);
    } catch (_) {}
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('surveys')
          .doc('nps')
          .set(
            {'shownAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true),
          );
    } catch (_) {}

    if (!context.mounted) return;

    int? selectedScore;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('How likely are you to recommend us?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'On a scale of 0-10, how likely are you to recommend Tulasi Restaurants to a friend or colleague?',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 4,
                children: List.generate(11, (index) {
                  return ChoiceChip(
                    label: Text('$index'),
                    selected: selectedScore == index,
                    onSelected: (selected) {
                      setState(() => selectedScore = selected ? index : null);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: selectedScore != null
                  ? () {
                      _submitSurvey(uid, selectedScore!);
                      Navigator.of(context).pop();
                    }
                  : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _submitSurvey(String uid, int score) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('surveys')
          .doc('nps')
          .set({
            'score': score,
            'lastCompletedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('⚠️ NPS: survey submission failed: $e');
      ErrorLoggingService.logError(
        error: e,
        stackTrace: st,
        severity: ErrorSeverity.warning,
        metadata: {'context': 'NPS survey submission', 'score': score},
      ).ignore();
    }
  }
}
