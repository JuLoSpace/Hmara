import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yamka/screens/widgets/callback_types.dart';
import 'widgets/weather_report.dart';

abstract class Report {
  String name;
  Report(this.name);
}

class WeatherConditionsReport extends Report {
  WeatherConditionsReport() : super('weather');
}

class SosReport extends Report {
  SosReport() : super('help');
}

class ReportWidget {
  final dynamic report;
  final Widget widget;
  final IconData icon;
  ReportWidget({required this.report, required this.icon, required this.widget});
}

class ReportWidgets {
  static List<ReportWidget> allReportWidgets({void Function(CallbackType callbackType, double? size,)? voidCallback}) {
    return [
      ReportWidget(report: WeatherConditionsReport(), icon: Icons.thunderstorm, widget: WeatherConditionsWidget(callback: voidCallback ?? (_, _) {},)),
      ReportWidget(report: SosReport(), icon: Icons.support, widget: Container()),
    ];
  }
}