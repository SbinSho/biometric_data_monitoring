import 'package:biometric_data_monitoring/color_schemes.g.dart';
import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'views/dash_board.dart';
import 'models/hive/hive_model.dart';

void main() async {
  await HiveModel.init();

  runApp(const Main());
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> with WidgetsBindingObserver {
  late final BioMonitoringProvider _bioMonitorProvder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bioMonitorProvder = BioMonitoringProvider();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Biometric Data Monitoring",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: darkColorScheme.onPrimaryContainer,
          ),
          titleLarge: TextStyle(
            color: darkColorScheme.onPrimaryContainer,
          ),
          titleMedium: TextStyle(
            color: darkColorScheme.onPrimaryContainer,
          ),
        ),
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _bioMonitorProvder),
        ],
        child: const DashBoardView(),
      ),
    );
  }
}
