import 'package:biometric_data_monitoring/models/user_data.dart';
import 'package:flutter/material.dart';

class UserTile extends StatefulWidget {
  final UserDataModel userDataModel;

  const UserTile({required this.userDataModel, super.key});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  late final UserDataModel model;

  @override
  void initState() {
    model = widget.userDataModel;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${model.userName}"),
        Container(
          child: Column(children: []),
        ),
      ],
    );
  }
}
