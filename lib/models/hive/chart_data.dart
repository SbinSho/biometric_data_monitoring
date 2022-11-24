import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'hive_model.dart';

part 'chart_data.g.dart';

@HiveType(typeId: HiveTypeId.bio)
class ChartData {
  @HiveField(0)
  late final double temp;
  @HiveField(1)
  late final double heart;
  @HiveField(2)
  late final double step;
  @HiveField(3)
  late final DateTime _timeStamp;

  ChartData(this.temp, this.heart, this.step, this._timeStamp);

  @override
  String toString() =>
      "temp : $temp, heart : $heart, step : $step, timeStamp : $_timeStamp";

  String getTime([String pattern = "yy-MM-dd HH:mm"]) =>
      DateFormat(pattern).format(_timeStamp);
}
