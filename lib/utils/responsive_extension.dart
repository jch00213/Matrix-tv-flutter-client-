import 'package:flutter/widgets.dart';

extension ResponsiveExtension on BuildContext {
  /// Simple heuristic to detect TV screens based on screen width
  bool get isTv {
    final size = MediaQuery.of(this).size;
    // TVs generally have a much larger layout width (e.g., 900dp+)
    return size.width > 900;
  }

  /// Scales padding dynamically depending on whether it's a TV or mobile screen
  double get defaultPadding => isTv ? 32.0 : 16.0;

  /// Specific padding for list items or cards
  double get listItemPadding => isTv ? 24.0 : 16.0;

  /// Scales body font size for readability on TV versus mobile
  double get bodyTextSize => isTv ? 18.0 : 14.0;

  /// Scales title font size for headers and titles
  double get titleTextSize => isTv ? 22.0 : 16.0;
}
