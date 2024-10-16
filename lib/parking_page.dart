import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'parking_data.dart';

class ParkingPage extends StatefulWidget {
  @override
  _ParkingPageState createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  GoogleMapController? _mapController;
  double _currentZoomLevel = 19.5;

  final LatLngBounds _intiBounds = LatLngBounds(
    southwest: LatLng(5.3407917, 100.2809528),
    northeast: LatLng(5.3424806, 100.2827500),
  );

  final LatLng _center = LatLng(5.3416, 100.2818);

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

  // Show a dialog box displaying the nearest parking lot
  void _showParkingLotDialog(String parkingLotName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Nearest Parking Lot"),
          content: Text("The nearest parking lot is: $parkingLotName"),
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

  // Map creation setup
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
  }

  // Handle tap on entrance markers to display nearest parking lot
  void _onEntranceTapped(String entranceName) {
    // Check if nearest parking lot is null and handle appropriately
    String? nearestParkingLot = ParkingData.findNearestParkingLot(entranceName);
    if (nearestParkingLot != null) {
      _showParkingLotDialog(nearestParkingLot);
    } else {
      _showParkingLotDialog("No nearby parking lot found.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Parking"),
        backgroundColor: Colors.purple,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 17.0,
            ),
            mapType: MapType.normal,
            onMapCreated: _onMapCreated,
            polygons: ParkingData.parkingLotPolygons.toSet(),
            polylines: ParkingData.pathPolyline != null
                ? {ParkingData.pathPolyline!}
                : {},
            markers: ParkingData.entranceMarkers.map((marker) {
              return marker.copyWith(
                onTapParam: () {
                  // Check if markerId and markerId.value are non-null
                  if (marker.markerId != null && marker.markerId.value != null) {
                    _onEntranceTapped(marker.markerId.value); // Trigger dialog on tap
                  } else {
                    print("Marker ID or its value is null.");
                  }
                },
              );
            }).toSet(),
            cameraTargetBounds: CameraTargetBounds(_intiBounds),
            minMaxZoomPreference: MinMaxZoomPreference(19.5, 22),
          ),
          Positioned(
            bottom: 100,
            right: 9,
            child: SizedBox(
              width: 45,
              height: 50,
              child: FloatingActionButton(
                onPressed: () {
                  if (_mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _center,
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
        ],
      ),
    );
  }
}
