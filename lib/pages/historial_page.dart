import 'package:control_termotanque/models/device_model.dart';
import 'package:control_termotanque/models/point_model.dart';
/// Example of an ordinal combo chart with two series rendered as bars, and a
/// third rendered as a line.
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class OrdinalComboBarLineChart extends StatefulWidget {

  final bool animate;
  final Device device;
  final String title;

  OrdinalComboBarLineChart({required this.animate, required this.device, required this.title});


  @override
  _OrdinalComboBarLineChartState createState() => _OrdinalComboBarLineChartState();


}

class _OrdinalComboBarLineChartState extends State<OrdinalComboBarLineChart> {
  List<charts.Series<dynamic, String>> seriesList = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: (){
            Navigator.of(context).pushNamed("/settings");
          }),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: charts.OrdinalComboChart(_createSampleData(),

            animate: widget.animate,
            // Configure the default renderer as a bar renderer.
            defaultRenderer: charts.BarRendererConfig(
                groupingType: charts.BarGroupingType.grouped
            ),
            // Custom renderer configuration for the line series. This will be used for
            // any series that does not define a rendererIdKey.
            customSeriesRenderers: [
              new charts.LineRendererConfig(

                // ID used to link series to this renderer.
                  customRendererId: 'customLine')
            ],

          ),
        ),
      )
    );
  }
  /// Create series list with multiple series
  static List<charts.Series<Point, String>> _createSampleData() {
    final points = [
      new Point(deviceId: 3, temperature: 34, resistanceTime: 0, dateTime: DateTime.parse("2021-10-13 00:00:00") ),
      new Point(deviceId: 3, temperature: 56, resistanceTime: 20, dateTime: DateTime.parse("2021-10-13 01:00:00")),
      new Point(deviceId: 3, temperature: 60, resistanceTime: 10, dateTime: DateTime.parse("2021-10-13 02:00:00")),
      new Point(deviceId: 3, temperature: 100, resistanceTime: 60, dateTime: DateTime.parse("2021-10-13 03:00:00")),
    ];

    return [
      new charts.Series<Point, String>(
        id: 'Desktop',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (Point point, _) => point.dateTime.hour.toString(),
        measureFn: (Point point, _) => point.resistanceTime,
        data: points,


      ),
      new charts.Series<Point, String>(
        id: 'Mobile ',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (Point point, _) => point.dateTime.hour.toString(),
        measureFn: (Point point, _) => point.temperature,
        data: points,
      )
      // Configure our custom line renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customLine'),
    ];
  }
}