import 'package:aves/model/collection_lens.dart';
import 'package:aves/model/filters/country.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/model/filters/tag.dart';
import 'package:aves/model/image_entry.dart';
import 'package:aves/utils/color_utils.dart';
import 'package:aves/utils/constants.dart';
import 'package:aves/widgets/album/collection_page.dart';
import 'package:aves/widgets/common/aves_filter_chip.dart';
import 'package:aves/widgets/common/data_providers/media_query_data_provider.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class StatsPage extends StatelessWidget {
  final CollectionLens collection;
  final Map<String, int> entryCountPerCountry = Map<String, int>(), entryCountPerTag = Map<String, int>();

  StatsPage({this.collection}) {
    entries.forEach((entry) {
      final country = entry.addressDetails?.countryName;
      if (country != null) {
        entryCountPerCountry[country] = (entryCountPerCountry[country] ?? 0) + 1;
      }
      entry.xmpSubjects.forEach((tag) {
        entryCountPerTag[tag] = (entryCountPerTag[tag] ?? 0) + 1;
      });
    });
  }

  List<ImageEntry> get entries => collection.sortedEntries;

  @override
  Widget build(BuildContext context) {
    final catalogued = entries.where((entry) => entry.isCatalogued);
    final withGps = catalogued.where((entry) => entry.hasGps);
    final withGpsPercent = withGps.length / collection.entryCount;
    final Map<String, int> byMimeTypes = groupBy(entries, (entry) => entry.mimeType).map((k, v) => MapEntry(k, v.length));
    final imagesByMimeTypes = Map.fromEntries(byMimeTypes.entries.where((kv) => kv.key.startsWith('image/')));
    final videoByMimeTypes = Map.fromEntries(byMimeTypes.entries.where((kv) => kv.key.startsWith('video/')));
    return MediaQueryDataProvider(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stats'),
        ),
        body: SafeArea(
          child: ListView(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  _buildMimePie(context, (sum) => Intl.plural(sum, one: 'image', other: 'images'), imagesByMimeTypes),
                  _buildMimePie(context, (sum) => Intl.plural(sum, one: 'video', other: 'videos'), videoByMimeTypes),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearPercentIndicator(
                      percent: withGpsPercent,
                      lineHeight: 16,
                      backgroundColor: Colors.white24,
                      progressColor: Theme.of(context).accentColor,
                      animation: true,
                      leading: const Icon(OMIcons.place),
                      // right padding to match leading, so that inside label is aligned with outside label below
                      padding: const EdgeInsets.symmetric(horizontal: 16) + const EdgeInsets.only(right: 24),
                      center: Text(NumberFormat.percentPattern().format(withGpsPercent)),
                    ),
                    const SizedBox(height: 8),
                    Text('${withGps.length} ${Intl.plural(withGps.length, one: 'item', other: 'items')} with location'),
                  ],
                ),
              ),
              ..._buildTopFilters(context, 'Top countries', entryCountPerCountry, (s) => CountryFilter(s)),
              ..._buildTopFilters(context, 'Top tags', entryCountPerTag, (s) => TagFilter(s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMimePie(BuildContext context, String Function(num) label, Map<String, num> byMimeTypes) {
    if (byMimeTypes.isEmpty) return const SizedBox.shrink();

    final sum = byMimeTypes.values.fold(0, (prev, v) => prev + v);

    final seriesData = byMimeTypes.entries.map((kv) => StringNumDatum(kv.key.replaceFirst(RegExp('.*/'), '').toUpperCase(), kv.value)).toList();
    seriesData.sort((kv1, kv2) {
      final c = kv2.value.compareTo(kv1.value);
      return c != 0 ? c : compareAsciiUpperCase(kv1.key, kv2.key);
    });

    final series = [
      charts.Series<StringNumDatum, String>(
        id: 'mime',
        colorFn: (d, i) => charts.ColorUtil.fromDartColor(stringToColor(d.key)),
        domainFn: (d, i) => d.key,
        measureFn: (d, i) => d.value,
        data: seriesData,
        labelAccessorFn: (d, _) => '${d.key}: ${d.value}',
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      var mq = MediaQuery.of(context);
      final dim = constraints.maxWidth / (mq.orientation == Orientation.portrait ? 2 : 4);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dim,
            height: dim,
            child: Stack(
              children: [
                charts.PieChart(
                  series,
                  defaultRenderer: charts.ArcRendererConfig(
                    arcWidth: 16,
                  ),
                ),
                Center(
                  child: Text(
                    '${sum}\n${label(sum)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: dim,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: seriesData
                    .map((kv) => Row(
                          children: [
                            Icon(Icons.fiber_manual_record, color: stringToColor(kv.key)),
                            const SizedBox(width: 8),
                            Text(kv.key),
                            const SizedBox(width: 8),
                            Text('${kv.value}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ))
                    .toList()),
          ),
        ],
      );
    });
  }

  List<Widget> _buildTopFilters(BuildContext context, String title, Map<String, int> entryCountMap, FilterBuilder filterBuilder) {
    if (entryCountMap.isEmpty) return [];

    final maxCount = collection.entryCount;
    final sortedEntries = entryCountMap.entries.toList()
      ..sort((kv1, kv2) {
        final c = kv2.value.compareTo(kv1.value);
        return c != 0 ? c : compareAsciiUpperCase(kv1.key, kv2.key);
      });
    return [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          title,
          style: Constants.titleTextStyle,
        ),
      ),
      Padding(
        padding: const EdgeInsetsDirectional.only(start: AvesFilterChip.buttonBorderWidth / 2 + 6, end: 8),
        child: Table(
          children: sortedEntries.take(5).map((kv) {
            final label = kv.key;
            final count = kv.value;
            final percent = count / maxCount;
            return TableRow(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AvesFilterChip(
                    filter: filterBuilder(label),
                    onPressed: (filter) => _goToFilteredCollection(context, filter),
                  ),
                ),
                Expanded(
                  child: LinearPercentIndicator(
                    percent: percent,
                    lineHeight: 16,
                    backgroundColor: Colors.white24,
                    progressColor: stringToColor(label),
                    animation: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    center: Text(NumberFormat.percentPattern().format(percent)),
                  ),
                ),
                Text(
                  '${count}',
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.end,
                ),
              ],
            );
          }).toList(),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            2: IntrinsicColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        ),
      ),
    ];
  }

  void _goToFilteredCollection(BuildContext context, CollectionFilter filter) {
    if (collection == null) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionPage(collection.derive(filter)),
      ),
      (route) => false,
    );
  }
}

class StringNumDatum {
  final String key;
  final num value;

  const StringNumDatum(this.key, this.value);

  @override
  String toString() {
    return '[$runtimeType#$hashCode: key=$key, value=$value]';
  }
}