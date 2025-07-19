import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


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
    return Container(
      height: height,
      width: width,
      color: Colors.white,
      child: Column(
        children: [
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(left: width * 0.05),
                  child: Text('Settings', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 30),),
                ),
                Container(
                  margin: EdgeInsets.only(right: width * 0.05),
                  child: IconButton(
                    onPressed: () {
                      callback();
                    },
                    icon: Icon(Icons.close, size: 40, color: Colors.black,),
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
                  padding: EdgeInsets.only(left: width * 0.05, right: width * 0.15, top: 24, bottom: 24),
                  decoration: BoxDecoration(
                    border: BoxBorder.symmetric(horizontal: BorderSide(width: 1, color: Colors.grey.withValues(alpha: 0.1)))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Language', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),),
                      Text('English', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),)
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: width * 0.05, right: width * 0.15, top: 24, bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Prefer of reports', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),),
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
              )
            ],
          )
        ],
      ),
    );
  }
}