import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yamka/providers/location_provider.dart';
import 'package:yamka/screens/home_screen.dart';
import 'package:yamka/screens/splash_screen.dart';
import 'package:yandex_mobileads/mobile_ads.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);

  await MobileAds.initialize();

  Future<void> setup() async {
    await dotenv.load(fileName: '.env');
    MapboxOptions.setAccessToken(dotenv.env["MAPBOX_ACCESS_TOKEN"]!);
    WidgetsBinding.instance.addPersistentFrameCallback((_) async {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
    });
    // List<Map<String, dynamic>> data = await geocodingService.searchAddress('Цум');
    // print(data);
    
  }

  await setup();

  runApp(const HmaraApp());
}

class HmaraApp extends StatelessWidget {

  const HmaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final provider = LocationProvider();
          provider.initializateLocator();
          return provider;
        },)
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}
