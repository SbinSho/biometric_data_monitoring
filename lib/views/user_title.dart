import 'dart:ffi';

import 'package:biometric_data_monitoring/providers/bio_monitoring.dart';
import 'package:biometric_data_monitoring/views/bio_statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import '../models/hive/chart_data.dart';
import '../models/hive/user.dart';
import 'bio_realtime_chart.dart';
import 'register.dart';

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
  late User user;
  late final BioMonitoringProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<BioMonitoringProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    user = widget.user;
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
            color: Colors.blueGrey,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(10.0),
              child: Column(
                children: [
                  _buildDeviceInfo(),
                  const SizedBox(height: 10.0),
                  user.deviceID == null
                      ? Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  registerDevice(context, user, provider)
                                      .then((value) {
                                    if (value != null && value) {
                                      setState(() {});
                                    }
                                  });
                                },
                                child: const Text("디바이스 추가"),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                child: const Text("통계 보기"),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: _buildChart(),
                            ),
                            const SizedBox(height: 10.0),
                            Wrap(
                              spacing: 10.0,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    provider.deleteUser(user);
                                  },
                                  child: const Text("계정 삭제"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    provider.deleteUser(user);
                                  },
                                  child: const Text("디바이스 삭제"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    registerUser(context, user, provider)
                                        .then((value) {
                                      setState(() {});
                                    });
                                  },
                                  child: const Text("설정 변경"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    var results = provider.getStatics(user);
                                    if (results != null) {
                                      var converts = <ChartData>[];
                                      for (var element in results) {
                                        converts.add(element as ChartData);
                                      }

                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BioStatisticsView(
                                                  dbDatas: converts),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text("통계 보기"),
                                ),
                              ],
                            ),
                          ],
                        )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return user.deviceID == null
        ? const SizedBox(
            width: 0,
            height: 0,
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "${user.deviceID}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                "수집간격 : ${user.interval}분",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              StreamBuilder<DeviceConnectionState>(
                stream: provider.connState(user),
                initialData: DeviceConnectionState.disconnected,
                builder: (context, snapshot) {
                  var state = snapshot.data as DeviceConnectionState;

                  TextStyle style = Theme.of(context).textTheme.titleMedium!;

                  if (state == DeviceConnectionState.disconnected) {
                    style = Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Colors.redAccent,
                        );
                  }

                  return Text(state.getName, style: style);
                },
              ),
              StreamBuilder<int>(
                stream: provider.batteryStream(user),
                initialData: 0,
                builder: (context, snapshot) {
                  return Text(
                    "${snapshot.data}%",
                    style: Theme.of(context).textTheme.titleMedium,
                  );
                },
              ),
            ],
          );
  }

  Widget _buildChart() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      direction: Axis.horizontal,
      children: List.generate(ChartType.values.length, (index) {
        return BioRealtimeChart(
          chartType: ChartType.values[index],
          dataStream: provider.chartDataStream(user),
          initalDatas: [for (var e in provider.getLastBioDatas(user)) e],
        );
      }),
    );
  }
}
