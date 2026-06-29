import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tulasihotels/core/design/design_system.dart';
import 'package:tulasihotels/shared/widgets/web_safe_image.dart';

/// A reusable widget that displays the hotel logo from a path (HTTP URL or local file),
/// falling back to a hotel icon if no logo is set.
class ShopLogoWidget extends StatelessWidget {
  final String? logoPath;
  final double size;
  final double borderRadius;
  final double iconSize;

  const ShopLogoWidget({
    super.key,
    required this.logoPath,
    this.size = 36,
    this.borderRadius = 8,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoPath != null && logoPath!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hasLogo ? Colors.transparent : AppColors.primary,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo ? _buildLogoImage() : _buildFallbackIcon(),
    );
  }

  Widget _buildLogoImage() {
    if (logoPath!.startsWith('http')) {
      if (kIsWeb) {
        return WebSafeImage(
          url: logoPath!,
          width: size,
          height: size,
          errorWidget: _buildFallbackIcon(),
        );
      }
      return CachedNetworkImage(
        imageUrl: logoPath!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, url, error) => _buildFallbackIcon(),
      );
    }
    // Local file (non-web only)
    if (!kIsWeb) {
      final file = File(logoPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackIcon(),
        );
      }
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/restaurant_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.primary,
          child: Center(
            child: Icon(Icons.hotel, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}
