import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:yamka/providers/theme_provider.dart';
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
  final Widget icon;
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


class _WeatherConditionsWidgetState extends State<WeatherConditionsWidget> with TickerProviderStateMixin {

  final void Function(CallbackType callbackType, double? size) callback;
  
  _WeatherConditionsWidgetState({required this.callback});

  List<WeatherReportElement> elements = [
    WeatherReportElement(icon: SvgPicture.asset("assets/bad-weather-icon.svg", width: 100, height: 100,), name: 'Bad weather', weatherReport: WeatherReport.badWeather),
    WeatherReportElement(icon: SvgPicture.asset("assets/slippery-road-icon.svg", width: 100, height: 100,), name: 'Slippery road', weatherReport: WeatherReport.slipparyRoad),
    WeatherReportElement(icon: SvgPicture.asset("assets/flood-icon.svg", width: 100, height: 100,), name: 'Flood', weatherReport: WeatherReport.flood),
    WeatherReportElement(icon: SvgPicture.asset("assets/unplowed-road-icon.svg"), name: 'Unplowed road', weatherReport: WeatherReport.unplowedRoad),
    WeatherReportElement(icon: SvgPicture.asset("assets/fog-icon.svg", width: 100, height: 100,), name: 'Fog', weatherReport: WeatherReport.fog),
    WeatherReportElement(icon: Icon(Icons.ac_unit, color: Color(0xFF4F4F4F),), name: 'Icy road', weatherReport: WeatherReport.icyRoad)
  ];

  late AnimationController reportAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback(CallbackType.jumpTo, 0.6);
    });
    reportAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5)
    );
  }

  final ValueNotifier<double> autoSend = ValueNotifier(0.0);

  void animateReport() {
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0
    ).animate(CurvedAnimation(
      parent: reportAnimationController,
      curve: Curves.linear
    ));
    animation.addListener(() {
      autoSend.value = animation.value;
    });
    reportAnimationController.forward(from: 0.0);
  }

  WeatherReport? selectedWeatherReport;

  @override
  void dispose() {
    super.dispose();
    reportAnimationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final themeProvider = context.watch<ThemeProvider>();
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
                child: Text('Report bad weather', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.light ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 24),),
              ),
              Container(
                margin: EdgeInsets.only(right: width * 0.02),
                child: IconButton(
                  icon: Icon(Icons.close, size: 35, color: themeProvider.themeMode == ThemeMode.light ? Colors.black : Colors.white,),
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
          margin: EdgeInsets.only(top: height * 0.02),
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
                      height: width * 0.25,
                      width: width * 0.25,
                      margin: EdgeInsets.only(left: width * 0.0625),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: width * 0.2,
                            height: width * 0.2,
                            decoration: BoxDecoration(
                              border: selectedWeatherReport ==  elements[3 * i + j].weatherReport ? Border.all(width: 2, color: Colors.orangeAccent) : Border.all(width: 0, color: Colors.transparent),
                              shape: BoxShape.circle
                            ),
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Color(0xFFF2F2F7),
                                iconSize: width * 0.2
                              ),
                              onPressed: () {
                                if (!reportAnimationController.isAnimating && !reportAnimationController.isCompleted) {
                                  animateReport();
                                }
                                setState(() {
                                  selectedWeatherReport = elements[3 * i + j].weatherReport;
                                });
                              },
                              icon: SizedBox(
                                width: width * 0.14,
                                height: width * 0.14,
                                child: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Center(
                                    child: elements[3 * i + j].icon,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(elements[3 * i + j].weatherReport.name, style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.light ? Colors.black : Colors.white), maxLines: 1,),
                          )
                        ],
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
              height: 54,
              margin: EdgeInsets.only(left: width * 0.04),
              child: ElevatedButton(
                onPressed: () {
                  callback(CallbackType.cancel, null);
                },
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                  padding: EdgeInsets.only(left: width * 0.02, right: width * 0.02, top: 12, bottom: 12)
                ),
                child: Center(
                  child: Text('Cancel', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 18),),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: autoSend,
              builder: (context, value, child) {
                return Container(
                  width: width * 0.4,
                  height: 54,
                  margin: EdgeInsets.only(right: width * 0.04),
                  child: ElevatedButton(
                    onPressed: () {
                    },
                    style: ElevatedButton.styleFrom(
                      shadowColor: Colors.transparent,
                      backgroundColor: Color(0xFFFB9726),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)
                      ),
                      padding: EdgeInsets.zero
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: width * 0.4 * value,
                              height: 54,
                              decoration: BoxDecoration(
                                color: themeProvider.themeMode == ThemeMode.light ? Colors.white.withValues(alpha: 0.3) : Color(0xFF252525).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16)
                              ),
                            )
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Report', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 18),)
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        )
      ],
    );
  }
}