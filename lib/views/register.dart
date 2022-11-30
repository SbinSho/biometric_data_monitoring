import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/hive/user.dart';
import '../providers/bio_monitoring.dart';

Future<bool?> registerDevice(
  BuildContext context,
  User user,
  BioMonitoringProvider provider,
) async {
  provider.startScan();

  return await showModalBottomSheet<bool?>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(50.0),
        topRight: Radius.circular(50.0),
      ),
    ),
    builder: (context) {
      return Container(
        margin: const EdgeInsetsDirectional.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "디바이스 목록",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10.0),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    StreamBuilder<Map<String, DiscoveredDevice>>(
                      stream: provider.scanResults,
                      initialData: const {},
                      builder: (context, snapshot) {
                        var widgets = <Widget>[];

                        for (var element in snapshot.data!.entries) {
                          if (provider.usedDevices.contains(element.key)) {
                            continue;
                          }
                          widgets.add(
                            InkWell(
                              onTap: () {
                                provider.startScan();
                                provider
                                    .registerDevice(user, element.value.id)
                                    .then((value) {
                                  if (value) {
                                    Navigator.of(context).pop(true);
                                  } else {
                                    Navigator.of(context).pop(false);
                                  }
                                });
                              },
                              child: ListTile(
                                title: Text(element.value.name),
                                subtitle: Text(element.value.id),
                                trailing: Text("rssi : ${element.value.rssi}"),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: widgets,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            StreamBuilder(
              stream: provider.scanningState,
              initialData: false,
              builder: (context, snapshot) {
                if (snapshot.data!) {
                  return ElevatedButton(
                    onPressed: provider.stopScan,
                    child: const CircularProgressIndicator(),
                  );
                } else {
                  return ElevatedButton(
                    onPressed: provider.startScan,
                    child: const Text("재검색"),
                  );
                }
              },
            )
          ],
        ),
      );
    },
  );
}

Future<void> registerUser(
  BuildContext context,
  User? user,
  BioMonitoringProvider provider,
) async {
  final userIDCont = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var interval = 15.0;

  if (user != null) {
    userIDCont.text = user.userID;
    interval = user.interval.toDouble();
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: user == null ? const Text("사용자 등록") : const Text("사용자 수정"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        if (value != null && user != null) {
                          if (value.toLowerCase() == user.key) {
                            return null;
                          }
                        }

                        if (value == null || value.isEmpty) {
                          return "공백은 입력 할 수 없습니다.";
                        }

                        if (!provider.idCheck(value)) {
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                final editUser = User(
                  userIDCont.text,
                  user?.deviceID,
                  interval.toInt(),
                  DateTime.now(),
                );

                if (user != null) {
                  provider.editUser(user, editUser).then((value) async {
                    if (value) {
                      Navigator.of(context).pop();
                    } else {}
                  });
                } else {
                  provider.registerUser(editUser).then((value) {
                    if (value) {
                      Navigator.of(context).pop();
                    } else {}
                  });
                }
              }
            },
          ),
        ],
      );
    },
  );
}
