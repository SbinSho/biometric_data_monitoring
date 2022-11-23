import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/device_scan.dart';
import 'real_time_chart.dart';

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
  late DeviceDataProcess? process;
  late final BioMonitoringProvider provider;
  @override
  void initState() {
    super.initState();
    user = widget.user;
    provider = Provider.of<BioMonitoringProvider>(context, listen: false);
    process = provider.devices[user.userID];
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        user.deviceID ?? "NULL",
                        style: Theme.of(context).textTheme.titleMedium!,
                      ),
                      StreamBuilder<DeviceConnectionState>(
                        stream: process?.connectState,
                        initialData: DeviceConnectionState.disconnected,
                        builder: (context, snapshot) {
                          if (snapshot.data! ==
                              DeviceConnectionState.connected) {
                            return Text(
                              "Connected",
                              style: Theme.of(context).textTheme.titleMedium!,
                            );
                          } else if (snapshot.data! ==
                              DeviceConnectionState.connecting) {
                            return Text(
                              "Connecting",
                              style: Theme.of(context).textTheme.titleMedium!,
                            );
                          } else {
                            return Text(
                              "Disconnected",
                              style: Theme.of(context).textTheme.titleMedium!,
                            );
                          }
                        },
                      ),
                      Text(
                        "Battery",
                        style: Theme.of(context).textTheme.titleMedium!,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Align(
                    alignment: Alignment.center,
                    child: process != null
                        ? StreamBuilder<ChartData>(
                            stream: process!.chartDataStream,
                            builder: (context, snapshot) {
                              if (snapshot.data == null) {
                                return const CircularProgressIndicator();
                              }

                              return Wrap(
                                spacing: 10.0,
                                runSpacing: 10.0,
                                direction: Axis.horizontal,
                                children: [
                                  SizedBox(
                                    width: 300,
                                    height: 200,
                                    child: RealTimeChart(
                                      chartType: ChartType.temp,
                                      dataStream: process!.chartDataStream,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 300,
                                    height: 200,
                                    child: RealTimeChart(
                                      chartType: ChartType.heart,
                                      dataStream: process!.chartDataStream,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 300,
                                    height: 200,
                                    child: RealTimeChart(
                                      chartType: ChartType.step,
                                      dataStream: process!.chartDataStream,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
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
                  ElevatedButton(
                    onPressed: () {},
                    child: Text("통계 보기"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _scanDeviceDialog(BuildContext context) async {
    var scanModel = DeviceScan();
    scanModel.startScan();

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
                        stream: scanModel.deviceDatas,
                        initialData: const {},
                        builder: (context, snapshot) {
                          var widgets = <Widget>[];

                          for (var element in snapshot.data!.entries) {
                            widgets.add(
                              InkWell(
                                onTap: () {
                                  scanModel.stopScan();
                                  provider
                                      .registerDevice(user, element.value.id)
                                      .then((value) {
                                    if (value) {
                                      process = provider.devices[user.userID];
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
                stream: scanModel.scanningState,
                initialData: false,
                builder: (context, snapshot) {
                  if (snapshot.data!) {
                    return ElevatedButton(
                      onPressed: scanModel.stopScan,
                      child: const CircularProgressIndicator(),
                    );
                  } else {
                    return ElevatedButton(
                      onPressed: scanModel.startScan,
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
