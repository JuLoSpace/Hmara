import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'package:yamka/screens/widgets/callback_types.dart';


enum WeatherReport {
  badWeather,
  slipparyRoad,
  flood,
  unplowedRoad,
  fog,
  icyRoad
}

class WeatherReportElement {
  final Icon icon;
  final String name;
  final WeatherReport weatherReport;
  WeatherReportElement({required this.icon, required this.name, required this.weatherReport});
}

class WeatherConditionsWidget extends StatefulWidget {
  final void Function(CallbackType callbackType, double? size) callback;
  WeatherConditionsWidget({required this.callback, Key? key}) : super(key: key);

  @override
  State<WeatherConditionsWidget> createState() => _WeatherConditionsWidgetState(callback: callback);
}


class _WeatherConditionsWidgetState extends State<WeatherConditionsWidget> {

  final void Function(CallbackType callbackType, double? size) callback;
  
  _WeatherConditionsWidgetState({required this.callback});

  List<WeatherReportElement> elements = [
    WeatherReportElement(icon: Icon(Icons.air), name: 'Bad weather', weatherReport: WeatherReport.badWeather),
    WeatherReportElement(icon: Icon(Icons.home), name: 'Slippery road', weatherReport: WeatherReport.slipparyRoad),
    WeatherReportElement(icon: Icon(Icons.flood), name: 'Flood', weatherReport: WeatherReport.flood),
    WeatherReportElement(icon: Icon(Icons.home), name: 'Unplowed road', weatherReport: WeatherReport.unplowedRoad),
    WeatherReportElement(icon: Icon(Icons.foggy), name: 'Fog', weatherReport: WeatherReport.fog),
    WeatherReportElement(icon: Icon(Icons.ac_unit), name: 'Icy road', weatherReport: WeatherReport.icyRoad)
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback(CallbackType.jumpTo, 0.6);
    });
  }

  WeatherReport? selectedWeatherReport;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: height * 0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(left: width * 0.04),
                child: Text('Report bad weather', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 24),),
              ),
              Container(
                margin: EdgeInsets.only(right: width * 0.02),
                child: IconButton(
                  icon: Icon(Icons.close, size: 35,),
                  onPressed: () {
                    callback(CallbackType.close, null);
                  },
                ),
              )
            ],
          ),
        ),
        Container(
          width: width,
          child: ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: ((elements.length + 2) / 3).toInt(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            scrollDirection: Axis.vertical,
            itemBuilder:(context, i) {
              return Container(
                height: width * 0.25,
                margin: EdgeInsets.only(bottom: 24),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: min(3, elements.length - 3 * i),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, j) {
                    return Container(
                      width: width * 0.25,
                      height: width * 0.25,
                      margin: EdgeInsets.only(left: width * 0.0625),
                      decoration: BoxDecoration(
                        border: selectedWeatherReport ==  elements[3 * i + j].weatherReport ? Border.all(width: 2, color: Colors.orangeAccent) : Border.all(width: 0, color: Colors.transparent),
                        shape: BoxShape.circle
                      ),
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          iconSize: 40
                        ),
                        onPressed: () {
                          setState(() {
                            selectedWeatherReport = elements[3 * i + j].weatherReport;
                          });
                        },
                        icon: elements[3 * i + j].icon,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: width * 0.4,
              margin: EdgeInsets.only(left: width * 0.04),
              child: ElevatedButton(
                onPressed: () {
                  callback(CallbackType.cancel, null);
                },
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.only(left: width * 0.02, right: width * 0.02, top: 12, bottom: 12)
                ),
                child: Center(
                  child: Text('Cancel', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 18),),
                ),
              ),
            ),
            Container(
              width: width * 0.4,
              margin: EdgeInsets.only(right: width * 0.04),
              child: ElevatedButton(
                onPressed: () {
                },
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.transparent,
                  backgroundColor: Color(0xFFFF6B00),
                  padding: EdgeInsets.only(left: width * 0.02, right: width * 0.02, top: 12, bottom: 12)
                ),
                child: Center(
                  child: Text('Report', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 18),),
                ),
              ),
            )
          ],
        )
      ],
    );
  }
}