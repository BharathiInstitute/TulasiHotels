/// Customer-facing feedback submission screen (no auth required)
library;

import 'package:flutter/material.dart';
import 'package:tulasihotels/core/utils/id_generator.dart';
import 'package:tulasihotels/features/feedback/services/feedback_service.dart';
import 'package:tulasihotels/models/feedback_model.dart';

class CustomerFeedbackScreen extends StatefulWidget {
  final String hotelId;
  const CustomerFeedbackScreen({super.key, required this.hotelId});

  @override
  State<CustomerFeedbackScreen> createState() => _CustomerFeedbackScreenState();
}

class _CustomerFeedbackScreenState extends State<CustomerFeedbackScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  double _foodRating = 4;
  double _serviceRating = 4;
  double _ambianceRating = 4;
  bool _submitted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_submitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thank You!')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              Text(
                'Thank you for your feedback!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'We appreciate your time and will use this to improve.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Your Feedback'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rate Your Experience', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 24),

            // Food rating
            _RatingRow(
              label: 'Food Quality',
              icon: Icons.restaurant,
              value: _foodRating,
              onChanged: (v) => setState(() => _foodRating = v),
            ),
            const SizedBox(height: 16),

            // Service rating
            _RatingRow(
              label: 'Service',
              icon: Icons.room_service,
              value: _serviceRating,
              onChanged: (v) => setState(() => _serviceRating = v),
            ),
            const SizedBox(height: 16),

            // Ambiance rating
            _RatingRow(
              label: 'Ambiance',
              icon: Icons.nightlife,
              value: _ambianceRating,
              onChanged: (v) => setState(() => _ambianceRating = v),
            ),
            const SizedBox(height: 24),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your Name (optional)',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Phone
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (optional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Comment
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comments (optional)',
                prefixIcon: Icon(Icons.comment),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final feedback = FeedbackModel(
        id: generateSafeId('fb'),
        foodRating: _foodRating.round(),
        serviceRating: _serviceRating.round(),
        ambianceRating: _ambianceRating.round(),
        customerName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        comments: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      await FeedbackService.submitPublicFeedback(widget.hotelId, feedback);
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      setState(() => _submitting = false);
    }
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  const _RatingRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)}/5',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
