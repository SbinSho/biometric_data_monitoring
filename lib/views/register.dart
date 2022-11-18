import 'package:flutter/material.dart';

import '../models/user.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _userIDCont = TextEditingController();
  double _currentSliderValue = 20;

  bool _deviceSelFlag = false;

  late String _inputUserID;
  late String _inputDeviceID;
  late int _inputInterVal;

  @override
  void initState() {
    super.initState();
    _inputUserID = "";
    _inputDeviceID = "";
    _inputInterVal = 10;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _idTextField,
          const SizedBox(height: 10.0),
          ..._slider,
          const SizedBox(height: 10.0),
          _deviceInfo,
          const SizedBox(height: 10.0),
          Expanded(
            child: _deviceSelFlag ? Container() : _deviceList,
          ),
          const SizedBox(height: 10.0),
          _bottomBtn,
        ],
      ),
    );
  }

  Column get _idTextField => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("아이디"),
          const SizedBox(height: 10.0),
          TextField(
            controller: _userIDCont,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "User ID",
            ),
          ),
        ],
      );

  List<Widget> get _slider => [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "수집 간격",
            ),
            Text(_sliderValue),
          ],
        ),
        Slider(
          min: 1,
          max: 30,
          divisions: 30,
          value: _currentSliderValue,
          onChanged: (value) {
            setState(() {
              _currentSliderValue = value;
            });
          },
        ),
      ];

  Column get _deviceInfo => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "디바이스 정보",
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Device Name : ",
                    style: Theme.of(context).textTheme.bodyText1!.copyWith(),
                  ),
                  Text(
                    "Mac : ",
                    style: Theme.of(context).textTheme.bodyText1!.copyWith(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  Widget get _deviceList => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("디바이스 목록"),
              ElevatedButton(
                onPressed: () {},
                child: const Text("재검색"),
              )
            ],
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: List.generate(
                100,
                (index) => ListTile(
                  title: Text("test"),
                  subtitle: Text("subtitle"),
                  trailing: Text("rssi"),
                  onTap: () {
                    setState(() {
                      _deviceSelFlag = true;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      );

  Widget get _bottomBtn => Row(
        children: [
          _deviceSelFlag
              ? Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 4.0,
                      end: 4.0,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _deviceSelFlag = false;
                        });
                      },
                      child: const Text("디바이스 다시 선택"),
                    ),
                  ),
                )
              : Container(),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 4.0,
                end: 4.0,
              ),
              child: ElevatedButton(
                onPressed: () {
                  final snackBarMsg = <String>[];

                  _inputUserID = _userIDCont.text;

                  if (_inputUserID == "") {
                    snackBarMsg.add("User ID Error");
                  }

                  if (_inputDeviceID == "") {
                    snackBarMsg.add("Device ID Error");
                  }

                  if (snackBarMsg.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Valid Error : ${snackBarMsg.join(",")}'),
                      ),
                    );

                    return;
                  }

                  User user = User(
                    _inputUserID,
                    _inputDeviceID,
                    _inputInterVal,
                    DateTime.now(),
                  );

                  debugPrint(user.toString());
                },
                child: const Text("등록"),
              ),
            ),
          ),
        ],
      );

  String get _sliderValue =>
      "${_currentSliderValue.toString().split(".").first} 분";

  @override
  void dispose() {
    super.dispose();
    _userIDCont.dispose();
  }
}
