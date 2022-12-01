import 'package:biometric_data_monitoring/color_schemes.g.dart';
import 'package:biometric_data_monitoring/models/hive/background_controller.dart';
import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

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
    BackgroundController.initForegroundTask();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _bioMonitorProvder.onDidChangeAppLifecycleState(state, refresh);
  }

  void refresh() => setState(() {});

  @override
  void dispose() async {
    super.dispose();
    _bioMonitorProvder.dispose();
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
      home: WithForegroundTask(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _bioMonitorProvder),
          ],
          child: const DashBoardView(),
        ),
      ),
    );
  }
}
