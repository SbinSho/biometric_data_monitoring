import 'dart:async';

import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:biometric_data_monitoring/views/user_title.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';

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
          _showRegisterDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<User?> _showRegisterDialog(BuildContext context) async {
    TextEditingController userIDCont = TextEditingController();
    final formKey = GlobalKey<FormState>();

    double interValue = 30;

    return await showDialog<User?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("사용자 등록"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _inputID(userIDCont, formKey),
                const SizedBox(height: 10.0),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "수집 간격",
                            ),
                            Text("${interValue.toString().split(".").first} 분"),
                          ],
                        ),
                        Slider(
                          min: 1,
                          max: 30,
                          divisions: 30,
                          value: interValue,
                          onChanged: (value) {
                            setState(() {
                              print("cahnge");
                              interValue = value;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            // TODO: 버튼 색상 변경 필요
            TextButton(
              child: const Text('Disable'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text('Enable'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final user = User(
                    userIDCont.text,
                    null,
                    interValue.toInt(),
                    DateTime.now(),
                  );

                  debugPrint("User : ${user.toString()}");

                  Navigator.of(context).pop(user);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Form _inputID(TextEditingController controller, Key key) => Form(
        key: key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("아이디"),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: controller,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "공백은 입력 할 수 없습니다.";
                }

                return null;
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "User ID",
              ),
            ),
          ],
        ),
      );
}
