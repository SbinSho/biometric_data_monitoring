import 'package:biometric_data_monitoring/views/bio_statistics_chart.dart';
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
      body: SingleChildScrollView(child: BioStaticsChart(dbDatas: dbDatas)),
    );
  }
}
