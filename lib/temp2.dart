import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParkingPage extends StatefulWidget {
  @override
  _ParkingPageState createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  GoogleMapController? _mapController;

  // Coordinates for the map's center (near INTI College)
  static final LatLng _center = LatLng(5.3416, 100.2818);

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
              zoom: 17.0,  // Set initial zoom level
            ),
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: {
              Marker(
                markerId: MarkerId('intiCollegeMarker'),
                position: _center,  // Marker at the center or any relevant location
                infoWindow: InfoWindow(
                  title: 'INTI International College Penang',
                  snippet: 'Parking Lot',
                ),
              ),
            },
          ),
          // Overlay the parking lot image with reduced size
          Positioned(
            top: 100,  // Adjust the top position as needed
            left: 50,  // Adjust the left position as needed
            child: Image.asset(
              'assets/Cropped_Floor_plan_Level_2.jpg',
              width: 150,  // Set the width to a smaller value
              height: 150, // Set the height to a smaller value
              fit: BoxFit.cover,  // Ensures the image maintains its aspect ratio
            ),
          ),
        ],
      ),
    );
  }
}
