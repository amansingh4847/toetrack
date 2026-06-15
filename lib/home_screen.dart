import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:screenshot/screenshot.dart';
import 'package:toetrack/summary_screen.dart';
import 'dart:async';
import 'dart:typed_data';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng? currentLocation; //this can be null so using ?
  final MapController mapController =
      MapController(); //to control the camera on map wrt our live location

  StreamSubscription<Position>? positionStream;

  @override
  void dispose() {
    positionStream?.cancel();

    runTimer?.cancel();

    super.dispose();
  }

  final ScreenshotController screenshotController = ScreenshotController();

  Uint8List? runImage;
  bool isTracking = false;

  List<LatLng> routePoints = [];

  double distanceCovered = 0.0;

  Timer? runTimer;

  int elapsedSeconds = 0;

  String smoothedPace = "--:--";

  double nextPaceUpdate = 100;

  void updateSmoothedPace() {
    smoothedPace = calculatePace();
  }

  //func banaya to get curr loc everytime the app open or screen get loaded
  Future<void> getCurrentLocation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
    mapController.move(currentLocation!, 16);
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  //trackking start krne ka function
  void startTracking() {
    setState(() {
      isTracking = true;

      distanceCovered = 0;

      elapsedSeconds = 0;

      routePoints.clear();

      smoothedPace = "--:--";

      nextPaceUpdate = 100;

      if (currentLocation != null) {
        routePoints.add(currentLocation!);
      }
    });

    startTimer();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,

      distanceFilter: 10,
    );

    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            LatLng newPoint = LatLng(position.latitude, position.longitude);

            if (routePoints.isNotEmpty) {
              LatLng lastPoint = routePoints.last;

              double movement = Geolocator.distanceBetween(
                lastPoint.latitude,

                lastPoint.longitude,

                newPoint.latitude,

                newPoint.longitude,
              );

              // Ignore tiny GPS movements
              if (movement < 5) return;

              setState(() {
                distanceCovered += movement;

                currentLocation = newPoint;

                routePoints.add(newPoint);

                if (distanceCovered >= nextPaceUpdate) {
                  updateSmoothedPace();

                  nextPaceUpdate += 100;
                }
              });
            } else {
              setState(() {
                currentLocation = newPoint;

                routePoints.add(newPoint);
              });
            }

            mapController.move(newPoint, mapController.camera.zoom);
          },
        );
  }

  Future<void> stopTracking() async {
    positionStream?.cancel();

    stopTimer();

    await captureRun();

    setState(() {
      isTracking = false;
    });

    if (runImage == null) return;

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) => SummaryScreen(
          image: runImage!,

          onDone: () {
            resetRun();
          },
        ),
      ),
    );
  }

  //to start the run timmer
  void startTimer() {
    runTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
      });
    });
  }

  void stopTimer() {
    runTimer?.cancel();
  }

  String formatTime() {
    int hours = elapsedSeconds ~/ 3600;

    int minutes = (elapsedSeconds % 3600) ~/ 60;

    int seconds = elapsedSeconds % 60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  //for pace
  String calculatePace() {
    if (distanceCovered == 0) {
      return "--:--";
    }

    double distanceKm = distanceCovered / 1000;

    double paceMinutes = (elapsedSeconds / 60) / distanceKm;

    int minutes = paceMinutes.floor();

    int seconds = ((paceMinutes - minutes) * 60).round();

    return "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  void resetRun() {
    setState(() {
      isTracking = false;

      distanceCovered = 0;

      elapsedSeconds = 0;

      routePoints.clear();

      smoothedPace = "--:--";

      nextPaceUpdate = 100;
    });
  }

  Future<void> captureRun() async {
    runImage = await screenshotController.capture();
  }

  //for screen shot babay
  Widget trackingArea() {
    return Column(
      children: [
        // Map
        Expanded(
          flex: 4,

          child: Container(
            width: double.infinity,

            decoration: BoxDecoration(
              color: Colors.grey.shade900,

              borderRadius: BorderRadius.circular(12),
            ),

            child: FlutterMap(
              mapController: mapController,

              options: MapOptions(
                initialCenter: LatLng(28.6139, 77.2090),

                initialZoom: 15,
              ),

              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                  userAgentPackageName: 'com.example.toetrack',
                ),

                if (routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,

                        strokeWidth: 7,

                        color: Colors.lightGreen,

                        strokeCap: StrokeCap.round,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    if (currentLocation != null)
                      Marker(
                        point: currentLocation!,

                        width: 80,

                        height: 80,

                        child: const Icon(
                          Icons.location_on,

                          color: Colors.red,

                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Stats widget
        Container(
          width: double.infinity,

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.grey.shade900,

            borderRadius: BorderRadius.circular(12),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                formatTime(),

                style: const TextStyle(
                  fontSize: 20,

                  color: Colors.lightGreen,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text("Distance"),

                      Text(
                        "${(distanceCovered / 1000).toStringAsFixed(2)} km",

                        style: const TextStyle(
                          fontSize: 32,

                          color: Colors.lightGreen,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  Column(
                    children: [
                      const Text("Pace"),

                      Text(
                        smoothedPace,

                        style: const TextStyle(
                          fontSize: 38,

                          color: Colors.lightGreen,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Text("min/km"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'ToeTrack',
          style: TextStyle(
            color: Colors.lightGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //const SizedBox(height: 24),
            Expanded(
              child: Screenshot(
                controller: screenshotController,

                child: trackingArea(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  if (isTracking) {
                    stopTracking();
                  } else {
                    startTracking();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTracking ? Colors.red : Colors.lightGreen,
                  foregroundColor: Colors.black,
                ),
                child: Text(isTracking ? "STOP RUN" : "START RUN"),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
