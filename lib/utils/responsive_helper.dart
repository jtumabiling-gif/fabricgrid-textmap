import 'package:flutter/material.dart';

/// Responsive layout helper class
/// Provides utilities to create responsive designs that work across different screen sizes
class ResponsiveHelper {
  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      // Extra small devices (e.g., Infinix Hot 9: 720px width)
      return const EdgeInsets.all(12);
    } else if (width < 480) {
      // Small devices
      return const EdgeInsets.all(14);
    } else if (width < 600) {
      // Medium devices
      return const EdgeInsets.all(16);
    } else {
      // Large devices
      return const EdgeInsets.all(20);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 10);
    } else if (width < 480) {
      return const EdgeInsets.symmetric(horizontal: 12);
    } else if (width < 600) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else {
      return const EdgeInsets.symmetric(horizontal: 20);
    }
  }

  /// Get responsive vertical padding
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return const EdgeInsets.symmetric(vertical: 8);
    } else if (width < 480) {
      return const EdgeInsets.symmetric(vertical: 10);
    } else if (width < 600) {
      return const EdgeInsets.symmetric(vertical: 12);
    } else {
      return const EdgeInsets.symmetric(vertical: 16);
    }
  }

  /// Get responsive spacing between widgets
  static double getResponsiveSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return 8;
    } else if (width < 480) {
      return 10;
    } else if (width < 600) {
      return 12;
    } else {
      return 16;
    }
  }

  /// Get responsive grid cross axis count
  static int getResponsiveGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 480) {
      return 2;
    } else if (width < 720) {
      return 2;
    } else if (width < 1024) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Get responsive grid spacing
  static double getResponsiveGridSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return 8;
    } else if (width < 480) {
      return 10;
    } else if (width < 600) {
      return 12;
    } else {
      return 16;
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double small,
    double? medium,
    double? large,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return small;
    } else if (width < 480) {
      return medium ?? small + 1;
    } else if (width < 600) {
      return (medium ?? small + 2) + 1;
    } else {
      return large ?? (medium ?? small + 2) + 2;
    }
  }

  /// Get responsive aspect ratio for grid items
  static double getResponsiveAspectRatio(BuildContext context,
      {double defaultRatio = 0.8}) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return defaultRatio;
    } else if (width < 480) {
      return defaultRatio;
    } else if (width < 600) {
      return defaultRatio;
    } else {
      return defaultRatio + 0.1;
    }
  }

  /// Get responsive container constraints to prevent overflow
  static BoxConstraints getResponsiveConstraints(
    BuildContext context, {
    double maxWidth = double.infinity,
  }) {
    final width = MediaQuery.of(context).size.width;
    final constraints = BoxConstraints(
      maxWidth: maxWidth > width ? width - 24 : maxWidth,
    );
    return constraints;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) => MediaQuery.of(context).orientation == Orientation.portrait;

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) => MediaQuery.of(context).orientation == Orientation.landscape;

  /// Get screen width
  static double getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;

  /// Get screen height
  static double getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  /// Get responsive card padding
  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return const EdgeInsets.all(10);
    } else if (width < 480) {
      return const EdgeInsets.all(12);
    } else if (width < 600) {
      return const EdgeInsets.all(14);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  /// Get responsive border radius
  static BorderRadius getResponsiveBorderRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return BorderRadius.circular(10);
    } else if (width < 480) {
      return BorderRadius.circular(12);
    } else if (width < 600) {
      return BorderRadius.circular(14);
    } else {
      return BorderRadius.circular(16);
    }
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(
    BuildContext context, {
    required double small,
    double? medium,
    double? large,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      return small;
    } else if (width < 480) {
      return medium ?? small + 2;
    } else if (width < 600) {
      return (medium ?? small + 2) + 2;
    } else {
      return large ?? (medium ?? small + 2) + 4;
    }
  }

  /// Get maximum content width to prevent excessive stretching
  static double getMaxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 480) {
      return width - 24; // Leave 12px margin on each side
    } else if (width < 720) {
      return width - 32; // Leave 16px margin on each side
    } else {
      return 600; // Cap at 600px for very large screens
    }
  }
}
