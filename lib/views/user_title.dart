import 'package:flutter/material.dart';

class UserTile extends StatefulWidget {
  final String userName;

  const UserTile({required this.userName, super.key});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.userName),
        Container(
          child: Column(children: []),
        ),
      ],
    );
  }
}
