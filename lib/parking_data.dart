import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';

class ParkingData {
  static List<Polygon> parkingLotPolygons = [];
  static Polyline? pathPolyline;
  static List<Marker> entranceMarkers = [];

  static Map<String, LatLng> entrances = {};
  static Map<String, Map<String, dynamic>> parkingLots = {}; // Keep this structure
  static Map<String, Map<String, double>> graph = {}; // Graph representation

  // Helper method to calculate the centroid of a polygon
  static LatLng calculateCentroid(List<LatLng> points) {
    double latitudeSum = 0;
    double longitudeSum = 0;

    for (var point in points) {
      latitudeSum += point.latitude;
      longitudeSum += point.longitude;
    }

    double centroidLat = latitudeSum / points.length;
    double centroidLng = longitudeSum / points.length;

    return LatLng(centroidLat, centroidLng);
  }

// Update loadGeoJson to store centroid instead of the first point
  static Future<bool> loadGeoJson(Function(String) showDialogCallback) async {
    try {
      // Load GeoJSON files
      String parkingGeoJson = await rootBundle.loadString('assets/parkinglot.geojson');
      String entranceGeoJson = await rootBundle.loadString('assets/entrance.geojson');

      final parkingData = jsonDecode(parkingGeoJson);
      final List parkingFeatures = parkingData['features'];

      // Clear existing polygons
      parkingLotPolygons.clear();
      parkingLots.clear();

      CollectionReference parkingCollection = FirebaseFirestore.instance.collection('ParkingLot');

      for (var feature in parkingFeatures) {
        final List coordinates = feature['geometry']['coordinates'][0];
        List<LatLng> points = coordinates.map<LatLng>((coord) {
          return LatLng(coord[1], coord[0]); // Correct latitude and longitude order
        }).toList();

        String parkingLotName = feature['properties']['Name'];
        DocumentSnapshot document = await parkingCollection.doc(parkingLotName).get();

        Color polygonColor;
        bool isVacant = false;
        if (document.exists) {
          isVacant = document.get('vacant');
          polygonColor = isVacant ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);
        } else {
          polygonColor = Colors.grey.withOpacity(0.5);
        }

        // Calculate the centroid of the parking lot
        LatLng centroid = calculateCentroid(points);

        parkingLotPolygons.add(
          Polygon(
            polygonId: PolygonId(parkingLotName),
            points: points,
            strokeColor: polygonColor,
            fillColor: polygonColor,
            strokeWidth: 2,
            consumeTapEvents: true,
            onTap: () {
              showDialogCallback(parkingLotName);
            },
          ),
        );

        // Store centroid as 'location' in parkingLots
        parkingLots[parkingLotName] = {
          'location': centroid, // Using centroid
          'vacant': isVacant,
          'coordinates': points
        };
      }

      // Parse entrances and initialize entranceMarkers and entrances map
      final entranceData = jsonDecode(entranceGeoJson);
      final List entranceFeatures = entranceData['features'];

      entranceMarkers.clear();
      for (var feature in entranceFeatures) {
        final List coordinates = feature['geometry']['coordinates'];
        LatLng entrancePoint = LatLng(coordinates[1], coordinates[0]);
        String entranceName = feature['properties']['Name'];

        entranceMarkers.add(
          Marker(
            markerId: MarkerId(entranceName),
            position: entrancePoint,
            icon: await getScaledMarkerIcon(70),
            infoWindow: InfoWindow(title: entranceName),
          ),
        );

        entrances[entranceName] = entrancePoint;
      }

      initializeGraph();

      return true; // Return true to indicate polygons were updated
    } catch (e) {
      print("Error in loadGeoJson: $e");
      return false;
    }
  }

// Update initializeGraph to use centroid
  static void initializeGraph() {
    print("Initializing graph...");
    entrances.forEach((entranceName, entranceLatLng) {
      graph[entranceName] = {};
      parkingLots.forEach((lotName, lotData) {
        if (lotData.containsKey('location') && lotData.containsKey('vacant')) {
          LatLng centroid = lotData['location']; // Use centroid
          double distance = _calculateDistance(entranceLatLng, centroid);
          graph[entranceName]![lotName] = distance;
          graph[lotName] = {entranceName: distance};
        }
      });
    });
    print("Graph initialized: $graph");
  }




// parking_data.dart

  static Stream<void> listenToParkingLotUpdates(Function(String) showDialogCallback) {
    return FirebaseFirestore.instance
        .collection('ParkingLot')
        .snapshots()
        .map((snapshot) {
      List<String> changedLots = [];

      // Build the new parking lots map with updated vacancy status only
      Map<String, Map<String, dynamic>> newParkingLots = {};

      for (var doc in snapshot.docs) {
        String lotId = doc.id;
        bool isVacant = doc.get('vacant') ?? false;

        // Check if the vacancy status has changed
        if (parkingLots[lotId]?['vacant'] != isVacant) {
          changedLots.add(lotId); // Add only the changed lots
        }

        // Update the newParkingLots structure
        newParkingLots[lotId] = {
          'vacant': isVacant,
          'location': parkingLots[lotId]?['location'] ?? LatLng(0, 0), // Keep existing location if available
          'coordinates': parkingLots[lotId]?['coordinates'] ?? [], // Keep existing coordinates if available
        };
      }

      // If there are any changes, update only the affected lots
      if (changedLots.isNotEmpty) {
        // Update the main parkingLots map
        parkingLots = {...parkingLots, ...newParkingLots};

        // Reload only the changed polygons
        for (var lot in changedLots) {
          _updatePolygonForLot(lot, showDialogCallback);
          print("Parking lot $lot updated.");
        }

        // Since we're mapping to void, we don't emit any specific data
      }
    });
  }


  static Future<void> _updatePolygonForLot(String lotId, Function(String) showDialogCallback) async {
    DocumentSnapshot document = await FirebaseFirestore.instance.collection('ParkingLot').doc(lotId).get();

    if (document.exists) {
      bool isVacant = document.get('vacant');
      Color polygonColor;

      // Set color based on lotId and vacancy status
      if (lotId == "OKU1" || lotId == "OKU2") {
        polygonColor = isVacant ? Colors.blue.withOpacity(0.5) : Colors.red.withOpacity(0.5);
      } else {
        polygonColor = isVacant ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);
      }

      // Find the polygon associated with the lotId and update its color
      int polygonIndex = parkingLotPolygons.indexWhere((polygon) => polygon.polygonId.value == lotId);
      if (polygonIndex >= 0) {
        Polygon updatedPolygon = Polygon(
          polygonId: PolygonId(lotId),
          points: parkingLots[lotId]!['coordinates'],
          strokeColor: polygonColor,
          fillColor: polygonColor,
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () {
            showDialogCallback(lotId);
          },
        );

        // Replace the old polygon with the updated one
        parkingLotPolygons[polygonIndex] = updatedPolygon;
      }
    }
  }




  static Future<BitmapDescriptor> getScaledMarkerIcon(int markerSize) async {
    try {
      final ByteData byteData = await rootBundle.load('assets/images/custom_marker.png');
      final Uint8List imageData = byteData.buffer.asUint8List();

      final ui.Codec codec = await ui.instantiateImageCodec(imageData, targetWidth: markerSize);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      final ByteData? resizedBytes = await image.toByteData(format: ui.ImageByteFormat.png);

      if (resizedBytes != null) {
        return BitmapDescriptor.fromBytes(resizedBytes.buffer.asUint8List());
      } else {
        throw Exception("Failed to resize marker");
      }
    } catch (e) {
      print("Error loading custom marker icon: $e");
      return BitmapDescriptor.defaultMarker;
    }
  }



  // Haversine formula to calculate distance between two LatLng points
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371; // Radius of the Earth in kilometers
    double latDistance = (point2.latitude - point1.latitude) * pi / 180;
    double lonDistance = (point2.longitude - point1.longitude) * pi / 180;
    double a = sin(latDistance / 2) * sin(latDistance / 2) +
        cos(point1.latitude * pi / 180) * cos(point2.latitude * pi / 180) *
            sin(lonDistance / 2) * sin(lonDistance / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

// Dijkstra's algorithm for shortest path, only considering vacant parking lots
  static String? findShortestPath(String startNode) {
    if (graph[startNode] == null) {
      print("Error: Start node $startNode does not exist in the graph.");
      return null;
    }

    Map<String, double> distances = {};
    Map<String, String?> previousNodes = {};
    Set<String> unvisitedNodes = {};

    // Initialize distances
    graph.keys.forEach((node) {
      distances[node] = double.infinity;
      previousNodes[node] = null;
      unvisitedNodes.add(node);
    });
    distances[startNode] = 0;

    while (unvisitedNodes.isNotEmpty) {
      // Find the node with the smallest distance
      String? closestNode;
      double shortestDistance = double.infinity;
      for (String node in unvisitedNodes) {
        if (distances[node]! < shortestDistance) {
          shortestDistance = distances[node]!;
          closestNode = node;
        }
      }

      if (closestNode == null) break;

      // Remove the closest node from unvisited nodes
      unvisitedNodes.remove(closestNode);

      // Calculate distances for neighbors of the closest node
      graph[closestNode]?.forEach((neighbor, distance) {
        double alternativeRoute = distances[closestNode]! + distance;
        if (alternativeRoute < distances[neighbor]!) {
          distances[neighbor] = alternativeRoute;
          previousNodes[neighbor] = closestNode;
        }
      });
    }

    // Find the nearest vacant parking lot from the starting node, excluding OKU1 and OKU2
    String? nearestParkingLot;
    double shortestPathDistance = double.infinity;
    parkingLots.forEach((parkingLot, lotData) {
      // Only consider vacant parking lots, excluding OKU1 and OKU2
      if (lotData['vacant'] && distances[parkingLot]! < shortestPathDistance && parkingLot != "OKU1" && parkingLot != "OKU2") {
        shortestPathDistance = distances[parkingLot]!;
        nearestParkingLot = parkingLot;
      }
    });

    if (nearestParkingLot != null) {
      print("Nearest vacant parking lot to $startNode is $nearestParkingLot with distance $shortestPathDistance");
      return nearestParkingLot;
    } else {
      print("No nearby vacant parking lot found for $startNode.");
      return null;
    }
  }

}
