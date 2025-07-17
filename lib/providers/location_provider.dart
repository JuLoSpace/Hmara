import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';


class LocationProvider extends ChangeNotifier {

  LocationPermission? _permissionStatus;
  Position? _currentPosition;
  StreamSubscription<Position>? _locationStream;

  final _positionStreamController = StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _positionStreamController.stream;

  Position? get currentPosition => _currentPosition;
  LocationPermission? get locationPermission => _permissionStatus;

  static const double goodAccuracyThreshold = 25.0;

  Future<void> initializateLocator() async {
    try {
      final status = await Geolocator.checkPermission();
      if (status == LocationPermission.whileInUse || status == LocationPermission.always) {
        _permissionStatus = status;
      } else {
        final requestStatus = await Geolocator.requestPermission();
        _permissionStatus = requestStatus;
      }
      if (_permissionStatus == LocationPermission.whileInUse || _permissionStatus == LocationPermission.always) {
        startLocationUpdates();
      }
      notifyListeners();
    } catch (e) {
      _permissionStatus = LocationPermission.denied;
      notifyListeners();
    }
  }

  void startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
    _locationStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = position;
      _positionStreamController.add(position);
      notifyListeners();
    },
    onError: (error) {}
    );
  }

  @override
  void dispose() {
    _positionStreamController.close();
    _locationStream?.cancel();
    super.dispose();
  }
}