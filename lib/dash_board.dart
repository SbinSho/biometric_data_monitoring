import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:biometric_data_monitoring/views/user_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/user_data.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  late final BioMonitoringProvider _bioMonitorProvider;

  // Text Widget
  final registerTitle = const Text("사용자 등록");
  final registerUser = const Text("등록");
  final cancle = const Text('취소', style: TextStyle(color: Colors.red));

  final userTiles = <Widget>[];

  @override
  void initState() {
    super.initState();

    _bioMonitorProvider =
        Provider.of<BioMonitoringProvider>(context, listen: false);

    for (var element in _bioMonitorProvider.userList.entries) {
      userTiles.add(UserTile(userDataModel: element.value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Bio Monitoring"),
      ),
      body: Consumer<BioMonitoringProvider>(
        builder: (context, value, child) {
          return GridView.count(
            crossAxisCount: 1,
            children: userTiles,
          );
        },
        child: GridView.count(
          crossAxisCount: 1,
          children: userTiles,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _createUserDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createUserDialog() async {
    final idCont = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: registerTitle,
          content: SingleChildScrollView(
            child: TextField(
              controller: idCont,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: registerUser,
              onPressed: () {
                if (idCont.text != "") {
                  _bioMonitorProvider.createUser(idCont.text).then(
                    (value) {
                      if (value) {
                        Navigator.of(context).pop();
                      } else {
                        // TODO : 실패시 로직 처리
                      }
                    },
                  );
                }
              },
            ),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: cancle,
            ),
          ],
        );
      },
    );
  }
}
