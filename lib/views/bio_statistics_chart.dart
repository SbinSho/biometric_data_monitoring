import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/hive/chart_data.dart';
import 'bio_realtime_chart.dart';

class BarChart extends StatelessWidget {
  const BarChart({super.key});

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
      child: BarChart(),
    );
  }

  List<BarChartGroupData> barGroups() {
    return List.generate(3, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: 0,
            gradient: _barsGradient,
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }
}

class BioStaticsChart extends StatefulWidget {
  final List<ChartData> dbDatas;

  const BioStaticsChart({
    required this.dbDatas,
    super.key,
  });

  @override
  _BioStaticsChartState createState() => _BioStaticsChartState();
}

class _BioStaticsChartState extends State<BioStaticsChart> {
  final tempPoints = <FlSpot>[];
  final heartPoints = <FlSpot>[];
  final stepPoints = <FlSpot>[];

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    double xCount = 0.0;

    for (var data in widget.dbDatas) {
      tempPoints.add(FlSpot(xCount, data.temp));
      heartPoints.add(FlSpot(xCount, data.heart));
      stepPoints.add(FlSpot(xCount, data.step));
      xCount++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.all(10.0),
      child: Wrap(
        runSpacing: 50,
        children: [
          SizedBox(
            width: 300,
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TEMP",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
                Expanded(
                  child: LineChart(
                    _chartData(tempPoints, ChartType.temp),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 300,
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "HEART",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
                Expanded(
                  child: LineChart(
                    _chartData(heartPoints, ChartType.heart),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 300,
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "STEP",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
                Expanded(
                  child: LineChart(
                    _chartData(stepPoints, ChartType.step),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(List<FlSpot> points, ChartType chartType) {
    Color lineColor;
    double minY;
    double maxY;

    switch (chartType) {
      case ChartType.temp:
        lineColor = Colors.blueAccent;
        minY = 32.0;
        maxY = 40.0;

        break;
      case ChartType.heart:
        lineColor = Colors.redAccent;
        minY = 30.0;
        maxY = 150.0;
        break;
      case ChartType.step:
        lineColor = Colors.green;
        var convertY = _convertY(points, chartType);
        minY = convertY[0];
        maxY = convertY[1];
        break;
    }

    return LineChartData(
      minY: minY,
      maxY: maxY,
      minX: 0.0,
      maxX: points.isEmpty ? 0.0 : points.last.x,
      lineTouchData: LineTouchData(
        enabled: true,
        getTouchedSpotIndicator: (barData, spotIndexes) =>
            _buildTouchSpot(barData, spotIndexes, lineColor),
        touchTooltipData: _buildTouchData(points, lineColor),
      ),
      gridData: FlGridData(
        drawHorizontalLine: true,
      ),
      lineBarsData: _buildLine(points, lineColor),
      titlesData: _buildTitle(chartType, minY, maxY),
    );
  }

  List<LineChartBarData> _buildLine(List<FlSpot> points, Color lineColor) {
    final results = <LineChartBarData>[];

    results.add(
      LineChartBarData(
        spots: points,
        dotData: FlDotData(
          show: false,
        ),
        color: lineColor,
        barWidth: 2,
        isCurved: true,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lineColor.withOpacity(0.1), lineColor.withOpacity(0.1)],
          ),
        ),
      ),
    );

    return results;
  }

  FlTitlesData _buildTitle(ChartType chartType, double minY, double maxY) {
    return FlTitlesData(
      show: true,
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toString(),
              style: const TextStyle(
                color: Color(0xff68737d),
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          interval: 1,
          getTitlesWidget: (value, meta) =>
              _buildRightTitle(value, meta, chartType, minY, maxY),
        ),
      ),
    );
  }

  List<TouchedSpotIndicatorData?> _buildTouchSpot(
      LineChartBarData barData, List<int> spotIndexes, Color lineColor) {
    return spotIndexes.map((spotIndex) {
      return TouchedSpotIndicatorData(
        FlLine(color: lineColor, strokeWidth: 3),
        FlDotData(
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 10,
              color: lineColor,
              strokeWidth: 2,
              strokeColor: lineColor.withOpacity(.5),
            );
          },
        ),
      );
    }).toList();
  }

  LineTouchTooltipData _buildTouchData(List<FlSpot> points, Color lineColor) {
    return LineTouchTooltipData(
      tooltipBgColor: Colors.white,
      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
        return touchedBarSpots.map((barSpot) {
          final index = barSpot.x.toInt();

          return LineTooltipItem(
            points[index].y.toStringAsFixed(2),
            TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: lineColor,
            ),
            children: [
              TextSpan(
                text: "\n"
                    "${widget.dbDatas[index].getTime()}",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                  color: lineColor,
                ),
              ),
            ],
          );
        }).toList();
      },
    );
  }

  Widget _buildRightTitle(double value, TitleMeta meta, ChartType chartType,
      double minY, double maxY) {
    final titlesMap = <ChartType, double>{
      ChartType.temp: 36.0,
      ChartType.heart: 100.0,
      ChartType.step: maxY / 2.0,
    };

    if (minY == value || maxY == value || titlesMap[chartType] == value) {
      return Padding(
        padding: const EdgeInsets.only(left: 1.0),
        child: Text(
          value.toString(),
        ),
      );
    }

    return Container();
  }

  Map<String, double> _minMaxFind(double max, double min, List<double> data) {
    for (var element in data) {
      max = math.max(max, element);
      min = math.min(min, element);
    }

    return {'max': max, 'min': min};
  }

  List<double> _convertY(List<FlSpot> points, ChartType chartType) {
    final resultY = _minMaxFind(0, 0, [for (var e in points) e.y]);

    return [resultY["min"]!, resultY["max"]! + 100.0];
  }
}
