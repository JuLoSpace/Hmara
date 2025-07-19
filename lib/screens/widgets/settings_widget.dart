import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:yamka/providers/theme_provider.dart';


class SettingsWidget extends StatefulWidget {

  final VoidCallback callback;

  SettingsWidget({required this.callback});

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState(callback: callback);
}


class _SettingsWidgetState extends State<SettingsWidget> {

  final VoidCallback callback;

  _SettingsWidgetState({required this.callback});

  bool isReportPrefered = false;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    final themeProvider = context.watch<ThemeProvider>();
    return Container(
      height: height,
      width: width,
      color: themeProvider.themeMode == ThemeMode.light ? Colors.white : Color(0xFF252525),
      child: Column(
        children: [
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(left: width * 0.05),
                  child: Text('Settings', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w600, fontSize: 30),),
                ),
                Container(
                  margin: EdgeInsets.only(right: width * 0.05),
                  child: IconButton(
                    onPressed: () {
                      callback();
                    },
                    icon: Icon(Icons.close, size: 40, color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525),),
                  ),
                )
              ],
            )
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  // change language
                },
                child: Container(
                  padding: EdgeInsets.only(left: width * 0.05, right: width * 0.1, top: 24, bottom: 24),
                  decoration: BoxDecoration(
                    border: BoxBorder.symmetric(horizontal: BorderSide(width: 1, color: Colors.grey.withValues(alpha: 0.1)))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Language', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w500, fontSize: 16),),
                      Text('English', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w600, fontSize: 16),)
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: width * 0.05, right: width * 0.1, top: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Prefer of reports', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w500, fontSize: 16),),
                    Container(
                      child: Platform.isIOS ? CupertinoSwitch(
                        value: isReportPrefered,
                        onChanged: (value) {
                          setState(() {
                            isReportPrefered = value;
                          });
                        },
                      ) : Switch(
                        value: isReportPrefered,
                        activeTrackColor: Color(0xFF34C759),
                        inactiveTrackColor: Colors.black.withValues(alpha: 0.1),
                        onChanged: (value) {
                          setState(() {
                            isReportPrefered = value;
                          });
                        },
                      )
                    )
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: width * 0.05, right: width * 0.1, top: 24, bottom: 24),
                decoration: BoxDecoration(
                  border: BoxBorder.symmetric(horizontal: BorderSide(width: 1, color: Colors.grey.withValues(alpha: 0.1)))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Theme', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w500, fontSize: 16),),
                    Container(
                      width: width * 0.4,
                      height: 50,
                      child: Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  themeProvider.toogleTheme(ThemeMode.light);
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(width * 0.2, 50),
                                  shadowColor: Colors.transparent,
                                  backgroundColor: Colors.white,
                                  overlayColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))
                                  ),
                                ),
                                child: Center(
                                  child: Text('Light', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black)),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  themeProvider.toogleTheme(ThemeMode.dark);
                                },
                                style: ElevatedButton.styleFrom(
                                  fixedSize: Size(width * 0.2, 50),
                                  shadowColor: Colors.transparent,
                                  backgroundColor: Colors.white,
                                  overlayColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16))
                                  ),
                                ),
                                child: Center(
                                  child: Text('Dark', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black),),
                                ),
                              ),
                            ],
                          ),
                          AnimatedContainer(
                            width: width * 0.2,
                            height: 50,
                            margin: EdgeInsets.only(left: themeProvider.themeMode == ThemeMode.light ? 0 : width * 0.2),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.only(topLeft: themeProvider.themeMode == ThemeMode.light ? Radius.circular(16) : Radius.zero, bottomLeft: themeProvider.themeMode == ThemeMode.light ? Radius.circular(16) : Radius.zero, topRight: themeProvider.themeMode == ThemeMode.dark ? Radius.circular(16) : Radius.zero, bottomRight: themeProvider.themeMode == ThemeMode.dark ? Radius.circular(16) : Radius.zero)
                            ),
                            duration: Duration(milliseconds: 500),
                            curve: Curves.bounceOut,
                            child: Center(
                              child: Text(themeProvider.themeMode == ThemeMode.light ? "Light" : "Dark", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600),),
                            ),
                          )
                        ],
                      )
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}