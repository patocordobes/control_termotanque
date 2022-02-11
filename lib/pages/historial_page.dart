import 'dart:async';
import 'dart:convert';

import 'package:control_termotanque/models/device_model.dart';
import 'package:control_termotanque/models/message_manager_model.dart';
import 'package:control_termotanque/models/point_model.dart';
import 'package:control_termotanque/repository/models_repository.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:provider/provider.dart';

class OrdinalComboBarLineChart extends StatefulWidget {
  final bool animate;
  final String title;
  OrdinalComboBarLineChart({required this.animate, required this.title});
  @override
  _OrdinalComboBarLineChartState createState() => _OrdinalComboBarLineChartState();
}

class _OrdinalComboBarLineChartState extends State<OrdinalComboBarLineChart> {
  List<charts.Series<dynamic, String>> seriesList = [];
  late MessageManager messageManager;
  ModelsRepository modelsRepository = ModelsRepository();
  late Device device;
  List<Point> points = [];
  DateTime _date = DateTime.now();
  int i = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState(){
    super.initState();

    messageManager = context.read<MessageManager>();
    device = messageManager.selectedDevice;

    modelsRepository.deletePoints(device: device);
    refresh();

  }
  @override
  void dispose(){
    super.dispose();
  }
  void refresh() async {
    if (_date.day == DateTime.now().day && _date.month == DateTime.now().month && _date.year == DateTime.now().year ){
      setState(() {
        this.points = device.todayPoints;
      });
      if (device.todayPoints.length != DateTime.now().hour + 1) {
        Map <String, dynamic> map = {
          "t": "devices/" + device.mac.toUpperCase().substring(3),
          "a": "geth",
          "d": {"day": _date.day}
        };
        messageManager.send(jsonEncode(map), true);
        setState(() {
          device.deviceStatus = DeviceStatus.updating;
          device.historicalStatus = HistoricalStatus.updating;
        });
        await Future.delayed(Duration(seconds: 4),);
        setState(() {
          this.points = device.todayPoints;
          device.deviceStatus = DeviceStatus.updated;
          device.historicalStatus = HistoricalStatus.done;
        });
        refresh();

      }else{
        print("ya estan todas las horas disponibles");
      }
    }else {
      modelsRepository.getPoints(device: device, dateTime: _date).then((
          points) async {
        setState(() {
          this.points = points;
          device.deviceStatus = DeviceStatus.updated;
          device.historicalStatus = HistoricalStatus.done;
        });
        print("cantidad de puntos encontrados " + points.length.toString());
        print(_date.toString());
        if (points.isEmpty) {
          if (DateTime(DateTime
              .now()
              .year, DateTime
              .now()
              .month - 1, DateTime
              .now()
              .day + 1).isAfter(_date)) {
            showDialog(context: context, builder: (_) {
              return AlertDialog(
                title: Text("Error"),
                content: Text("Esta fecha ya no se puede solicictar."),
                actions: [
                  TextButton(
                    child: Text("ACEPTAR"),
                    onPressed: () {
                      setState(() {
                        this.points = [];
                        device.deviceStatus = DeviceStatus.updated;
                        device.historicalStatus = HistoricalStatus.done;
                      });
                      Navigator.of(context).pop();
                    },
                  )
                ],

              );
            });
          } else {
            Map <String, dynamic> map = {
              "t": "devices/" + device.mac.toUpperCase().substring(3),
              "a": "geth",
              "d": {"day": _date.day}
            };
            messageManager.send(jsonEncode(map), true);
            setState(() {
              device.deviceStatus = DeviceStatus.updating;
              device.historicalStatus = HistoricalStatus.updating;
            });
            await Future.delayed(Duration(seconds: 4),);

            refresh();
          }
        }
      }, onError: (e) {
        print(e);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: (){
            Navigator.of(context).pushNamed("/settings");
          }),
          IconButton(icon: Icon(Icons.refresh), onPressed: (){
            refresh();
          }),
        ],

      ),
      body: SingleChildScrollView(
        child: IntrinsicHeight(
          child: Column(
            children: [
              (device.historicalStatus == HistoricalStatus.updating)? LinearProgressIndicator(): Container(),
              Form(
                key: _formKey,
                child: Expanded(
                  child: DatePickerFormField(
                    onSaved: (value) {
                      setState(() {
                        _date = value!;
                      });print("intentando");
                    },
                    validator:(val){
                      if (val == null){
                        return "Debe ingresar una fecha.";
                      }
                      _date = val;
                    },
                    context: context,
                    initialDateTime: _date,
                    enabled: (device.historicalStatus == HistoricalStatus.updating)? false: true,
                    onChanged: (){
                      if (_formKey.currentState!.validate()) {
                        refresh();
                      }
                    },
                  ),
                ),
              ),
              Center(
                child: Container(
                  height: 400,
                  width: MediaQuery.of(context).size.width -14,
                  child: charts.OrdinalComboChart(_createSampleData(),

                    behaviors: [
                      new charts.SeriesLegend(position: charts.BehaviorPosition.bottom),
                    ],

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
              ),
            ],
          ),
        ),
      )
    );
  }
  /// Create series list with multiple series
  List<charts.Series<Point, String>> _createSampleData() {

    return [
      new charts.Series<Point, String>(
        id: 'Resistencia-Minutos',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault.lighter,
        domainFn: (Point point, _) => point.dateTime.hour.toString(),
        measureFn: (Point point, _) => point.resistanceTime,
        data: this.points,

      ),
      new charts.Series<Point, String>(
        id: 'Temperatura ',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (Point point, _) => point.dateTime.hour.toString(),
        measureFn: (Point point, _) => point.temperature,
        data: this.points,
      )
      // Configure our custom line renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customLine'),
    ];
  }
}
class DatePickerFormField extends FormField<DateTime> {

  DatePickerFormField({
    required FormFieldSetter<DateTime> onSaved,
    required FormFieldValidator<DateTime> validator,
    required DateTime initialDateTime,
    required BuildContext context,
    required bool enabled,
    required VoidCallback onChanged

  }) : super(
      onSaved: onSaved,
      validator: validator,
      initialValue: initialDateTime,
      builder: (FormFieldState<DateTime> state) {
        return ListTile(
          enabled: enabled,
          leading:const Icon(Icons.date_range),
          title: Text("Dia del grafico"),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${state.value!.year}-${state.value!.month}-${state.value!.day}"),
              Text("${(state.errorText == null) ?'': state.errorText}",style:TextStyle(color: Theme.of(context).errorColor)),
            ],
          ),

          onTap: () async{
            DateTime? date = DateTime(1900);
            FocusScope.of(context).requestFocus(new FocusNode());

            date = await showDatePicker(
                context: context,
                initialDate: state.value!,
                firstDate: DateTime(DateTime.now().year-10),
                lastDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
            );
            if (date == null){
              date = state.value!;
            }
            state.didChange(date);
            onChanged();
          },
        );
      }
  );
}