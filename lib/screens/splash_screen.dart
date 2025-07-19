import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:yamka/screens/home_screen.dart';


class SplashScreen extends StatefulWidget {

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {

  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800)
    );
    animate();
  }

  ValueNotifier<double> valueNotifier = ValueNotifier(0.0); 

  void animate() {
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut
    ));

    animation.addListener(() {
      valueNotifier.value = animation.value;
    });

    animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder(
            valueListenable: valueNotifier,
            builder: (context, value, child) {
              return Container(
                margin: EdgeInsets.only(bottom: value * height * 0.2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/splash-icon.svg', width: width * max(value, 0.5) * 0.4)
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 12),
                          child: Text('Travel. Report. Discover', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 18),),
                        )
                      ],
                    )
                  ],
                )
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: valueNotifier,
            builder: (context, value, child) {
              return Container(
                width: width * 0.6,
                height: 54,
                margin: EdgeInsets.only(left: width * 0.04, top: value * height * 0.2),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    shadowColor: Colors.transparent,
                    backgroundColor: Color(0xFFF17420).withValues(alpha: value),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)
                    ),
                    padding: EdgeInsets.only(left: width * 0.02, right: width * 0.02, top: 12, bottom: 12)
                  ),
                  child: Center(
                    child: Text('Let\'s discover', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}