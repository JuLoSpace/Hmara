import 'package:flutter/material.dart';
import 'package:yamka/screens/widgets/callback_types.dart';
import '../../data/reports/reports.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class ReportsWidget extends StatefulWidget {

  final void Function(CallbackType callbackType, double? size) callback;

  ReportsWidget({required this.callback});

  @override
  State<ReportsWidget> createState() => _ReportsWidgetState(callback: callback);
}

class _ReportsWidgetState extends State<ReportsWidget> {

  final void Function(CallbackType callbackType, double? size) callback;

  _ReportsWidgetState({required this.callback});

  Widget? currentReport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback(CallbackType.jumpTo, 0.4);
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return currentReport == null ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: height * 0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(left: width * 0.04),
                child: Text('Отправить отчёт', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 24),),
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
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: ((ReportWidgets.allReportWidgets().length + 2) / 3).toInt(),
            itemBuilder: (context, i) {
              return Container(
                height: height * 0.15,
                margin: EdgeInsets.only(top: height * 0.02),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: min(ReportWidgets.allReportWidgets().length - 3 * i, 3),
                  itemBuilder: (context, j) {
                    return Container(
                      width: width * 0.25,
                      height: height * 0.15,
                      margin: EdgeInsets.only(left: width * 0.0625),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              width: width * 0.25,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    currentReport = ReportWidgets.allReportWidgets(voidCallback: (CallbackType callbackType, double? size) {
                                      switch (callbackType) {
                                        case CallbackType.close: {
                                          callback(callbackType, null);
                                        }
                                        case CallbackType.jumpTo: {
                                          callback(callbackType, size);
                                        }
                                        case CallbackType.cancel: {
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            setState(() {
                                              currentReport = null;
                                            });
                                            callback(CallbackType.jumpTo, 0.4);
                                          });
                                        }
                                      }
                                    })[3 * i + j].widget;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  shadowColor: Colors.transparent,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.1),
                                  overlayColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadiusGeometry.circular(16)
                                  )
                                ),
                                child: SizedBox(
                                  height: height * 0.1,
                                  width: width * 0.2,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: ReportWidgets.allReportWidgets()[3 * i + j].icon,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: width * 0.25,
                            child: Center(
                              child: Text(ReportWidgets.allReportWidgets()[3 * i + j].report.name, style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, softWrap: false,),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                )
              );
            },
          ),
        )
      ],
    ) : currentReport!;
  }
}