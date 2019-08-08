import 'dart:async';

import 'package:aves/model/image_entry.dart';
import 'package:aves/model/metadata_service.dart';
import 'package:aves/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class InfoPage extends StatefulWidget {
  final ImageEntry entry;

  const InfoPage({this.entry});

  @override
  State<StatefulWidget> createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  Future<Map> _metadataLoader;
  Future<CatalogMetadata> _catalogLoader;
  bool _scrollStartFromTop = false;

  ImageEntry get entry => widget.entry;

  @override
  void initState() {
    super.initState();
    initMetadataLoader();
  }

  @override
  void didUpdateWidget(InfoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    initMetadataLoader();
  }

  initMetadataLoader() {
    _catalogLoader = MetadataService.getCatalogMetadata(entry.contentId, entry.path).then((metadata) async {
      final latitude = metadata.latitude;
      final longitude = metadata.longitude;
      if (latitude != null && longitude != null) {
        final coordinates = Coordinates(latitude, longitude);
        final addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
        if (addresses != null && addresses.length > 0) {
          metadata.address = addresses.first;
        }
      }
      return metadata;
    });
    _metadataLoader = MetadataService.getAllMetadata(entry.path);
  }

  @override
  Widget build(BuildContext context) {
    final date = entry.bestDate;
    final dateText = '${DateFormat.yMMMd().format(date)} – ${DateFormat.Hm().format(date)}';
    final resolutionText = '${entry.width} × ${entry.height}${entry.isVideo ? '' : ' (${entry.megaPixels} MP)'}';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_upward),
          onPressed: () => BackUpNotification().dispatch(context),
          tooltip: 'Back to image',
        ),
        title: Text('Info'),
      ),
      body: NotificationListener(
        onNotification: (notification) {
          if (notification is ScrollNotification) {
            if (notification is ScrollStartNotification) {
              final metrics = notification.metrics;
              _scrollStartFromTop = metrics.pixels == metrics.minScrollExtent;
            }
            if (_scrollStartFromTop) {
              if (notification is ScrollEndNotification) {
                _scrollStartFromTop = false;
              } else if (notification is OverscrollNotification) {
                if (notification.overscroll < 0) {
                  BackUpNotification().dispatch(context);
                  _scrollStartFromTop = false;
                }
              }
            }
          }
          return false;
        },
        child: ListView(
          padding: EdgeInsets.all(8.0),
          children: [
            InfoRow('Title', entry.title),
            InfoRow('Date', dateText),
            if (entry.isVideo) InfoRow('Duration', entry.durationText),
            InfoRow('Resolution', resolutionText),
            InfoRow('Size', formatFilesize(entry.sizeBytes)),
            InfoRow('Path', entry.path),
            FutureBuilder(
              future: _catalogLoader,
              builder: (futureContext, AsyncSnapshot<CatalogMetadata> snapshot) {
                if (snapshot.hasError) return Text(snapshot.error);
                if (snapshot.connectionState != ConnectionState.done) return SizedBox.shrink();
                final metadata = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildLocationSection(metadata.latitude, metadata.longitude, metadata.address),
                    ..._buildTagSection(metadata.keywords),
                  ],
                );
              },
            ),
            FutureBuilder(
              future: _metadataLoader,
              builder: (futureContext, AsyncSnapshot<Map> snapshot) {
                if (snapshot.hasError) return Text(snapshot.error);
                if (snapshot.connectionState != ConnectionState.done) return SizedBox.shrink();
                final metadataMap = snapshot.data.cast<String, Map>();
                final directoryNames = metadataMap.keys.toList()..sort();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionRow('Metadata'),
                    ...directoryNames.expand(
                      (directoryName) {
                        final directory = metadataMap[directoryName];
                        final tagKeys = directory.keys.toList()..sort();
                        return [
                          if (directoryName.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(directoryName, style: TextStyle(fontSize: 18)),
                            ),
                          ...tagKeys.map((tagKey) => InfoRow(tagKey, directory[tagKey])),
                          SizedBox(height: 16),
                        ];
                      },
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLocationSection(double latitude, double longitude, Address address) {
    if (latitude == null || longitude == null) return [];
    final latLng = LatLng(latitude, longitude);
    return [
      SectionRow('Location'),
      SizedBox(
        height: 200,
        child: ClipRRect(
          borderRadius: BorderRadius.all(
            Radius.circular(16),
          ),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: latLng,
              zoom: 12,
            ),
            markers: [
              Marker(
                markerId: MarkerId(entry.path),
                icon: BitmapDescriptor.defaultMarker,
                position: latLng,
              )
            ].toSet(),
          ),
        ),
      ),
      if (address != null)
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: InfoRow('Address', address.addressLine),
        ),
    ];
  }

  List<Widget> _buildTagSection(String keywords) {
    if (keywords == null) return [];
    return [
      SectionRow('XMP Tags'),
      Wrap(
        children: keywords
            .split(' ')
            .where((word) => word.isNotEmpty)
            .map((word) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    backgroundColor: Colors.indigo,
                    label: Text(word),
                  ),
                ))
            .toList(),
      ),
    ];
  }
}

class SectionRow extends StatelessWidget {
  final String title;

  const SectionRow(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white70)),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(title, style: TextStyle(fontSize: 20)),
        ),
        Expanded(child: Divider(color: Colors.white70)),
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label, value;

  const InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label    ', style: TextStyle(color: Colors.white70)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class BackUpNotification extends Notification {}