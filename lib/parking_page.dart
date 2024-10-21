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
  // Add this Timer to track the navigation monitoring timer
  Timer? _navigationMonitorTimer;

  bool _hasReachedDestination = false;

  final LatLngBounds _intiBounds = LatLngBounds(
    southwest: LatLng(5.3407917, 100.2809528),
    northeast: LatLng(5.3424806, 100.2827500),
  );

  final LatLng _center = LatLng(5.3416, 100.2818);
  // LatLng _userLocation = LatLng(5.34158, 100.28234); // User's fixed location at guardhouse
  LatLng _userLocation = LatLng(5.34165, 100.28212); // User's fixed location

  final String _mapStyle = '''
  [
    {
      "featureType": "poi",
      "stylers": [
        { "visibility": "off" }
      ]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    ParkingData.loadGeoJson(_showParkingLotDialog).then((_) {
      setState(() {}); // Refresh UI after data is loaded
    }).catchError((e) {
      print("Error loading GeoJSON data: $e");
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCustomUserMarker(_currentZoom);
  }

  // Load custom user marker from assets and resize it based on zoom level
  void _loadCustomUserMarker(double zoom) async {
    try {
      final ByteData data = await rootBundle.load('assets/images/user_marker.png');
      final Uint8List bytes = data.buffer.asUint8List();

      // Decode the image from the bytes
      img.Image? baseSizeImage = img.decodeImage(bytes);
      if (baseSizeImage == null) {
        print("Failed to decode image.");
        return;
      }

      // Resize the image based on the current zoom level
      int newSize = (100 + (zoom - 1) * 10).toInt();// Adjusted formula for larger size // Adjust the size based on zoom
      newSize = newSize.clamp(100, 250); // Limit the size within a range
      img.Image resizedImage = img.copyResize(baseSizeImage, width: newSize, height: newSize);

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
    if ((_currentZoom - newZoom).abs() >= 0.1) { // Update if zoom changed significantly
      _currentZoom = newZoom;
      _loadCustomUserMarker(_currentZoom); // Reload marker with new size
    }
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

  // Show a dialog box displaying the nearest parking lot
  void _showNearestParkingLotDialog(String entranceName) {
    String? nearestParkingLot = ParkingData.findShortestPath(entranceName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Nearest Parking Lot"),
          content: Text(
            nearestParkingLot != null
                ? "The nearest parking lot to $entranceName is: $nearestParkingLot"
                : "No nearby parking lot found.",
          ),
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



  void _startMovingAlongPath() {
    if (_navigationPoints.isEmpty) {
      print("No navigation path available.");
      return;
    }

    int currentIndex = 0;

    // Timer to update the user location along the path
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (currentIndex >= _navigationPoints.length - 1) {
        timer.cancel();
        print("User has reached the destination.");
        _showReachedDestinationDialog(); // Show the reached destination dialog
        return;
      }

      // Update the user's location to the next point in the path
      LatLng currentLocation = _navigationPoints[currentIndex];
      LatLng nextLocation = _navigationPoints[currentIndex + 1];

      setState(() {
        _userLocation = currentLocation;
      });

      // Calculate the bearing to face the next point
      double bearing = _calculateBearing(currentLocation, nextLocation);

      // Animate the camera to follow the updated user location and bearing
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLocation,
            zoom: 20,
            bearing: bearing,
          ),
        ),
      );

      // Increment the index to move to the next point
      currentIndex++;
    });
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

    // Start moving along the path
    _startMovingAlongPath();
  }

// Helper method to calculate the centroid of a polygon
  LatLng _calculateCentroid(List<LatLng> points) {
    double latitudeSum = 0.0;
    double longitudeSum = 0.0;

    for (var point in points) {
      latitudeSum += point.latitude;
      longitudeSum += point.longitude;
    }

    return LatLng(latitudeSum / points.length, longitudeSum / points.length);
  }



  // Method to show a dialog box when the user reaches the destination
  void _showReachedDestinationDialog() {
    if (!_isNavigating || _hasReachedDestination) return; // Prevent showing the dialog if navigation is stopped or already reached

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


  // Updated _monitorNavigation method
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

// Check proximity to destination
  bool _isCloseToDestination(LatLng currentLocation) {
    if (_destination == null) return false; // Handle null case

    // Calculate the absolute difference between the current and destination latitudes
    double latDiff = (currentLocation.latitude - _destination!.latitude).abs();

    // Calculate the absolute difference between the current and destination longitudes
    double lngDiff = (currentLocation.longitude - _destination!.longitude).abs();

    // Check if both latitude and longitude differences are within the defined proximity threshold
    return latDiff < _proximityThreshold && lngDiff < _proximityThreshold;
  }



  // Method to show confirmation before stopping navigation
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

  // Stop Navigation method
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

  // Update the _onMapCreated method to use the custom marker
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.setMapStyle(_mapStyle).then((_) {
      print("Map style applied successfully.");
    }).catchError((error) {
      print("Error applying map style: $error");
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _center,
          zoom: 19.5,
          bearing: -36.0,
        ),
      ),
    );

    // Add user location marker with the custom icon
    setState(() {
      ParkingData.entranceMarkers.add(Marker(
        markerId: MarkerId('user_location'),
        position: _userLocation,
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: _customUserMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue
        ),
      ));
    });

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
      _showParkingLotDialog(nearestParkingLot);
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
                  if (!_isNavigating) { // Only allow tap if not navigating
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
                  if (!_isNavigating) { // Only allow tap if not navigating
                    final markerIdValue = marker.markerId?.value;
                    if (markerIdValue != null) {
                      _onEntranceTapped(markerIdValue);
                    } else {
                      print("Marker ID or its value is null.");
                    }
                  }
                },
              );
            }).toSet()
              ..add(Marker(
                markerId: MarkerId('user_location'),
                position: _userLocation,
                infoWindow: InfoWindow(title: 'Your Location'),
                icon: _customUserMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                anchor: Offset(0.5, 0.5), // Center the marker
              ))
            // Add the destination marker if navigating
              ..addAll(_isNavigating && _destination != null
                  ? [
                Marker(
                  markerId: MarkerId('destination'),
                  position: _destination!,
                  infoWindow: InfoWindow(title: 'Destination'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
                    _mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: targetLocation,
                          zoom: 19.5,
                          bearing: -36.0,
                        ),
                      ),
                    );
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
