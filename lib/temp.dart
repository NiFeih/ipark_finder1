import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';


class ParkingData {
  static List<Polygon> parkingLotPolygons = [];
  static Polyline? pathPolyline;
  static List<LatLng> pathCoordinates = [];
  static List<Marker> entranceMarkers = [];

  // Load and parse the GeoJSON data, passing in the callback for showing a dialog
  static Future<void> loadGeoJson(Function(String) showDialogCallback) async {
    // Load GeoJSON for parking lots and path
    String parkingGeoJson = await rootBundle.loadString('assets/parkinglots.geojson');
    String pathGeoJson = await rootBundle.loadString('assets/path_new.geojson');
    String entranceGeoJson = await rootBundle.loadString('assets/entrance.geojson');

    // Parse Parking Lot GeoJSON
    final parkingData = jsonDecode(parkingGeoJson);
    final List parkingFeatures = parkingData['features'];

    // Clear the previous polygons
    parkingLotPolygons.clear();

    // Fetch all parking lot statuses from Firestore
    CollectionReference parkingCollection = FirebaseFirestore.instance.collection('ParkingLot');

    // Parse each parking lot and check against Firestore
    for (var feature in parkingFeatures) {
      final List coordinates = feature['geometry']['coordinates'][0];
      List<LatLng> points = coordinates.map<LatLng>((coord) {
        return LatLng(coord[1], coord[0]);  // LatLng expects [latitude, longitude]
      }).toList();

      // Get the polygon name
      String parkingLotName = feature['properties']['Name'];

      // Fetch parking lot data from Firestore
      DocumentSnapshot document = await parkingCollection.doc(parkingLotName).get();

      // Determine the polygon color
      Color polygonColor = Colors.blue.withOpacity(0.3);  // Default color
      if (document.exists) {
        bool isVacant = document.get('vacant');
        polygonColor = isVacant ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);
      }

      // Create and add the polygon to the list
      parkingLotPolygons.add(
        Polygon(
          polygonId: PolygonId(parkingLotName),
          points: points,
          strokeColor: polygonColor,
          fillColor: polygonColor,
          strokeWidth: 2,
          consumeTapEvents: true,  // Enable tap events for the polygon
          onTap: () {
            // Call the callback when the polygon is tapped
            showDialogCallback(parkingLotName);
          },
        ),
      );
    }

    // Parse Path GeoJSON
    final pathData = jsonDecode(pathGeoJson);
    final List pathCoordinatesData = pathData['features'][0]['geometry']['coordinates'];

    pathCoordinates = pathCoordinatesData.map<LatLng>((coord) {
      return LatLng(coord[1], coord[0]);  // LatLng expects [latitude, longitude]
    }).toList();

    // Create the polyline for the path
    pathPolyline = Polyline(
      polylineId: PolylineId('path'),
      points: pathCoordinates,
      color: Colors.red,
      width: 4,
    );

    // Parse Entrance GeoJSON and create markers
    final entranceData = jsonDecode(entranceGeoJson);
    final List entranceFeatures = entranceData['features'];

    // Clear previous markers
    entranceMarkers.clear();

    // Create custom entrance markers
    for (var feature in entranceFeatures) {
      final List coordinates = feature['geometry']['coordinates'];
      LatLng entrancePoint = LatLng(coordinates[1], coordinates[0]);

      // Get the entrance name
      String entranceName = feature['properties']['Name'];

      // Add the entrance marker
      entranceMarkers.add(
        Marker(
          markerId: MarkerId(entranceName),
          position: entrancePoint,
          icon: await getScaledMarkerIcon(70),  // Custom yellow marker with black outline
          infoWindow: InfoWindow(title: entranceName),
        ),
      );
    }
  }

  static Future<BitmapDescriptor> getScaledMarkerIcon(int markerSize) async {
    final ByteData byteData = await rootBundle.load('assets/images/custom_marker.png');
    final Uint8List imageData = byteData.buffer.asUint8List();

    // Adjust the marker size based on zoom level
    final ui.Codec codec = await ui.instantiateImageCodec(imageData, targetWidth: markerSize);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final ui.Image image = frameInfo.image;
    final ByteData? resizedBytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (resizedBytes != null) {
      return BitmapDescriptor.fromBytes(resizedBytes.buffer.asUint8List());
    } else {
      throw Exception("Failed to resize marker");
    }
  }


}

