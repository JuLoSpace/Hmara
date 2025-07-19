import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yamka/data/application/application_storage.dart';
import 'package:yamka/providers/theme_provider.dart';
import 'package:yamka/screens/widgets/callback_types.dart';
import 'package:yamka/screens/widgets/reports_widget.dart';
import 'package:yamka/screens/widgets/settings_widget.dart';
import 'package:yamka/services/geocoding_service.dart';
import 'package:yamka/services/route_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart' as Geolocator;
import 'package:yandex_mobileads/mobile_ads.dart';
import '../providers/location_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as latlong;


enum HomeState {
  places,
  reports,
  settings
}


class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {

  HomeState homeState = HomeState.places;

  TextEditingController textEditingController = TextEditingController();

  late AnimationController draggableAnimationController;

  DraggableScrollableController draggableScrollableController = DraggableScrollableController();

  StreamSubscription<Geolocator.Position>? locationSubscription;

  MapboxMap? mapboxMap;

  final ValueNotifier<double> iconPosition = ValueNotifier(0.14);

  bool isTracking = false;

  late final Future<AppOpenAdLoader> appOpenAdLoader;
  AppOpenAd? appOpenAd;
  final adUnitId = "R-M-16293360-1";
  late var adRequestConfiguration = AdRequestConfiguration(adUnitId: adUnitId);
  static var isAdShowing = false;
  static var isColdStartAdShown = false;
  bool shouldNavigateToHome = false;

  @override
  void initState() {
    super.initState();
    setup();
    draggableScrollableController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        iconPosition.value = draggableScrollableController.size;
      });
      if (draggableScrollableController.size <= 0.4) {
        textEditingController.clear();
      }
      if (places.isNotEmpty && draggableScrollableController.size <= 0.4) {
        setState(() {
          places.clear();
        });
      }
    });
    draggableAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300)
    );
    // appOpenAdLoader = createAppOpenAdLoader();
    // loadAppOpenAd();
    WidgetsBinding.instance.addObserver(this);
  }

  late PointAnnotationManager pointAnnotationManager;
  late Uint8List destinationIconData;

  void onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    locationSubscription = context.read<LocationProvider>().positionStream.listen(updateMapPosition); 
    mapboxMap.location.updateSettings(
      LocationComponentSettings(enabled: true, showAccuracyRing: true, puckBearingEnabled: true, accuracyRingColor: Color(0xFF61A2D0).withValues(alpha: 0.1).value)
    );
    mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    final ByteData bytes = await rootBundle.load('assets/destination-icon.png');
    destinationIconData = bytes.buffer.asUint8List();
    await addTrafficLayer();
  }

  late GeocodingService geocodingService;
  late RouteService routeService;
  ApplicationStorage applicationStorage = ApplicationStorage();


  List<Map<String, dynamic>> recentlyPlaces = [];

  void setup() async {
    geocodingService = GeocodingService();
    await geocodingService.initializate();
    routeService = RouteService();
    await routeService.initializate();
    String? applicationRecentlyPlaces = await ApplicationStorage.getRecentlyPlaces;
    if (applicationRecentlyPlaces != null) {
      final decodedData = jsonDecode(applicationRecentlyPlaces);
      for (Map<String, dynamic> place in decodedData['places']) {
        final out = recentlyPlaces.where((Map<String, dynamic> rplace) {
          return place['mapbox_id'] == rplace['mapbox_id'];
        });
        if (out.isEmpty) {
          recentlyPlaces.add(place);
        }
      }
    }

    String? cameraOptionsData = await ApplicationStorage.getCameraOptions;

    if (cameraOptionsData != null) {
      try {
        final jsonData = jsonDecode(cameraOptionsData);
        String lng = jsonData['center']['longitude'] as String, lat = jsonData['center']['latitude'] as String, zoom = jsonData['zoom'] as String;
        cameraOptionsSaved = CameraOptions(
          center: Point(
            coordinates: Position(double.parse(lng), double.parse(lat)),
          ),
          zoom: double.parse(zoom)
        );
      } catch (e) {
        print(e);
        cameraOptionsSaved = null;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        isInitializated = true;
      });
    });
  }

  void getGeoPlaces(String query, Geolocator.Position proximity) async {
    List<Map<String, dynamic>> data = await geocodingService.searchAddress(query, proximity);
    setState(() {
      places = data;
    });
  }

  void updateMapPosition(Geolocator.Position position) {
    if (isTracking) {
      mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude)
          ),
          zoom: 15,
          bearing: position.heading,
          pitch: position.speed > 5 ? 20 : 0,
        ),
        MapAnimationOptions(
          duration: 1000
        )
      );
      updateCameraOptions();
    }
  }

  Future<void> getCoordinates(String maxpboxId) async {
    setState(() {
      isTracking = false;
    });
    List<double> data = await geocodingService.getCoordinates(maxpboxId);
    await addDestinationMarker(data[0], data[1]);

    final destination = latlong.LatLng(data[1], data[0]);
    final start = latlong.LatLng(
      locationProvider.currentPosition!.latitude,
      locationProvider.currentPosition!.longitude
    );
    await removeRoute();
    Map<String, dynamic> routeData = await routeService.getRouteCoordinates(start, destination);
    for (int i = (routeData['routes'] as List).length-1; i >= 0; i--) {
      await drawRoute(routeData['routes'][i], i != 0);
    }
    textEditingController.clear();
    animatedJumpTo(0.14);
  }

  int routeSourceId = 0;

  Future<void> drawRoute(Map<String, dynamic> route, bool isAlternative) async {

    List<dynamic> originalCoords = route['geometry']['coordinates'] as List<dynamic>;

    List<List<double>> coords = [];

    for (dynamic coord in originalCoords) {
      List<dynamic> data = coord as List<dynamic>;
      List<double> parsedData = [];
      for (final e in data) {
        parsedData.add(double.parse(e.toString()));
      }
      coords.add(parsedData);
    }

    final geoJson = {
      "type": "Feature",
      "geometry": {
        "type": "LineString",
        "coordinates": coords
      },
      'properties': {}
    };

    await mapboxMap?.style.addSource(GeoJsonSource(
      id: "route-source-$routeSourceId",
      data: jsonEncode(geoJson)
    ));

    await mapboxMap?.style.addLayer(LineLayer(
      id: "route-layer-$routeSourceId",
      sourceId: "route-source-$routeSourceId",
      lineColor: !isAlternative ? Color(0xFF61A2D0).value : Colors.grey.value,
      lineWidth: 5.0
    ));

    routeSourceId++;
  }

  Future<void> removeRoute() async {
    try {
      int c = routeSourceId;
      c--;
      while (true) {
        Layer? layer = await mapboxMap?.style.getLayer("route-layer-$c");
        if (layer != null) {
          await mapboxMap?.style.removeStyleLayer("route-layer-$c");
        } else {
          break;
        }
        c--;
      }
    } catch (e) {

    }
  }

  Future<void> addTrafficLayer() async {
    try {
      await mapboxMap?.style.addSource(
        VectorSource(
          id: 'traffic',
          url: 'mapbox://mapbox.mapbox-traffic-v1'
        )
      );

      await mapboxMap?.style.addLayer(
        LineLayer(
          id: 'traffic-layer-severe',
          sourceId: 'traffic',
          sourceLayer: 'traffic',
          lineColor: Colors.red.value,
          lineWidth: 4.0,
          lineOpacity: 0.7,
          filter: [
            'all',
            ['==', ['get', 'congestion'], 'severe'],
            [
              'match',
              ['get', 'class'],
              'motorway', true,
              'trunk', true,
              'motorway_link', true,
              'primary', true,
              'tertiary', true,
              false
            ]
          ]
        )
      );

      await mapboxMap?.style.addLayer(
        LineLayer(
          id: 'traffic-layer-heavy',
          sourceId: 'traffic',
          sourceLayer: 'traffic',
          lineColor: Colors.orange.value,
          lineWidth: 4.0,
          lineOpacity: 0.7,
          filter: [
            'all',
            ['==', ['get', 'congestion'], 'heavy'],
            [
              'match',
              ['get', 'class'],
              'motorway', true,
              'trunk', true,
              'motorway_link', true,
              'tertiary', true,
              false
            ]
          ]
        )
      );

       await mapboxMap?.style.addLayer(
        LineLayer(
          id: 'traffic-layer-moderate',
          sourceId: 'traffic',
          sourceLayer: 'traffic',
          lineColor: Colors.yellow.value,
          lineWidth: 4.0,
          lineOpacity: 0.7,
          filter: [
            'all',
            ['==', ['get', 'congestion'], 'moderate'],
            [
              'match',
              ['get', 'class'],
              'motorway', true,
              'trunk', true,
              'motorway_link', true,
              'tertiary', true,
              false
            ]
          ]
        )
      );
    } catch (e) {

    }
  }

  Future<void> addDestinationMarker(double longitude, double latitude) async {

    final currentLatLng = latlong.LatLng(locationProvider.currentPosition!.latitude, locationProvider.currentPosition!.longitude);
    final destinationLatLng = latlong.LatLng(latitude, longitude);

    final distance = latlong.Distance().distance(currentLatLng, destinationLatLng);

    pointAnnotationManager.deleteAll();
    PointAnnotationOptions pointAnnotationOptions = PointAnnotationOptions(
      geometry: Point(coordinates: Position(longitude, latitude)),
      image: destinationIconData,
      iconSize: 0.6,
    );
    pointAnnotationManager.create(pointAnnotationOptions);

    final bounds = CoordinateBounds(
      northeast: Point(coordinates: Position(currentLatLng.longitude, currentLatLng.latitude)),
      southwest: Point(coordinates: Position(longitude, latitude)),
      infiniteBounds: true
    );

    final camera = await mapboxMap!.cameraForCoordinateBounds(bounds, MbxEdgeInsets(left: 100, bottom: 100, right: 100, top: 100), 0, 0, 20, null);
    
    mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position((locationProvider.currentPosition!.longitude + longitude) / 2.0, (locationProvider.currentPosition!.latitude + latitude) / 2.0),
        ),
        zoom: camera.zoom
      ), 
      MapAnimationOptions(
        duration: 1000
    ));
  }


  List<Map<String, dynamic>> places = [];

  static double maxHeight = 1;

  void hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  late LocationProvider locationProvider;

  void closeReportWidget() {
    setState(() {
      homeState = HomeState.places;
    });
  }

  late List<Widget> draggableWidgets = [
    ReportsWidget(
      callback: (CallbackType callbackType, double? size) {
        switch (callbackType) {
          case CallbackType.close: {
            closeReportWidget();
            animatedJumpTo(0.14);
          }
          case CallbackType.cancel: {

          }
          case CallbackType.jumpTo: {
            animatedJumpTo(size!);
          }
        }
      }
    )
  ];

  void animatedJumpTo(double target) {
    final currentSize = iconPosition.value;
    final animation = Tween<double>(
      begin: currentSize,
      end: target
    ).animate(
      CurvedAnimation(
        parent: draggableAnimationController,
        curve: Curves.easeIn
      )
    );

    animation.addListener(() {
      draggableScrollableController.jumpTo(animation.value);
    });

    draggableAnimationController.forward(from: 0);
  }

  Future<AppOpenAdLoader> createAppOpenAdLoader() {
    return AppOpenAdLoader.create(
      onAdLoaded: (appOpenAd) {
        this.appOpenAd = appOpenAd;
        if (!isColdStartAdShown) {
          showAdIfAvailable();
          isColdStartAdShown = true;
        }
      },
      onAdFailedToLoad: (error) {
        setState(() {
          shouldNavigateToHome = true;
        });
      }
    );
  }

  Future<void> loadAppOpenAd() async {
    final adLoader = await appOpenAdLoader;
    await adLoader.loadAd(adRequestConfiguration: adRequestConfiguration);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (state == AppLifecycleState.resumed) {
    //   showAdIfAvailable();
    // }
  }

  void setAdEventListener({required AppOpenAd appOpenAd}) {
    appOpenAd.setAdEventListener(
      eventListener: AppOpenAdEventListener(
        onAdShown: () {
          isAdShowing = true;
        },
        onAdFailedToShow: (error) {
          clearAppOpenAd();
          setState(() {
            shouldNavigateToHome = true;
          });
        },
        onAdDismissed: () {
          isAdShowing = false;
          clearAppOpenAd();
          setState(() {
            shouldNavigateToHome = true;
          });
        },
        onAdClicked: () {
        },
        onAdImpression: (impressionData) {
        },
      )
    );
  }

  Future<void> showAdIfAvailable() async {
    if (appOpenAd != null && !isAdShowing) {
      setAdEventListener(appOpenAd: appOpenAd!);
      await appOpenAd?.show();
      await appOpenAd?.waitForDismiss();
    } else {
      loadAppOpenAd();
    }
  }

  void clearAppOpenAd() {
    appOpenAd?.destroy();
    appOpenAd = null;
  }

  double widgetSize = 0.4;

  CameraOptions? cameraOptionsSaved;
  CameraState? cameraState;

  bool isInitializated = false;

  void updateCameraOptions() async {
    if (isInitializated) {
      await ApplicationStorage.setCameraOptions(
        jsonEncode({
          'zoom': cameraState?.zoom.toDouble().toString(),
          'center': {
            'latitude': cameraState?.center.coordinates.lat.toDouble().toString(),
            'longitude': cameraState?.center.coordinates.lng.toDouble().toString()
          }
        })
      );
      cameraOptionsSaved = CameraOptions(
        zoom: cameraState?.zoom,
        center: Point(
          coordinates: Position(cameraState!.center.coordinates.lng, cameraState!.center.coordinates.lat)
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    locationProvider = context.watch<LocationProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapWidget(
              styleUri: themeProvider.themeMode == ThemeMode.light ? MapboxStyles.STANDARD : MapboxStyles.DARK,
              onMapCreated: onMapCreated,
              key: ValueKey(themeProvider.themeMode),
              cameraOptions: cameraOptionsSaved ?? CameraOptions(
                zoom: 10,
              ),
              onCameraChangeListener: (cameraChangedEventData) {
                cameraState = cameraChangedEventData.cameraState;
                updateCameraOptions();
              },
              onScrollListener: (context) {
                if (!mounted) return;
                setState(() {
                  isTracking = false;
                });
              },
              onZoomListener: (context) {
                if (!mounted) return;
                setState(() {
                  isTracking = false;
                });
              },
            ),
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              controller: draggableScrollableController,
              initialChildSize: 0.14,
              minChildSize: 0.14,
              maxChildSize: maxHeight,
              snap: true,
              expand: true,
              snapSizes: homeState == HomeState.places ? [0.4, maxHeight] : [widgetSize],
              builder: (context, scrollController) {
                return GestureDetector(
                  onTap: () {
                    hideKeyboard();
                  },
                  onVerticalDragDown: (details) {
                    hideKeyboard();
                  },
                  onTapMove: (details) {
                    hideKeyboard();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeProvider.themeMode == ThemeMode.light ? Colors.white : Color(0xFF252525),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24))
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            physics: homeState == HomeState.places ? ScrollPhysics() : NeverScrollableScrollPhysics(),
                            controller: scrollController,
                            padding: EdgeInsets.zero,
                            children: [
                              homeState == HomeState.places ? ValueListenableBuilder<double>(
                                valueListenable: iconPosition,
                                builder: (context, value, child) {
                                  return value != maxHeight ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 5,
                                        width: 60,
                                        margin: EdgeInsets.only(top: 12),
                                        decoration: BoxDecoration(
                                          color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525),
                                          borderRadius: BorderRadius.circular(16)
                                        ),
                                      ),
                                    ],
                                  ) : Container();
                                },
                              ) : Container(),
                              homeState == HomeState.places ? Column(
                                children: [
                                  ValueListenableBuilder<double>(
                                    valueListenable: iconPosition,
                                    builder: (context, value, child) {
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                              width: width * 0.9,
                                              height: 54,
                                              margin: EdgeInsets.only(top: value != maxHeight ? height * 0.02 : height * 0.06),
                                              decoration: BoxDecoration(
                                                color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Colors.grey.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(16)
                                              ),
                                              padding: EdgeInsets.only(left: width * 0.03),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.search, color: themeProvider.themeMode == ThemeMode.dark ? Color(0xFF252525) : Colors.black.withValues(alpha: 0.6), size: 30,),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: textEditingController,
                                                      cursorColor: Colors.black.withValues(alpha: 0.6),
                                                      onTap: () {
                                                        animatedJumpTo(1);
                                                      },
                                                      onChanged: (String value) {
                                                        getGeoPlaces(value, locationProvider.currentPosition!);
                                                      },
                                                      onSubmitted: (String value) {
                                                        getCoordinates(places[0]['mapbox_id']);
                                                        hideKeyboard();
                                                        applicationStorage.updateRecentlyPlaces(places[0]);
                                                        recentlyPlaces.insert(0, places[0]);
                                                      },
                                                      style: GoogleFonts.montserrat(color: Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.w400, fontSize: 18),
                                                      decoration: InputDecoration(
                                                        hintText: 'Куда едем?',
                                                        hintStyle: GoogleFonts.montserrat(color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.w400, fontSize: 18),
                                                        enabledBorder: InputBorder.none,
                                                        border: InputBorder.none,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              )
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: width,
                                        margin: EdgeInsets.only(top: 12),
                                        child: ListView.builder(
                                          itemCount: places.length,
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () {
                                                getCoordinates(places[index]['mapbox_id']);
                                                applicationStorage.updateRecentlyPlaces(places[index]);
                                                recentlyPlaces.insert(0, places[index]);
                                              },
                                              child: Container(
                                                margin: EdgeInsets.only(bottom: 12),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets.only(left: 12),
                                                          child: Icon(Icons.place_outlined, color: Colors.black, size: 30,),
                                                        ),
                                                        Container(
                                                          margin: EdgeInsets.only(left: 12),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              SizedBox(
                                                                width: width * 0.6,
                                                                child: Text(places[index]['name'].toString(), style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20), maxLines: 1,),
                                                              ),
                                                              SizedBox(
                                                                width: width * 0.6,
                                                                child: Text(places[index]['address'] ?? '', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 16), maxLines: 1,),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Container(
                                                      margin: EdgeInsets.only(right: 12),
                                                      child: Text((int.tryParse(places[index]['distance'].toString())! / 1000).toInt().toString() + ' km', style: GoogleFonts.montserrat(color: Colors.black, fontWeight: FontWeight.w400, fontSize: 16), maxLines: 1,),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        height: height * 0.1,
                                        margin: EdgeInsets.only(left: width * 0.05),
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Colors.grey.withValues(alpha: 0.1),
                                            shadowColor: Colors.transparent,
                                            overlayColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadiusGeometry.circular(16)
                                            )
                                          ),
                                          child: Center(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Icon(Icons.home, color: Color(0xFF252525), size: 40,),
                                                Text('Home', style: GoogleFonts.montserrat(color: Color(0xFF252525), fontSize: 16, fontWeight: FontWeight.w700),)
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: height * 0.1,
                                        margin: EdgeInsets.only(left: width * 0.05),
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Colors.grey.withValues(alpha: 0.1),
                                            shadowColor: Colors.transparent,
                                            overlayColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadiusGeometry.circular(16)
                                            )
                                          ),
                                          child: Center(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Icon(Icons.work, color: Color(0xFF252525), size: 40,),
                                                Text('Work', style: GoogleFonts.montserrat(color: Color(0xFF252525), fontSize: 16, fontWeight: FontWeight.w700),)
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(left: width * 0.05, top: 12),
                                        child: Text('Недавание', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontSize: 12),),
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: width,
                                        margin: EdgeInsets.only(top: 12),
                                        child: ListView.builder(
                                          physics: NeverScrollableScrollPhysics(),
                                          itemCount: recentlyPlaces.length,
                                          shrinkWrap: true,
                                          padding: EdgeInsets.zero,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () {
                                                getCoordinates(recentlyPlaces[index]['mapbox_id']);
                                                applicationStorage.updateRecentlyPlaces(recentlyPlaces[index]);
                                                hideKeyboard();
                                              },
                                              child: Container(
                                                margin: EdgeInsets.only(bottom: 12),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets.only(left: 12),
                                                          child: Icon(Icons.restore, color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), size: 30,),
                                                        ),
                                                        Container(
                                                          margin: EdgeInsets.only(left: 12),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              SizedBox(
                                                                width: width * 0.6,
                                                                child: Text(recentlyPlaces[index]['name'].toString(), style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w600, fontSize: 20), maxLines: 1,),
                                                              ),
                                                              SizedBox(
                                                                width: width * 0.6,
                                                                child: Text(recentlyPlaces[index]['address'] ?? '', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w400, fontSize: 16), maxLines: 1,),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ) : draggableWidgets.first,
                            ],
                          ),
                        )
                      ],
                    )
                  ),
                );
              },
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: iconPosition,
            builder: (context, value, child) {
              return value != maxHeight ? Positioned(
                left: 10,
                bottom: value * height + 10,
                child: !isTracking ? SizedBox(
                  width: 60,
                  height: 60,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        isTracking = true;
                      });
                      updateMapPosition(locationProvider.currentPosition!);
                    },
                    iconSize: 40,
                    style: IconButton.styleFrom(
                      backgroundColor: themeProvider.themeMode == ThemeMode.light ? Colors.white : Color(0xFF252525),
                      iconSize: 40,
                      padding: EdgeInsets.zero,
                      overlayColor: Colors.black
                    ),
                    icon: Icon(Icons.near_me, color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525),),
                  ),
                ) : Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeProvider.themeMode == ThemeMode.light ? Colors.white : Color(0xFF252525)
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(locationProvider.currentPosition!.speed.round().toString(), style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w500, fontSize: 18),),
                        Text('Km/h', style: GoogleFonts.montserrat(color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525), fontWeight: FontWeight.w500, fontSize: 10),)
                      ],
                    ),
                  ),
                )
              ) : Container();
            },
          ),
          homeState == HomeState.places ? ValueListenableBuilder<double>(
            valueListenable: iconPosition,
            builder: (context, value, child) {
              return value != maxHeight ? Positioned(
                right: 10,
                bottom: value * height + 10,
                child: isTracking ? SizedBox(
                  width: 60,
                  height: 60,
                  child: IconButton(
                    onPressed: () {
                      // update draggable
                      homeState = HomeState.reports;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          
                        });
                      });
                      animatedJumpTo(0.4);
                    },
                    iconSize: 40,
                    style: IconButton.styleFrom(
                      backgroundColor: Color(0xFFFB9726),
                      iconSize: 40,
                      padding: EdgeInsets.zero,
                      overlayColor: Colors.white
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.warning, color: themeProvider.themeMode == ThemeMode.light ? Colors.white : Color(0xFF252525),),
                  ),
                ) : Container()
              ) : Container();
            },
          ) : Container(),
          ValueListenableBuilder<double>(
            valueListenable: iconPosition,
            builder: (context, value, child) {
              return value < 0.65 ? Positioned(
                left: 10,
                top: height * 0.06,
                child: Container(
                  width: 60,
                  height: 60,
                  child: Center(
                    child: SizedBox(
                      width: value < 0.6 ? 60 : 60 - 600 * (value - 0.6),
                      height: value < 0.6 ? 60 : 60 - 600 * (value - 0.6),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            homeState = HomeState.settings;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: themeProvider.themeMode == ThemeMode.light ? Colors.white : Color(0xFF252525),
                          iconSize: value < 0.6 ? 30 : 30 - 300 * (value - 0.6),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(16)
                          )
                        ),
                        icon: Center(
                          child: Icon(Icons.dehaze, color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : Color(0xFF252525),),
                        )
                      ),
                    ),
                  )
                )
              ) : Container();
            },
          ),
          AnimatedPositioned(
            bottom: homeState == HomeState.settings ? 0 : -height,
            duration: Duration(milliseconds: 400),
            child: SettingsWidget(callback: () {
              setState(() {
                homeState = HomeState.places;
              });
            },)
          )
        ],
      )
    );
  }
}