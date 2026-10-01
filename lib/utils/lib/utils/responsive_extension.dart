import 'package:flutter/widgets.dart';

extension ResponsiveExtension on BuildContext {
  /// Simple heuristic to detect TV screens based on screen width
  bool get isTv {
    final size = MediaQuery.of(this).size;
    // TVs generally have a much larger layout width (e.g., 960dp+ or 1280dp+)
    return size.width > 900;
  }

  /// Scales padding dynamically depending on whether it's a TV or mobile screen
  double get defaultPadding => isTv ? 32.0 : 16.0;

  /// Scales body font size for readability on TV versus mobile
  double get bodyTextSize => isTv ? 18.0 : 14.0;
}
