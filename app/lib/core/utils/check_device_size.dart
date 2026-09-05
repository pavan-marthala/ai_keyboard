import 'package:material_ui/material_ui.dart';

import 'sized_context.dart';
import 'dimens.dart';

bool checkDesktopSize(BuildContext context) {
  return context.widthPx > Dimens.largeDeviceBreakPoint;
}

bool checkMediumDeviceSize(BuildContext context) {
  return context.widthPx > Dimens.mediumDeviceBreakPoint;
}

bool checkSmallDeviceSize(BuildContext context) {
  return context.widthPx < Dimens.smallDeviceBreakPoint;
}

bool checkVerySmallDeviceSize(BuildContext context) {
  return context.widthPx < Dimens.verySmallDeviceBreakPoint;
}
