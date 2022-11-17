import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({super.key});

  @override
  State<DashBoard> createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  late final BioMonitoringProvider _bioMonitorProvder;

  @override
  void initState() {
    super.initState();
    _bioMonitorProvder =
        Provider.of<BioMonitoringProvider>(context, listen: false);
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
          return Container();
        },
        child: Container(),
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
          title: const Text('사용자 등록'),
          content: SingleChildScrollView(
            child: TextField(
              controller: idCont,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('등록'),
              onPressed: () {
                if (idCont.text != "") {
                  _bioMonitorProvder.createUser(idCont.text);
                  Navigator.of(context).pop();
                }
              },
            ),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
