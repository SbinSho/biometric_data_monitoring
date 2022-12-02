import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

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
    return Consumer<BioMonitoringProvider>(
      builder: (context, value, child) {
        var tiles = [
          for (var user in value.users.entries) UserTile(user: user.value),
        ];

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Bio Monitoring"),
          ),
          body: ListView(children: tiles),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              registerUser(context, null, value);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
