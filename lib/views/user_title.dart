import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import '../models/hive/chart_data.dart';
import '../models/hive/user.dart';
import 'bio_chart.dart';

class UserTile extends StatefulWidget {
  final User user;

  const UserTile({
    required this.user,
    super.key,
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  late final User user;
  late final BioMonitoringProvider provider;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    provider = Provider.of<BioMonitoringProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.userID,
            style: Theme.of(context).textTheme.headlineLarge!,
          ),
          Card(
            elevation: 8.0,
            color: Colors.white70,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeviceInfo(),
                  const SizedBox(height: 10.0),
                  Align(
                    alignment: Alignment.center,
                    child: user.deviceID != null
                        ? _buildChart()
                        : ElevatedButton(
                            onPressed: () {
                              _scanDeviceDialog(context).then(
                                (value) {
                                  if (value != null || value == true) {
                                    setState(() {});
                                  }
                                },
                              );
                            },
                            child: const Text("디바이스 추가"),
                          ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          provider.deleteUser(user);
                        },
                        child: const Text("계정 삭제"),
                      ),
                      const SizedBox(width: 10.0),
                      ElevatedButton(
                        onPressed: () {
                          provider.deleteDevice(user).then((value) {
                            if (value) {
                              setState(() {});
                            } else {}
                          });
                        },
                        child: const Text("디바이스 삭제"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Column _buildDeviceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MAC : ${user.deviceID}",
          style: Theme.of(context).textTheme.titleMedium!,
        ),
        StreamBuilder<DeviceConnectionState>(
          stream: provider.connState(user),
          initialData: DeviceConnectionState.disconnected,
          builder: (context, snapshot) {
            var state = snapshot.data as DeviceConnectionState;

            return Text(
              "연결 상태 : ${state.getName}",
              style: Theme.of(context).textTheme.titleMedium!,
            );
          },
        ),
        StreamBuilder<int>(
          stream: provider.batteryStream(user),
          initialData: 0,
          builder: (context, snapshot) {
            return Text(
              "Battery : ${snapshot.data}%",
              style: Theme.of(context).textTheme.titleMedium!,
            );
          },
        ),
      ],
    );
  }

  Wrap _buildChart() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      direction: Axis.horizontal,
      children: List.generate(ChartType.values.length, (index) {
        return BioChart(
          chartType: ChartType.values[index],
          dataStream: provider.chartDataStream(user)!,
          initalDatas: [
            for (var e in provider.getBioDatas(user) ?? []) e as ChartData
          ],
        );
      }),
    );
  }

  Future<bool?> _scanDeviceDialog(BuildContext context) async {
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
                                  trailing:
                                      Text("rssi : ${element.value.rssi}"),
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
}
