import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Biometric Data Monitoring",
      theme: ThemeData(primaryColor: Colors.blueAccent),
      home: const Home(),
    );
  }
}
