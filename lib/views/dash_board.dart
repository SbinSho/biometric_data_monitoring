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

    for (var user in _bioMonitorProvider.loadUsers()) {
      userTiles.add(
        UserTile(
          user: user,
        ),
      );
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
          showRegisterDialog(context, null, _bioMonitorProvider).then((_) {
            setState(() {});
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
