import 'package:biometric_data_monitoring/providers/device_proceess.dart';
import 'package:biometric_data_monitoring/views/bio_statistics_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/hive/chart_data.dart';

class BioStatisticsView extends StatelessWidget {
  final List<ChartData> dbDatas;

  const BioStatisticsView({required this.dbDatas, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Bio Monitoring"),
      ),
      body: TestBarChart(
        temps: [],
        hearts: [],
        steps: [],
        dayType: DayType.day,
      ),
    );
  }
}

class TestBarChart extends StatelessWidget {
  final List<double> temps;
  final List<double> hearts;
  final List<double> steps;

  final DayType dayType;

  TestBarChart({
    required this.temps,
    required this.hearts,
    required this.steps,
    required this.dayType,
    super.key,
  });

  final _barsGradient = const LinearGradient(
    colors: [
      Color(0xff23b6e6),
      Color(0xff02d39a),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(
          top: 30, bottom: 20, start: 15, end: 16),
      child: BarChart(mainBarData()),
    );
  }

  BarChartData mainBarData() {
    return BarChartData(
      maxY: 50,
      barGroups: showingGroups(),
    );
  }

  int touchedIndex = -1;

  List<BarChartGroupData> showingGroups() {
    switch (dayType) {
      case DayType.day:
        var now = DateTime.now();

        int lastDay = DateTime(now.year, now.month + 1, 0, 0, 0).day;
        return List.generate(lastDay, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: 10,
                color: Colors.blueAccent,
                width: 7,
              ),
            ],
            barsSpace: 5.0,
          );
        });
      case DayType.month:
        // TODO: Handle this case.
        break;
      case DayType.year:
        // TODO: Handle this case.
        break;
    }

    return List.generate(7, (i) {
      switch (i) {
        case 0:
          return makeGroupData(0, 5, isTouched: i == touchedIndex);
        case 1:
          return makeGroupData(1, 6.5, isTouched: i == touchedIndex);
        case 2:
          return makeGroupData(2, 5, isTouched: i == touchedIndex);
        case 3:
          return makeGroupData(3, 7.5, isTouched: i == touchedIndex);
        case 4:
          return makeGroupData(4, 9, isTouched: i == touchedIndex);
        case 5:
          return makeGroupData(5, 11.5, isTouched: i == touchedIndex);
        case 6:
          return makeGroupData(6, 6.5, isTouched: i == touchedIndex);
        default:
          return throw Error();
      }
    });
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color barColor = Colors.white,
    double width = 22,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y,
          color: isTouched ? Colors.yellow : barColor,
          width: width,
          borderSide: isTouched
              ? BorderSide(color: Colors.yellow)
              : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: Colors.red,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }
}
