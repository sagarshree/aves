import 'package:aves/theme/icons.dart';
import 'package:flutter/widgets.dart';

enum ChipSetAction {
  sort,
  refresh,
  stats,
}

enum ChipAction {
  delete,
  pin,
  unpin,
  rename,
}

extension ExtraChipAction on ChipAction {
  String getText() {
    switch (this) {
      case ChipAction.delete:
        return 'Delete';
      case ChipAction.pin:
        return 'Pin to top';
      case ChipAction.unpin:
        return 'Unpin from top';
      case ChipAction.rename:
        return 'Rename';
    }
    return null;
  }

  IconData getIcon() {
    switch (this) {
      case ChipAction.delete:
        return AIcons.delete;
      case ChipAction.pin:
      case ChipAction.unpin:
        return AIcons.pin;
      case ChipAction.rename:
        return AIcons.rename;
    }
    return null;
  }
}
