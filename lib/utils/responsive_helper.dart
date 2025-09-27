import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  // Determine device types
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Determine column count for grids
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) {
  return 1; // Mobile: single column
    } else if (isTablet(context)) {
  return 2; // Tablet: two columns
    } else {
  return 3; // Desktop: three columns
    }
  }

  // Card dimensions
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile(context)) {
  return screenWidth - 32; // Mobile: 16px horizontal padding
    } else if (isTablet(context)) {
  return (screenWidth - 48) / 2; // Tablet: 2 columns with gap
    } else {
  return (screenWidth - 64) / 3; // Desktop: 3 columns
    }
  }

  // crossAxisCount for dashboard grid
  static int getDashboardGridCount(BuildContext context) {
    if (isMobile(context)) {
  return 2; // Mobile: 2x2 grid
    } else if (isTablet(context)) {
  return 3; // Tablet: 3x2 grid
    } else {
  return 4; // Desktop: 4x2 grid
    }
  }

  // Padding values
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  // AppBar height
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else {
      return kToolbarHeight + 8;
    }
  }

  // Font size scaling
  static double getFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
  return baseSize * 0.9; // Mobile: 90% size
    } else if (isTablet(context)) {
  return baseSize; // Tablet: normal size
    } else {
  return baseSize * 1.1; // Desktop: 110% size
    }
  }

  // Icon size scaling
  static double getIconSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize * 0.9;
    } else if (isTablet(context)) {
      return baseSize;
    } else {
      return baseSize * 1.2;
    }
  }

  // Navigation style
  static bool shouldUseBottomNavigation(BuildContext context) {
  return isMobile(context); // Use bottom nav only on mobile
  }

  // Drawer width
  static double getDrawerWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile(context)) {
  return screenWidth * 0.8; // Mobile: 80% of screen width
    } else if (isTablet(context)) {
  return 300; // Tablet: fixed 300px
    } else {
  return 350; // Desktop: fixed 350px
    }
  }

  // Dialog size
  static BoxConstraints getDialogConstraints(BuildContext context) {
    if (isMobile(context)) {
      return BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      );
    } else if (isTablet(context)) {
      return const BoxConstraints(
        maxWidth: 400,
        maxHeight: 600,
      );
    } else {
      return const BoxConstraints(
        maxWidth: 500,
        maxHeight: 700,
      );
    }
  }

  // Card spacing
  static double getCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12;
    } else if (isTablet(context)) {
      return 16;
    } else {
      return 20;
    }
  }

  // Button size
  static Size getButtonSize(BuildContext context) {
    if (isMobile(context)) {
      return const Size(double.infinity, 48);
    } else if (isTablet(context)) {
      return const Size(double.infinity, 52);
    } else {
      return const Size(double.infinity, 56);
    }
  }

  // Helper for breakpoint-based values
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }
}