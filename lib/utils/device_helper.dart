import 'package:flutter/widgets.dart';

class DeviceHelper {
  static bool isTV(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    // Android TVs are typically landscape-first, wider screens, and often use directional navigation
    return data.size.width > 900 && data.navigationMode == NavigationMode.directional;
  }

  // Alternative fallback or explicit check using screen aspect ratio/width bounds
  static bool isTelevision(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Standard TV layout threshold (most TVs are 720p/1080p/4K landscape)
    return size.aspectRatio > 1.5 && size.width >= 960;
  }
}
