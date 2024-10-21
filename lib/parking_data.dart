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

  static Future<bool> loadGeoJson(Function(String) showDialogCallback) async {
    try {
      // Load GeoJSON files
      String parkingGeoJson = await rootBundle.loadString('assets/parkinglots.geojson');
      String entranceGeoJson = await rootBundle.loadString('assets/entrance.geojson');

      final parkingData = jsonDecode(parkingGeoJson);
      final List parkingFeatures = parkingData['features'];

      // Clear existing polygons
      parkingLotPolygons.clear();
      parkingLots.clear();

      CollectionReference parkingCollection = FirebaseFirestore.instance.collection('ParkingLot');

      // Parse parking lots and initialize polygons and parkingLots map
      for (var feature in parkingFeatures) {
        final List coordinates = feature['geometry']['coordinates'][0];
        List<LatLng> points = coordinates.map<LatLng>((coord) {
          return LatLng(coord[1], coord[0]); // Correct latitude and longitude order
        }).toList();

        String parkingLotName = feature['properties']['Name'];
        DocumentSnapshot document = await parkingCollection.doc(parkingLotName).get();

        Color polygonColor = Colors.blue.withOpacity(0.3);
        bool isVacant = false;
        if (document.exists) {
          isVacant = document.get('vacant');
          polygonColor = isVacant ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);
        }

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

        print('Parsed points : $points');

        // **Ensure correct structure**: location (LatLng) and vacant (bool)
        parkingLots[parkingLotName] = {
          'location': points[0],  // Storing LatLng as 'location'
          'vacant': isVacant,      // Storing vacancy status as 'vacant'
          'coordinates': points  // List of LatLng points representing the corners
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
      return false; // Return false to indicate failure
    }
  }


  static Stream<void> listenToParkingLotUpdates(Function(String) showDialogCallback, Function(double) refreshUI) {
    return FirebaseFirestore.instance
        .collection('ParkingLot')
        .snapshots()
        .map((snapshot) {
      Map<String, bool> newParkingLots = {};
      for (var doc in snapshot.docs) {
        newParkingLots[doc.id] = doc.get('vacant') ?? false;
      }

      // Check if there are any changes in the parking lots
      bool hasChanges = false;
      if (parkingLots.length != newParkingLots.length) {
        hasChanges = true; // Different number of parking lots means change
      } else {
        for (var lot in newParkingLots.keys) {
          if (parkingLots[lot]?['vacant'] != newParkingLots[lot]) {
            hasChanges = true; // Found a difference
            break;
          }
        }
      }

      // If there are changes, reload the polygons
      if (hasChanges) {
        loadGeoJson(showDialogCallback).then((updated) {
          if (updated) {
            refreshUI(19.5); // Pass the desired zoom level to refresh the UI
            print("Parking lots updated.");
          }
        });
      }
    });
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

  static void initializeGraph() {
    print("Initializing graph...");
    entrances.forEach((entranceName, entranceLatLng) {
      graph[entranceName] = {};
      parkingLots.forEach((lotName, lotData) {
        // Ensure correct access to 'location' and 'vacant'
        if (lotData.containsKey('location') && lotData.containsKey('vacant')) {
          LatLng lotLatLng = lotData['location'];
          double distance = _calculateDistance(entranceLatLng, lotLatLng);
          graph[entranceName]![lotName] = distance;
          // Symmetric edge in the graph
          graph[lotName] = {entranceName: distance};
        }
      });
    });
    print("Graph initialized: $graph");
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

    // Find the nearest vacant parking lot from the starting node
    String? nearestParkingLot;
    double shortestPathDistance = double.infinity;
    parkingLots.forEach((parkingLot, lotData) {
      // Only consider vacant parking lots
      if (lotData['vacant'] && distances[parkingLot]! < shortestPathDistance) {
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
