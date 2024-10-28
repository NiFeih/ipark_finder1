import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'parking_data.dart';
import 'navigation_service.dart'; // Ensure to import your navigation service
import 'dart:async'; // Import this to use Timer
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:math' as math;

class ParkingPage extends StatefulWidget {
  @override
  _ParkingPageState createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  GoogleMapController? _mapController;
  bool _isMapLoading = true; // Add loading flag
  bool _isNavigating = false; // Track navigation state
  List<LatLng> _navigationPoints = []; // Store points for navigation
  LatLng? _destination; // Make it nullable
  static const double _proximityThreshold = 0.00008; // Proximity threshold in degrees
  BitmapDescriptor? _customUserMarker; // Add this to hold the custom marker
  double _currentZoom = 17.0; // Track the current zoom level
  Timer? _navigationMonitorTimer; // Add this Timer to track the navigation monitoring timer
  String? _selectedLotId;
  bool _hasReachedDestination = false;

  // Keep track of the current bearing
  double _currentBearing = 0.0;

  // Add a StreamSubscription to manage the Firestore listener
  StreamSubscription? _parkingLotListener;


  // Add this line to declare the subscription variable
  StreamSubscription<void>? _parkingLotSubscription;


  final LatLngBounds _intiBounds = LatLngBounds(
    southwest: LatLng(5.3407917, 100.2809528),
    northeast: LatLng(5.3424806, 100.2827500),
  );
  final double proximityRadius = 100; // Define the proximity radius in meters
  final LatLng _center = LatLng(5.3416, 100.2818);
  LatLng _userLocation = LatLng(5.34165, 100.28212); // User's fixed location
  // LatLng _userLocation = LatLng(5.3417, 100.2817); // User's fixed location centre of inti
  // LatLng _userLocation = LatLng(5.341036, 100.282686); // User's fixed location outside of inti

  final String _mapStyle = '''
[
  {
    "featureType": "poi",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi.school",
    "stylers": [
      { "visibility": "on" }
    ]
  }
]

  ''';

  @override
  void initState() {
    super.initState();

    // Update _showParkingLotDialog to accept the additional parameter
    ParkingData.listenToParkingLotUpdates(_showParkingLotDialog, (double zoomLevel, String lotId) {
      if (mounted) {
        setState(() {
          _currentZoom = zoomLevel; // Update the current zoom level
          _selectedLotId = lotId;   // Optionally, store the changed lot ID if needed
        });
      }
    }).listen((_) {
      // Optional: handle additional state changes if necessary
    });

    // Load initial parking lot data
    ParkingData.loadGeoJson(_showParkingLotDialog).then((_) {
      setState(() {});
    }).catchError((e) {
      print("Error loading GeoJSON data: $e");
    });
  }


  @override
  void dispose() {
    _parkingLotSubscription?.cancel(); // Cancel subscription on dispose
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCustomUserMarker(_currentZoom);
  }

  // Load custom user marker from assets and resize it based on zoom level
  void _loadCustomUserMarker(double zoom) async {
    try {
      final ByteData data = await rootBundle.load(
          'assets/images/user_marker.png');
      final Uint8List bytes = data.buffer.asUint8List();

      // Decode the image from the bytes
      img.Image? baseSizeImage = img.decodeImage(bytes);
      if (baseSizeImage == null) {
        print("Failed to decode image.");
        return;
      }

      // Resize the image based on the current zoom level
      int newSize = (100 + (zoom - 1) * 10)
          .toInt(); // Adjusted formula for larger size
      newSize = newSize.clamp(100, 250); // Limit the size within a range
      img.Image resizedImage = img.copyResize(
          baseSizeImage, width: newSize, height: newSize);

      // Convert the resized image to bytes
      final ui.Codec codec = await ui.instantiateImageCodec(
        Uint8List.fromList(img.encodePng(resizedImage)),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();

      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        print("Failed to convert image to ByteData.");
        return;
      }

      final Uint8List resizedBytes = byteData.buffer.asUint8List();

      // Convert the resized bytes into a BitmapDescriptor
      _customUserMarker = BitmapDescriptor.fromBytes(resizedBytes);

      setState(() {}); // Refresh the UI after loading the custom marker
    } catch (e) {
      print("Error loading custom user marker: $e");
    }
  }

  // Callback when the camera moves
  void _onCameraMove(CameraPosition position) {
    double newZoom = position.zoom;
    if ((_currentZoom - newZoom).abs() >=
        0.1) { // Update if zoom changed significantly
      _currentZoom = newZoom;
      _loadCustomUserMarker(_currentZoom); // Reload marker with new size
    }
  }


  // Function to calculate distance between two LatLng points
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // Earth radius in meters
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(start.latitude)) * math.cos(_degreesToRadians(end.latitude)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c; // Return distance in meters
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  void _showParkingLotDialog(String parkingLotName) {
    bool isVacant = ParkingData.parkingLots[parkingLotName]?['vacant'] ?? false;
    if (isVacant) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Navigate to $parkingLotName"),
            content: Text("Do you want to navigate to $parkingLotName?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _navigateToParkingLot(parkingLotName);
                },
                child: Text("Confirm"),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$parkingLotName is currently not vacant.")),
      );
    }
  }

  void _showNearestParkingLotDialog(String parkingLotName) {
    bool isVacant = ParkingData.parkingLots[parkingLotName]?['vacant'] ?? false;
    if (isVacant) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("The nearest parking lot to the entrance is $parkingLotName"),
            content: Text("Do you want to navigate to $parkingLotName?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _navigateToParkingLot(parkingLotName);
                },
                child: Text("Confirm"),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$parkingLotName is currently not vacant.")),
      );
    }
  }
  // Calculate the bearing from one LatLng to another
  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * (math.pi / 180.0);
    double startLng = start.longitude * (math.pi / 180.0);
    double endLat = end.latitude * (math.pi / 180.0);
    double endLng = end.longitude * (math.pi / 180.0);

    double dLng = endLng - startLng;
    double y = math.sin(dLng) * math.cos(endLat);
    double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    double bearing = math.atan2(y, x);
    bearing = bearing * (180.0 / math.pi);
    bearing = (bearing + 360.0) % 360.0;

    return bearing;
  }

  void _startMovingAlongPath(String parkingLotName) {
    if (_navigationPoints.isEmpty) {
      print("No navigation path available.");
      return;
    }

    int currentIndex = 0;

    // Set the initial user location
    LatLng currentLocation = _userLocation;

    // Calculate the initial bearing to face the first navigation point
    double initialBearing = _calculateBearing(currentLocation, _navigationPoints[currentIndex]);

    // Set the camera to zoom level 25 at the start of navigation, facing the first point
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _navigationPoints[currentIndex],
          zoom: 25, // Set the zoom level to 25 when starting navigation
          bearing: initialBearing, // Set the initial bearing based on user perspective
        ),
      ),
    );

    // Timer to update the user location along the path
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (currentIndex >= _navigationPoints.length - 1) {
        timer.cancel();
        print("User has reached the destination.");
        _showReachedDestinationDialog(); // Show the reached destination dialog
        return;
      }

      // Update the user's location to the next point in the path
      LatLng nextLocation = _navigationPoints[currentIndex + 1];

      // Check the current destination parking lot for vacancy
      bool isVacant = ParkingData.parkingLots[parkingLotName]?['vacant'] ?? false;

      // Print statement to debug
      print("Checking vacancy for: $parkingLotName, Is vacant: $isVacant");

      // If the parking lot is not vacant, show a notification and stop navigation
      if (!isVacant) {
        // Stop the navigation
        _stopNavigation();
        // Show a notification for the occupied parking lot
        _showOccupiedParkingLotDialog(parkingLotName);
        timer.cancel(); // Stop navigation if the parking lot is occupied
        return;
      }

      setState(() {
        currentLocation = _navigationPoints[currentIndex];
        _userLocation = currentLocation;
      });

      // Calculate the new bearing to face the next point
      double newBearing = _calculateBearing(currentLocation, nextLocation);

      // Get the current camera position
      _mapController?.getVisibleRegion().then((LatLngBounds bounds) {
        double bearingChange = (_currentBearing - newBearing).abs();
        if (bearingChange >= 20.0) {
          _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: currentLocation,
                  zoom: 25,
                  bearing: newBearing,
                ),
              ),
              );

              _currentBearing = newBearing; // Update the tracked bearing
              } else {
              _mapController?.animateCamera(
              CameraUpdate.newLatLng(_userLocation),
              );
              }
          });

      // Increment the index to move to the next point
      currentIndex++;
    });
  }





  void _showOccupiedParkingLotDialog(String parkingLotName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Parking Lot Occupied"),
          content: Text("$parkingLotName is currently occupied."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }




  Future<void> _navigateToParkingLot(String parkingLotName) async {
    setState(() {
      _isNavigating = true;
    });

    // Retrieve the list of coordinates representing the corners of the parking lot
    List<LatLng>? parkingLotCoordinates = ParkingData.parkingLots[parkingLotName]?['coordinates'];

    LatLng parkingLotCenter;

    if (parkingLotCoordinates != null && parkingLotCoordinates.isNotEmpty) {
      // Calculate the centroid if the coordinates are available
      parkingLotCenter = _calculateCentroid(parkingLotCoordinates);
    } else {
      // Fallback to the 'location' if the coordinates are not available
      LatLng? fallbackLocation = ParkingData.parkingLots[parkingLotName]?['location'];
      if (fallbackLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No coordinates or location available for $parkingLotName.")),
        );
        setState(() {
          _isNavigating = false; // Reset the navigation state
        });
        return;
      }
      parkingLotCenter = fallbackLocation;
    }

    // Set the destination to the calculated center
    _destination = parkingLotCenter;

    // Fetch the custom path for navigation
    List<LatLng> customPath = await NavigationService.fetchCustomPathSegment(
      _userLocation,
      _destination!,
    );

    setState(() {
      ParkingData.pathPolyline = Polyline(
        polylineId: PolylineId('custom_route'),
        points: customPath,
        color: Colors.blue,
        width: 5,
      );

      _navigationPoints = customPath;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_navigationPoints[0]),
    );

    _monitorNavigation();

    // Start moving along the path, passing the parking lot name
    _startMovingAlongPath(parkingLotName);
  }


  LatLng _calculateCentroid(List<LatLng> points) {
    double latitudeSum = 0.0;
    double longitudeSum = 0.0;

    for (var point in points) {
      latitudeSum += point.latitude;
      longitudeSum += point.longitude;
    }

    return LatLng(latitudeSum / points.length, longitudeSum / points.length);
  }

  void _showReachedDestinationDialog() {
    if (!_isNavigating || _hasReachedDestination)
      return; // Prevent showing the dialog if navigation is stopped or already reached

    _hasReachedDestination = true; // Set the flag to true

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("You Have Arrived"),
          content: Text("You have reached your destination."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _stopNavigation(); // Stop the navigation
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _monitorNavigation() {
    // Cancel any previous timer if still active
    _navigationMonitorTimer?.cancel();

    _navigationMonitorTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isCloseToDestination(_userLocation)) {
        _showReachedDestinationDialog(); // Show the dialog when the destination is reached
        timer.cancel(); // Stop the timer
        _navigationMonitorTimer = null;
      }
    });
  }

  bool _isCloseToDestination(LatLng currentLocation) {
    if (_destination == null) return false; // Handle null case

    // Calculate the absolute difference between the current and destination latitudes
    double latDiff = (currentLocation.latitude - _destination!.latitude).abs();

    // Calculate the absolute difference between the current and destination longitudes
    double lngDiff = (currentLocation.longitude - _destination!.longitude)
        .abs();

    // Check if both latitude and longitude differences are within the defined proximity threshold
    return latDiff < _proximityThreshold && lngDiff < _proximityThreshold;
  }

  void _confirmStopNavigation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Stop Navigation"),
          content: Text("Are you sure you want to cancel the navigation?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _stopNavigation(); // Call the stop navigation method
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false; // Set navigation state to false
      _hasReachedDestination = false; // Reset the reached destination flag
      ParkingData.pathPolyline = null; // Clear the polyline
      _navigationPoints.clear(); // Clear navigation points
    });

    // Cancel the navigation monitor timer
    _navigationMonitorTimer?.cancel();
    _navigationMonitorTimer = null;

    // Animate the camera back to the center of Inti Penang
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _center, // Center of Inti Penang
          zoom: 19.5, // Desired zoom level
          bearing: -36.0, // Desired bearing
        ),
      ),
    );

    // Show a snack bar to inform the user that navigation has stopped
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Navigation stopped.")),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.setMapStyle(_mapStyle).then((_) {
      print("Map style applied successfully.");
    }).catchError((error) {
      print("Error applying map style: $error");
    });

    // Check if the user location marker already exists
    if (ParkingData.entranceMarkers.every((marker) =>
    marker.markerId.value != 'user_location')) {
      ParkingData.entranceMarkers.add(Marker(
        markerId: MarkerId('user_location'),
        position: _userLocation,
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: _customUserMarker ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        anchor: Offset(0.5, 0.5), // Center the marker
      ));
    }

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _center,
          zoom: 19.5,
          bearing: -36.0,
        ),
      ),
    );

    // Add a one-second delay before setting `_isMapLoading` to false
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        _isMapLoading = false;
      });
    });
  }


  void _onEntranceTapped(String entranceName) async {
    String? nearestParkingLot = ParkingData.findShortestPath(entranceName);
    if (nearestParkingLot != null) {
      _showNearestParkingLotDialog(nearestParkingLot);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No nearby vacant parking lot found.")),
      );
    }
  }

  int _getAvailableLotsCount() {
    return ParkingData.parkingLots.values
        .where((lot) => lot['vacant'] == true)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: _currentZoom,
            ),
            mapType: MapType.normal,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            polygons: ParkingData.parkingLotPolygons.map((polygon) {
              return polygon.copyWith(
                consumeTapEventsParam: true,
                onTapParam: () {
                  if (!_isNavigating) {
                    _showParkingLotDialog(polygon.polygonId.value);
                  }
                },
              );
            }).toSet(),
            polylines: ParkingData.pathPolyline != null
                ? {ParkingData.pathPolyline!}
                : {},
            markers: ParkingData.entranceMarkers.map((marker) {
              return marker.copyWith(
                onTapParam: () {
                  if (!_isNavigating) {
                    final markerIdValue = marker.markerId?.value;
                    if (markerIdValue != null) {
                      _onEntranceTapped(markerIdValue);
                    }
                  }
                },
              );
            }).toSet()
              ..add(Marker(
                markerId: MarkerId('user_location'),
                position: _userLocation,
                infoWindow: InfoWindow(title: 'Your Location'),
                icon: _customUserMarker ??
                    BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue),
                anchor: Offset(0.5, 0.5),
              ))
              ..addAll(_isNavigating && _destination != null
                  ? [
                Marker(
                  markerId: MarkerId('destination'),
                  position: _destination!,
                  infoWindow: InfoWindow(title: 'Destination'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
              ]
                  : []),
            cameraTargetBounds: CameraTargetBounds(_intiBounds),
            minMaxZoomPreference: MinMaxZoomPreference(19.5, 22),
          ),

          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.0),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 5,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Level 2",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Available Lots: ${_getAvailableLotsCount()}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isNavigating)
            Positioned(
              bottom: 100,
              right: 9,
              child: SizedBox(
                width: 60,
                height: 60,
                child: FloatingActionButton(
                  onPressed: _confirmStopNavigation,
                  child: Icon(Icons.stop, size: 30),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            right: 9,
            child: SizedBox(
              width: 60,
              height: 60,
              child: FloatingActionButton(
                onPressed: () {
                  if (_mapController != null) {
                    LatLng targetLocation = _isNavigating ? _userLocation : _center; // Change target based on navigation state

                    // If navigating, animate the camera to the user's location with current bearing
                    if (_isNavigating) {
                      _mapController!.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: targetLocation,
                            zoom: 25, // Set zoom level to 25
                            bearing: _currentBearing, // Use current bearing to face the path
                          ),
                        ),
                      );
                    } else {
                      // If not navigating, center on the starting point
                      _mapController!.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: targetLocation,
                            zoom: 19.5,
                            bearing: -36.0, // Adjust as necessary for your initial view
                          ),
                        ),
                      );
                    }
                  } else {
                    print("Map controller is not initialized yet.");
                  }
                },
                child: Icon(Icons.my_location, size: 20),
                backgroundColor: Colors.grey.withOpacity(0.5),
                foregroundColor: Colors.black,
              ),
            ),
          ),



          // Add the loading overlay
          if (_isMapLoading)
            AnimatedOpacity(
              opacity: _isMapLoading ? 1.0 : 0.0,
              duration: Duration(milliseconds: 500),
              child: Container(
                color: Colors.white,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}