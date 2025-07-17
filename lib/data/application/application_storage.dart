import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApplicationStorage {
  static const FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true
    )
  );

  static Future<String?> get getRecentlyPlaces async => await storage.read(key: 'recentlyPlaces');


  static Future setRecentlyPlaces(String places) async => await storage.write(key: 'recentlyPlaces', value: places);
  static Future removeAllData() async => await storage.deleteAll();

  Future<void> updateRecentlyPlaces(Map<String, dynamic> place) async {
    try {
      String? recentlyPlaces = await getRecentlyPlaces;
      Map<String, dynamic> decodedRecentlyPlaces = {};
      if (recentlyPlaces != null) {
        decodedRecentlyPlaces = jsonDecode(recentlyPlaces);
      }
      List decodedRecentlyPlacesList = [];
      if (decodedRecentlyPlaces.isNotEmpty) {
        decodedRecentlyPlacesList = decodedRecentlyPlaces['places'] as List;
      }
      decodedRecentlyPlacesList.add({
        'name': place['name'],
        'address': place['address'],
        'mapbox_id': place['mapbox_id'],
      });
      decodedRecentlyPlaces['places'] = decodedRecentlyPlacesList;
      String? encodedData = jsonEncode(decodedRecentlyPlaces);
      await setRecentlyPlaces(encodedData);
    } catch (e) {
      print(e);
    }
  }
}