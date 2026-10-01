import 'package:flutter/material.dart';
import 'device_helper.dart';

extension ResponsiveUI on BuildContext {
  bool get isTv => DeviceHelper.isTelevision(this);

  // Dynamic padding based on device type
  double get defaultPadding => isTv ? 32.0 : 16.0;
  double get listItemPadding => isTv ? 24.0 : 12.0;

  // Dynamic typography scale
  double get titleTextSize => isTv ? 28.0 : 18.0;
  double get bodyTextSize => isTv ? 18.0 : 14.0;
}
