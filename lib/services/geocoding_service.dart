import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';


class GeocodingService {

  late String accessToken;

  Future<void> initializate() async {
    await dotenv.load(fileName: '.env');
    accessToken = dotenv.env["MAPBOX_ACCESS_TOKEN"]!;
  }

  Future<List<Map<String, dynamic>>> searchAddress(String query, Position proximity) async {
    if (query == '') return [];
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/suggest'
        '?q=$query'
        '&access_token=$accessToken'
        '&session_token=1'
        '&proximity=${proximity.longitude},${proximity.latitude}'
        '&types=poi,street,address,place'
        '&language=ru'
      );
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      return (data['suggestions'] as List).map((suggestion) {
        return {
          'name': suggestion['name'],
          'address': suggestion['address'],
          'mapbox_id': suggestion['mapbox_id'],
          'distance': suggestion['distance']
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<double>> getCoordinates(String mapboxId) async {
    final url = Uri.parse(
      'https://api.mapbox.com/search/searchbox/v1/retrieve/$mapboxId'
      '?access_token=$accessToken'
      '&session_token=1'
    );
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    return [data['features'][0]['geometry']['coordinates'][0], data['features'][0]['geometry']['coordinates'][1]];
  }
}