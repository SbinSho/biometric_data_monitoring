import 'package:flutter/material.dart';

import '../models/user.dart';
import '../providers/bio_monitoring.dart';

Future<void> showRegisterDialog(
  BuildContext context,
  User? user,
  BioMonitoringProvider bioProvider,
) async {
  final userIDCont = TextEditingController();
  final formKey = GlobalKey<FormState>();

  double interval = 15;

  if (user != null) {
    userIDCont.text = user.userID;
    interval = user.interval.toDouble();
  }

  return await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("사용자 등록"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("아이디"),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      controller: userIDCont,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "공백은 입력 할 수 없습니다.";
                        }

                        if (!bioProvider.idCheck(value)) {
                          return "중복된 ID 입니다.";
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
              ),
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
                          Text("${interval.toString().split(".").first} 분"),
                        ],
                      ),
                      Slider(
                        min: 1,
                        max: 30,
                        divisions: 30,
                        value: interval,
                        onChanged: (value) {
                          setState(() {
                            interval = value;
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
            child: const Text(
              'Disable',
              style: TextStyle(color: Colors.redAccent),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text(
              'Enable',
              style: TextStyle(
                color: Colors.blueAccent,
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final user = User(
                  userIDCont.text,
                  null,
                  interval.toInt(),
                  DateTime.now(),
                );

                bioProvider.registerUser(user).then((value) {
                  if (value) {
                    Navigator.of(context).pop();
                  } else {}
                });
              }
            },
          ),
        ],
      );
    },
  );
}
