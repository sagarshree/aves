import 'dart:collection';
import 'dart:typed_data';

import 'package:aves/model/image_entry.dart';
import 'package:aves/services/android_debug_service.dart';
import 'package:aves/utils/constants.dart';
import 'package:aves/widgets/common/identity/aves_expansion_tile.dart';
import 'package:aves/widgets/fullscreen/info/common.dart';
import 'package:flutter/material.dart';

class MetadataTab extends StatefulWidget {
  final ImageEntry entry;

  const MetadataTab({@required this.entry});

  @override
  _MetadataTabState createState() => _MetadataTabState();
}

class _MetadataTabState extends State<MetadataTab> {
  Future<Map> _bitmapFactoryLoader, _contentResolverMetadataLoader, _exifInterfaceMetadataLoader, _mediaMetadataLoader, _metadataExtractorLoader;

  // MediaStore timestamp keys
  static const secondTimestampKeys = ['date_added', 'date_modified', 'date_expires', 'isPlayed'];
  static const millisecondTimestampKeys = ['datetaken', 'datetime'];

  ImageEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  void _loadMetadata() {
    _bitmapFactoryLoader = AndroidDebugService.getBitmapFactoryInfo(entry);
    _contentResolverMetadataLoader = AndroidDebugService.getContentResolverMetadata(entry);
    _exifInterfaceMetadataLoader = AndroidDebugService.getExifInterfaceMetadata(entry);
    _mediaMetadataLoader = AndroidDebugService.getMediaMetadataRetrieverMetadata(entry);
    _metadataExtractorLoader = AndroidDebugService.getMetadataExtractorSummary(entry);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget builder(BuildContext context, AsyncSnapshot<Map> snapshot, String title) {
      if (snapshot.hasError) return Text(snapshot.error.toString());
      if (snapshot.connectionState != ConnectionState.done) return SizedBox.shrink();
      final data = SplayTreeMap.of(snapshot.data.map((k, v) {
        final key = k.toString();
        var value = v?.toString() ?? 'null';
        if ([...secondTimestampKeys, ...millisecondTimestampKeys].contains(key) && v is num && v != 0) {
          if (secondTimestampKeys.contains(key)) {
            v *= 1000;
          }
          value += ' (${DateTime.fromMillisecondsSinceEpoch(v)})';
        }
        if (key == 'xmp' && v != null && v is Uint8List) {
          value = String.fromCharCodes(v);
        }
        return MapEntry(key, value);
      }));
      return AvesExpansionTile(
        title: title,
        children: data.isNotEmpty
            ? [
                Padding(
                  padding: EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  child: InfoRowGroup(
                    data,
                    maxValueLength: Constants.infoGroupMaxValueLength,
                  ),
                )
              ]
            : null,
      );
    }

    return ListView(
      padding: EdgeInsets.all(8),
      children: [
        FutureBuilder<Map>(
          future: _bitmapFactoryLoader,
          builder: (context, snapshot) => builder(context, snapshot, 'Bitmap Factory'),
        ),
        FutureBuilder<Map>(
          future: _contentResolverMetadataLoader,
          builder: (context, snapshot) => builder(context, snapshot, 'Content Resolver'),
        ),
        FutureBuilder<Map>(
          future: _exifInterfaceMetadataLoader,
          builder: (context, snapshot) => builder(context, snapshot, 'Exif Interface'),
        ),
        FutureBuilder<Map>(
          future: _mediaMetadataLoader,
          builder: (context, snapshot) => builder(context, snapshot, 'Media Metadata Retriever'),
        ),
        FutureBuilder<Map>(
          future: _metadataExtractorLoader,
          builder: (context, snapshot) => builder(context, snapshot, 'Metadata Extractor'),
        ),
      ],
    );
  }
}
