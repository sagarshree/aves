import 'package:aves/widgets/common/identity/highlight_title.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';

class AvesExpansionTile extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;
  final ValueNotifier<String> expandedNotifier;

  const AvesExpansionTile({
    @required this.title,
    this.color,
    this.expandedNotifier,
    @required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = children?.isNotEmpty == true;
    return Theme(
      data: Theme.of(context).copyWith(
        // color used by the `ExpansionTileCard` for selected text and icons
        accentColor: Colors.white,
      ),
      child: ExpansionTileCard(
        key: Key('tilecard-$title'),
        value: title,
        expandedNotifier: expandedNotifier,
        title: HighlightTitle(
          title,
          color: color,
          fontSize: 18,
          enabled: enabled,
        ),
        expandable: enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(thickness: 1, height: 1),
            SizedBox(height: 4),
            if (enabled) ...children,
          ],
        ),
        baseColor: Colors.grey[900],
        expandedColor: Colors.grey[850],
      ),
    );
  }
}
