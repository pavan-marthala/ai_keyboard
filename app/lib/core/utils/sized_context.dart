import 'package:material_ui/material_ui.dart';

import 'dimens.dart';
import 'check_platforms.dart';

extension SizedContext on BuildContext {
  double get pixelsPerInch =>
      PlatformChecker.isAndroid() || PlatformChecker.isIOS() ? 150 : 96;

  /// Returns if Orientation is landscape
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Returns if Orientation is portrait
  bool get isPortrait => MediaQuery.orientationOf(this) == Orientation.portrait;

  /// Returns same as MediaQuery.of(context).size
  Size get sizePx => MediaQuery.sizeOf(this);

  /// Returns same as MediaQuery.of(context).size.width
  double get widthPx => sizePx.width;

  /// Returns same as MediaQuery.of(context).height
  double get heightPx => sizePx.height;

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  EdgeInsets get padding => MediaQuery.paddingOf(this);

  bool get isVerySmallScreen => heightPx <= 600;

  bool get isSmallScreen => heightPx >= 600 && heightPx <= 800;

  bool get isMediumScreen => heightPx >= 800 && heightPx < 1200;

  bool get isMobile => widthPx < 600;

  bool get isTablet => widthPx >= 600 && widthPx < 1024;

  bool get isDesktop => widthPx >= 1024;

  /// Returns pixel size in Inches
  Size get sizeInches {
    final Size pxSize = sizePx;
    return Size(pxSize.width / pixelsPerInch, pxSize.height / pixelsPerInch);
  }

  /// Returns screen width in Inches
  double get widthInches => sizeInches.width;

  /// Returns screen height in Inches
  double get heightInches => sizeInches.height;

  /// Returns fraction (0-1) of screen width in pixels
  double widthPct(double fraction) => fraction * widthPx;

  /// Returns fraction (0-1) of screen height in pixels
  double heightPct(double fraction) => fraction * heightPx;

  /// Return limited width in large size screens
  double get appMediaQuerySmallSizeWidth {
    if (MediaQuery.of(this).size.width > Dimens.mediumDeviceBreakPoint) {
      return Dimens.mediumDeviceBreakPoint;
    } else {
      return MediaQuery.of(this).size.width;
    }
  }

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
