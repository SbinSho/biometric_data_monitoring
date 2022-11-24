import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../models/hive/hive_model.dart';
import '../providers/bio_monitoring.dart';
import 'register.dart';
import 'user_title.dart';

class DashBoardView extends StatefulWidget {
  const DashBoardView({super.key});

  @override
  State<DashBoardView> createState() => _DashBoardViewState();
}

class _DashBoardViewState extends State<DashBoardView> {
  late final BioMonitoringProvider _bioMonitorProvider;

  @override
  void initState() {
    super.initState();

    _bioMonitorProvider =
        Provider.of<BioMonitoringProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Bio Monitoring"),
      ),
      body: ListView(
        children: List.generate(
          _bioMonitorProvider.users.length,
          (index) => UserTile(
            user: _bioMonitorProvider.users[index],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showRegisterDialog(context, null, _bioMonitorProvider).then((_) {
            setState(() {});
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
