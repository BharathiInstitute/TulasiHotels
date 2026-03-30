/// Menu header widget for customer-facing menu — shows hotel branding
library;

import 'package:flutter/material.dart';

class MenuHeader extends StatelessWidget {
  final String hotelName;
  final String? logoUrl;
  final String? tagline;

  const MenuHeader({
    super.key,
    required this.hotelName,
    this.logoUrl,
    this.tagline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          if (logoUrl != null)
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(logoUrl!),
            )
          else
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                hotelName.isNotEmpty ? hotelName[0].toUpperCase() : 'H',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            hotelName,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (tagline != null) ...[
            const SizedBox(height: 4),
            Text(
              tagline!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
