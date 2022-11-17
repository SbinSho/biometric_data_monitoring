import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'dash_board.dart';
import 'models/hive_model.dart';

void main() async {
  await HiveModel.init();

  runApp(const Main());
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  late final BioMonitoringProvider _bioMonitorProvder;

  @override
  void initState() {
    super.initState();

    _bioMonitorProvder = BioMonitoringProvider();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Biometric Data Monitoring",
      theme: ThemeData(primaryColor: Colors.blueAccent),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _bioMonitorProvder),
        ],
        child: const DashBoard(),
      ),
    );
  }
}
