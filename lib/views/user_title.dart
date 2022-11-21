import 'package:biometric_data_monitoring/providers/device_interface.dart';
import 'package:biometric_data_monitoring/providers/device_scan.dart';
import 'package:biometric_data_monitoring/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'real_time_chart.dart';

class UserTile extends StatefulWidget {
  final User user;

  const UserTile({required this.user, super.key});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  late bool deviceFlag;

  late DeviceInterface deviceInterface;

  @override
  void initState() {
    super.initState();

    deviceFlag = false;

    deviceInterface = DeviceInterface(widget.user);
    if (deviceInterface.deviceID != null) {
      deviceInterface.startTask();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user.userID,
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
                        deviceInterface.userID,
                        style: Theme.of(context).textTheme.titleMedium!,
                      ),
                      StreamBuilder<DeviceConnectionState>(
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
                      child: Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        direction: Axis.horizontal,
                        children: [
                          Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red),
                            ),
                            child: RealTimeChart(
                              chartType: ChartType.temp,
                              dataStream: deviceInterface.tempStream,
                            ),
                          ),
                          Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red),
                            ),
                            child: RealTimeChart(
                              chartType: ChartType.heart,
                              dataStream: deviceInterface.heartStream,
                            ),
                          ),
                          Container(
                            width: 300,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red),
                            ),
                            child: RealTimeChart(
                              chartType: ChartType.step,
                              dataStream: deviceInterface.stepStream,
                            ),
                          ),
                        ],
                      ) /* deviceFlag
                        ? Wrap(
                            spacing: 10.0,
                            runSpacing: 10.0,
                            direction: Axis.horizontal,
                            children: [
                              Container(
                                width: 300,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                ),
                                child: RealTimeChart(
                                  chartType: ChartType.temp,
                                  dataStream: deviceInterface.tempStream,
                                ),
                              ),
                              Container(
                                width: 300,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                ),
                                child: RealTimeChart(
                                  chartType: ChartType.heart,
                                  dataStream: deviceInterface.heartStream,
                                ),
                              ),
                              Container(
                                width: 300,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                ),
                                child: RealTimeChart(
                                  chartType: ChartType.step,
                                  dataStream: deviceInterface.stepStream,
                                ),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () {
                              deviceInterface.startScan();
                              if (deviceInterface.deviceID != null) {
                                setState(() {
                                  deviceFlag = true;
                                });
                              }
                              _scanDeviceDialog(context);
                            },
                            child: const Text("디바이스 추가"),
                          ), */
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

  Future<void> _scanDeviceDialog(BuildContext context) async {
    return showModalBottomSheet(
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
                        stream: deviceInterface.deviceDatas,
                        initialData: const {},
                        builder: (context, snapshot) {
                          var widgets = <Widget>[];

                          for (var element in snapshot.data!.entries) {
                            widgets.add(
                              InkWell(
                                onTap: () {
                                  deviceInterface.deviceID = element.value.id;
                                  deviceInterface.startTask();
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
                stream: deviceInterface.scanningState,
                initialData: false,
                builder: (context, snapshot) {
                  if (snapshot.data!) {
                    return ElevatedButton(
                      onPressed: deviceInterface.stopScan,
                      child: const CircularProgressIndicator(),
                    );
                  } else {
                    return ElevatedButton(
                      onPressed: deviceInterface.startScan,
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
