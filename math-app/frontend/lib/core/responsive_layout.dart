import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveLayout {
  ResponsiveLayout._();

  static bool get isDesktop {
    if (kIsWeb) return true;
    return false;
  }

  static bool get isMobile => !isDesktop;

  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return isDesktop ? 1440 : w;
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    if (isDesktop) {
      return EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 1440 ? 48 : 24,
        vertical: 32,
      );
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 32);
  }

  static Widget buildResponsive({
    required BuildContext context,
    required Widget mobile,
    required Widget desktop,
  }) {
    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: desktop,
        ),
      );
    }
    return mobile;
  }
}
