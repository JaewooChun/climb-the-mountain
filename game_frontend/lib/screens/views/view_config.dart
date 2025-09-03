import 'package:flutter/material.dart';

class ViewLighting {
  final LinearGradient backgroundGradient;
  final Color sunColor;
  final double sunIntensity;
  final Offset lightDirection;
  final Color ambientColor;
  final double ambientIntensity;

  const ViewLighting({
    required this.backgroundGradient,
    required this.sunColor,
    required this.sunIntensity,
    required this.lightDirection,
    required this.ambientColor,
    required this.ambientIntensity,
  });
}

class ViewConfigs {
  static const ViewLighting startingView = ViewLighting(
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF87CEEB), // Sky blue at top
        Color(0xFFFFB347), // Orange middle
        Color(0xFFFF6B6B), // Pink-red at bottom
      ],
      stops: [0.0, 0.6, 1.0],
    ),
    sunColor: Color(0xFFFFD700),
    sunIntensity: 0.9,
    lightDirection: Offset(-1, 0.3), // Coming from left, slightly down
    ambientColor: Color(0xFFFFB347),
    ambientIntensity: 0.6,
  );

  static const ViewLighting morningView = ViewLighting(
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF87CEEB), // Light blue
        Color(0xFFE6E6FA), // Lavender
        Color(0xFFFFF8DC), // Cornsilk
      ],
      stops: [0.0, 0.5, 1.0],
    ),
    sunColor: Color(0xFFFFFF99),
    sunIntensity: 0.7,
    lightDirection: Offset(-0.8, 0.5),
    ambientColor: Color(0xFFE6E6FA),
    ambientIntensity: 0.8,
  );

  static const ViewLighting nightView = ViewLighting(
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF191970), // Midnight blue
        Color(0xFF483D8B), // Dark slate blue
        Color(0xFF2F4F4F), // Dark slate gray
      ],
      stops: [0.0, 0.4, 1.0],
    ),
    sunColor: Color(0xFFC0C0C0), // Silver moonlight
    sunIntensity: 0.3,
    lightDirection: Offset(1, -0.5), // Moonlight from right
    ambientColor: Color(0xFF483D8B),
    ambientIntensity: 0.3,
  );

  static const ViewLighting auroraView = ViewLighting(
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0A0F1C), // Very dark blue at top
        Color(0xFF1A1F3A), // Dark blue-purple
        Color(0xFF2D3561), // Medium blue
        Color(0xFF4A5D7A), // Lighter blue at horizon
      ],
      stops: [0.0, 0.3, 0.6, 1.0],
    ),
    sunColor: Color(0xFF9D4EDD), // Aurora purple moonlight
    sunIntensity: 0.4,
    lightDirection: Offset(0.5, -0.8), // Northern light from above
    ambientColor: Color(0xFF2D3561),
    ambientIntensity: 0.5,
  );

  static ViewLighting getLightingForView(String viewName) {
    switch (viewName.toLowerCase()) {
      case 'starting':
      case 'sunset':
        return startingView;
      case 'morning':
        return morningView;
      case 'night':
        return nightView;
      case 'view_1':
      case 'aurora':
      case 'alaska':
        return auroraView;
      default:
        return startingView;
    }
  }

  // Helper method to interpolate between two ViewLighting configurations
  static ViewLighting interpolateLighting(ViewLighting from, ViewLighting to, double progress) {
    progress = progress.clamp(0.0, 1.0);
    
    return ViewLighting(
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(from.backgroundGradient.colors[0], to.backgroundGradient.colors[0], progress)!,
          Color.lerp(from.backgroundGradient.colors[1], to.backgroundGradient.colors[1], progress)!,
          Color.lerp(from.backgroundGradient.colors[2], to.backgroundGradient.colors[2], progress)!,
          if (from.backgroundGradient.colors.length > 3 || to.backgroundGradient.colors.length > 3)
            Color.lerp(
              from.backgroundGradient.colors.length > 3 ? from.backgroundGradient.colors[3] : from.backgroundGradient.colors[2],
              to.backgroundGradient.colors.length > 3 ? to.backgroundGradient.colors[3] : to.backgroundGradient.colors[2],
              progress
            )!,
        ],
        stops: to.backgroundGradient.stops,
      ),
      sunColor: Color.lerp(from.sunColor, to.sunColor, progress)!,
      sunIntensity: from.sunIntensity + (to.sunIntensity - from.sunIntensity) * progress,
      lightDirection: Offset.lerp(from.lightDirection, to.lightDirection, progress)!,
      ambientColor: Color.lerp(from.ambientColor, to.ambientColor, progress)!,
      ambientIntensity: from.ambientIntensity + (to.ambientIntensity - from.ambientIntensity) * progress,
    );
  }
}