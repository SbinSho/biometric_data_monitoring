import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../providers/device_proceess.dart';
import 'bio_realtime_chart.dart';

import 'dart:math' as math;

class BioStatisticsChart extends StatelessWidget {
  final List<double> temps;
  final List<double> hearts;
  final List<double> steps;

  final DayType dayType;

  const BioStatisticsChart({
    required this.temps,
    required this.hearts,
    required this.steps,
    required this.dayType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(
          top: 30, bottom: 20, start: 15, end: 16),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "TEMP",
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Expanded(child: BarChart(mainBarData(temps, ChartType.temp))),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "HEART",
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Expanded(child: BarChart(mainBarData(hearts, ChartType.heart))),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "STEP",
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Expanded(child: BarChart(mainBarData(steps, ChartType.step))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartData mainBarData(List<double> datas, ChartType chartType) {
    double maxFind(double max, List<double> data) {
      for (var element in data) {
        max = math.max(max, element);
      }

      return max;
    }

    var max = 0.0;

    max = maxFind(max, datas);

    ColorSwatch<int> lineColor;

    switch (chartType) {
      case ChartType.temp:
        lineColor = Colors.blueAccent;
        break;
      case ChartType.heart:
        lineColor = Colors.redAccent;
        break;
      case ChartType.step:
        lineColor = Colors.green;
        break;
    }

    Widget Function(double value, TitleMeta meta) bottomTitles;

    switch (dayType) {
      case DayType.day:
        bottomTitles = _dayBottomTitles;
        break;
      case DayType.month:
        bottomTitles = _monthBottomTitles;
        break;
      case DayType.year:
        bottomTitles = _yearBottomTitles;
        break;
    }

    return BarChartData(
      maxY: max + 5.0,
      barGroups: _groups(datas, lineColor),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: lineColor,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              "${group.barRods[0].toY.toStringAsFixed(2)}\n",
              const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: _buildSpan(groupIndex),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                    fontSize: 9,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: bottomTitles,
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _groups(List<double> datas, Color lineColor) {
    return List.generate(datas.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: datas[index],
            color: lineColor,
            width: 5,
          ),
        ],
      );
    });
  }

  String _buildSpan(int groupIndex) {
    switch (dayType) {
      case DayType.day:
        return "${(groupIndex + 1)}일";
      case DayType.month:
        return "${(groupIndex + 1)}월";

      case DayType.year:
        var now = DateTime.now();
        var year = now.year - 2;

        return "${year + groupIndex}년";
    }
  }

  Widget _dayBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Color(0xff939393), fontSize: 10);
    String text = "";
    int valueToInt = value.toInt();

    int lastDay = _getLastDay();

    if (valueToInt == 0) {
      return const Text("1일", style: style);
    } else if (valueToInt == 14) {
      text = "15일";
    } else if (valueToInt + 1 == lastDay) {
      text = "$lastDay 일";
    }

    return Center(child: Text(text, style: style));
  }

  Widget _monthBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Color(0xff939393), fontSize: 10);
    String text = "";
    int valueToInt = value.toInt();

    int lastIndex = temps.length;

    if (valueToInt == 0) {
      return const Center(child: Text("1월", style: style));
    } else if (valueToInt == 5) {
      text = "6월";
    } else if (valueToInt + 1 == lastIndex) {
      text = "$lastIndex월";
    }

    return Center(child: Text(text, style: style));
  }

  Widget _yearBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Color(0xff939393), fontSize: 10);

    int valueToInt = value.toInt();
    var now = DateTime.now();
    var year = now.year - 2;

    valueToInt = year + valueToInt;

    return Center(child: Text(valueToInt.toString(), style: style));
  }

  int _getLastDay() {
    var now = DateTime.now();

    return DateTime(now.year, now.month + 1, 0, 0, 0).day;
  }
}
