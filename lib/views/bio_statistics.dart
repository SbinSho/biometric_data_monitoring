import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:biometric_data_monitoring/providers/device_proceess.dart';

import 'package:flutter/material.dart';

import '../models/hive/user.dart';
import 'bio_statistics_chart.dart';

class BioStatisticsView extends StatefulWidget {
  final User user;
  final BioMonitoringProvider provider;

  const BioStatisticsView({
    required this.user,
    required this.provider,
    super.key,
  });

  @override
  State<BioStatisticsView> createState() => _BioStatisticsViewState();
}

class _BioStatisticsViewState extends State<BioStatisticsView> {
  late final DateTime now;
  late final BioMonitoringProvider provider;
  late List<Widget> _widgetOptions;

  List<double> dayTemps = [];
  List<double> dayHearts = [];
  List<double> daySteps = [];

  List<double> monthTemps = [];
  List<double> monthHearts = [];
  List<double> monthSteps = [];

  List<double> yearTemps = [];
  List<double> yearHearts = [];
  List<double> yearSteps = [];

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    now = DateTime.now();

    provider = widget.provider;

    for (var value in DayType.values) {
      for (var element in provider.getBioDatas(widget.user, value, now)) {
        var count = element[0];
        var temp = element[1] == 0.0 ? 0.0 : element[1] / count;
        var heart = element[2] == 0.0 ? 0.0 : element[2] / count;
        var step = element[3] == 0.0 ? 0.0 : element[3] / count;

        switch (value) {
          case DayType.day:
            dayTemps.add(temp);
            dayHearts.add(heart);
            daySteps.add(step);
            break;
          case DayType.month:
            monthTemps.add(temp);
            monthHearts.add(heart);
            monthSteps.add(step);
            break;
          case DayType.year:
            yearTemps.add(temp);
            yearHearts.add(heart);
            yearSteps.add(step);
            break;
        }
      }
    }

    _widgetOptions = <Widget>[
      BioStatisticsChart(
        dayType: DayType.day,
        temps: dayTemps,
        hearts: dayHearts,
        steps: daySteps,
      ),
      BioStatisticsChart(
        dayType: DayType.month,
        temps: monthTemps,
        hearts: monthHearts,
        steps: monthSteps,
      ),
      BioStatisticsChart(
        dayType: DayType.year,
        temps: yearTemps.reversed.toList(),
        hearts: yearHearts.reversed.toList(),
        steps: yearSteps.reversed.toList(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("일월년별 평균"),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black45,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.date_range),
            label: '일',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.date_range),
            label: '월',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.date_range),
            label: '년',
          ),
        ],
        currentIndex: _selectedIndex, // 지정 인덱스로 이동
        selectedItemColor: Colors.lightGreen,
        onTap: _onItemTapped, // 선언했던 onItemTapped
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
