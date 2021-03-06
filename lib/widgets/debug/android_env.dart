import 'dart:collection';

import 'package:aves/services/android_debug_service.dart';
import 'package:aves/widgets/common/identity/aves_expansion_tile.dart';
import 'package:aves/widgets/fullscreen/info/common.dart';
import 'package:flutter/material.dart';

class DebugAndroidEnvironmentSection extends StatefulWidget {
  @override
  _DebugAndroidEnvironmentSectionState createState() => _DebugAndroidEnvironmentSectionState();
}

class _DebugAndroidEnvironmentSectionState extends State<DebugAndroidEnvironmentSection> with AutomaticKeepAliveClientMixin {
  Future<Map> _loader;

  @override
  void initState() {
    super.initState();
    _loader = AndroidDebugService.getEnv();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AvesExpansionTile(
      title: 'Android Environment',
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
          child: FutureBuilder<Map>(
            future: _loader,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text(snapshot.error.toString());
              if (snapshot.connectionState != ConnectionState.done) return SizedBox.shrink();
              final data = SplayTreeMap.of(snapshot.data.map((k, v) => MapEntry(k.toString(), v?.toString() ?? 'null')));
              return InfoRowGroup(data);
            },
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
