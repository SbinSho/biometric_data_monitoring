import 'dart:async';

import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:biometric_data_monitoring/views/register.dart';
import 'package:biometric_data_monitoring/views/user_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashBoardView extends StatefulWidget {
  const DashBoardView({super.key});

  @override
  State<DashBoardView> createState() => _DashBoardViewState();
}

class _DashBoardViewState extends State<DashBoardView> {
  late final BioMonitoringProvider _bioMonitorProvider;

  // Text Widget
  final dialogTitle = const Text("사용자 등록");
  final register = const Text("등록");
  final cancle = const Text('취소', style: TextStyle(color: Colors.red));

  final userTiles = <Widget>[];

  @override
  void initState() {
    super.initState();

    _bioMonitorProvider =
        Provider.of<BioMonitoringProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    userTiles.clear();

    for (var name in _bioMonitorProvider.loadUsers()) {
      userTiles.add(UserTile(userName: name));
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Bio Monitoring"),
      ),
      body: ListView(
        children: userTiles,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RegisterView(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
