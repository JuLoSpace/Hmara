import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class RouteService {

  late String accessToken;

  Future<void> initializate() async {
    await dotenv.load(fileName: '.env');
    accessToken = dotenv.env["MAPBOX_ACCESS_TOKEN"]!;
  }

  Future<Map<String, dynamic>> getRouteCoordinates(LatLng start, LatLng end) async {
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&access_token=$accessToken&overview=full&alternatives=true';
    print(url);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    }
    return {};
  }
}