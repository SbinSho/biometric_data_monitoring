import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/hive/chart_data.dart';

enum ChartType {
  temp,
  heart,
  step,
}

class BioRealtimeChart extends StatefulWidget {
  final Stream<ChartData>? dataStream;
  final ChartType chartType;
  final List<ChartData> initalDatas;

  const BioRealtimeChart({
    required this.dataStream,
    required this.chartType,
    required this.initalDatas,
    super.key,
  });

  @override
  State<BioRealtimeChart> createState() => _BioRealtimeChartState();
}

class _BioRealtimeChartState extends State<BioRealtimeChart> {
  late Color lineColor;

  late double minY;
  late double maxY;

  List<FlSpot> points = [];
  List<ChartData> chartDatas = [];

  double xCount = 0.0;

  double? _lastData;
  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    if (widget.initalDatas.isNotEmpty) {
      chartDatas.addAll(widget.initalDatas);

      for (var element in chartDatas) {
        points.add(
          FlSpot(xCount, _dataFiltering(element)),
        );

        xCount++;
      }
      _lastData = _dataFiltering(chartDatas.last);
      _lastSyncTime = chartDatas.last.getTime();
    }

    switch (widget.chartType) {
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
        minY = 0;
        maxY = 10000;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChartData>(
      stream: widget.dataStream,
      builder: (context, snapshot) {
        if (snapshot.data == null && chartDatas.isEmpty) {
          return SizedBox(
            width: 300,
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chartType.toString().split(".").last.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 30,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text("수집 된 데이터가 존재하지 않습니다."),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.data != null) {
          _lastData = _dataFiltering(snapshot.data!);
          _lastSyncTime = snapshot.data!.getTime();

          if (chartDatas.length > 30) {
            chartDatas.removeAt(0);
            chartDatas.add(snapshot.data!);

            var results = <FlSpot>[];

            points.removeAt(0);
            for (var element in points) {
              results.add(FlSpot(element.x - 1.0, element.y));
            }
            results.add(FlSpot(xCount.toDouble(), _lastData!));
            points = results;
          } else {
            chartDatas.add(snapshot.data!);
            points.add(FlSpot(xCount.toDouble(), _lastData!));
            xCount = xCount + 1.0;
          }
        }

        return SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.chartType.toString().split(".").last.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 30,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "DATA : ${_lastData ?? ""}",
                        style: TextStyle(
                          fontSize: 21,
                          color: lineColor,
                        ),
                      ),
                      Text("last time : ${_lastSyncTime ?? ""}"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              Expanded(
                child: LineChart(
                  _chartData(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LineChartData _chartData() {
    _convertY();

    return LineChartData(
      minY: minY,
      maxY: maxY,
      minX: 0.0,
      maxX: points.isEmpty ? 0.0 : points.last.x,
      lineTouchData: LineTouchData(
        enabled: true,
        getTouchedSpotIndicator: _buildTouchSpot,
        touchTooltipData: _buildTouchData(),
      ),
      gridData: FlGridData(
        drawHorizontalLine: true,
      ),
      lineBarsData: _buildLine(),
      titlesData: _buildTitle(),
    );
  }

  List<LineChartBarData> _buildLine() {
    final results = <LineChartBarData>[];

    results.add(
      LineChartBarData(
        spots: points,
        dotData: FlDotData(
          show: false,
        ),
        color: lineColor,
        barWidth: 2,
        isCurved: false,
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

  FlTitlesData _buildTitle() {
    return FlTitlesData(
      show: true,
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          interval: 1,
          getTitlesWidget: _buildRightTitle,
        ),
      ),
    );
  }

  List<TouchedSpotIndicatorData?> _buildTouchSpot(
      LineChartBarData barData, List<int> spotIndexes) {
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

  LineTouchTooltipData _buildTouchData() {
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
                    "${chartDatas[index].getTime()}",
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

  Widget _buildRightTitle(double value, TitleMeta meta) {
    final titlesMap = <ChartType, double>{
      ChartType.temp: 36.0,
      ChartType.heart: 100.0,
      ChartType.step: maxY / 2.0,
    };

    if (minY == value ||
        maxY == value ||
        titlesMap[widget.chartType] == value) {
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

  void _convertY() {
    if (widget.chartType == ChartType.step) {
      final resultY = _minMaxFind(0, 0, [for (var e in points) e.y]);
      minY = resultY["min"]!;
      maxY = resultY["max"]! + 100.0;
    }
  }

  double _dataFiltering(ChartData chartData) {
    switch (widget.chartType) {
      case ChartType.temp:
        if (chartData.temp <= 32) {
          break;
        }
        return chartData.temp;
      case ChartType.heart:
        if (chartData.heart <= 30) {
          break;
        }
        return chartData.heart;
      case ChartType.step:
        if (chartData.step < 0) {
          break;
        }
        return chartData.step;
    }

    return points.last.y;
  }
}
