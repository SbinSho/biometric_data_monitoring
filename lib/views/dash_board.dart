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
  @override
  Widget build(BuildContext context) {
    print("build!");
    return Consumer<BioMonitoringProvider>(
      builder: (context, value, child) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Bio Monitoring"),
          ),
          body: ListView(
            children: List.generate(
              value.users.length,
              (index) => UserTile(
                user: value.users[index],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showRegisterDialog(context, null, value).then((_) {
                setState(() {});
              });
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
