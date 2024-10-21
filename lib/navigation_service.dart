import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';

class NavigationService {
  static const String apiKey = 'YOUR_API_KEY_HERE'; // Replace with your actual API key

  // Function to fetch directions from Google Maps Directions API
  static Future<List<LatLng>> fetchDirections(LatLng start, LatLng destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<LatLng> route = [];

      if (data['status'] == 'OK') {
        // Parse the steps from the response
        for (var step in data['routes'][0]['legs'][0]['steps']) {
          final LatLng point = LatLng(
            step['end_location']['lat'],
            step['end_location']['lng'],
          );
          route.add(point);
        }
      } else {
        throw Exception('Error fetching directions: ${data['status']}');
      }

      return route;
    } else {
      throw Exception('Failed to load directions: ${response.statusCode}');
    }
  }
// Updated function to fetch the custom path segment
  static Future<List<LatLng>> fetchCustomPathSegment(LatLng userLocation, LatLng parkingLotLocation) async {
    String geojson = await rootBundle.loadString('assets/path_new_new.geojson');
    final data = json.decode(geojson);

    List<LatLng> fullPath = [];
    List<LatLng> segment = [];

    // Check if the GeoJSON contains features
    if (data['features'] != null) {
      for (var feature in data['features']) {
        if (feature['geometry']['type'] == 'LineString') {
          List<dynamic> coordinates = feature['geometry']['coordinates'];

          for (var coordinate in coordinates) {
            LatLng point = LatLng(coordinate[1], coordinate[0]); // Lat at index 1, Long at index 0
            fullPath.add(point);
          }
        }
      }
    } else {
      throw Exception('No features found in the GeoJSON');
    }

    if (fullPath.isEmpty) {
      throw Exception('No path data found in the GeoJSON file');
    }

    // Find the closest points on the path to the user and destination
    LatLng closestToUser = _findClosestPoint(userLocation, fullPath);
    LatLng closestToParkingLot = _findClosestPoint(parkingLotLocation, fullPath);

    // Find the indices of the closest points in the fullPath
    int indexOfClosestToUser = fullPath.indexOf(closestToUser);
    int indexOfClosestToParkingLot = fullPath.indexOf(closestToParkingLot);

    // Check if both indices are valid
    if (indexOfClosestToUser == -1 || indexOfClosestToParkingLot == -1) {
      throw Exception('One or both closest points not found on the path.');
    }

    // Extract the segment based on index positions
    if (indexOfClosestToUser <= indexOfClosestToParkingLot) {
      // Normal case: user location is before or at the parking lot location
      segment = fullPath.sublist(indexOfClosestToUser, indexOfClosestToParkingLot + 1);
    } else {
      // User location is after the parking lot, so we need to wrap around
      segment = fullPath.sublist(indexOfClosestToUser) // Segment from user location to the end
          + fullPath.sublist(3, indexOfClosestToParkingLot + 1); // Continue from the fourth point to the parking lot
    }

    if (segment.isEmpty) {
      throw Exception('No valid path segment found between user and parking lot.');
    }

    return segment;
  }



  // Helper function to find the closest point in the path to a given location
  static LatLng _findClosestPoint(LatLng location, List<LatLng> path) {
    LatLng closestPoint = path[0];
    double minDistance = _calculateDistance(location, closestPoint);

    for (LatLng point in path) {
      double distance = _calculateDistance(location, point);
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }

    return closestPoint;
  }

// Function to calculate the distance between two LatLng points
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371000; // Radius of the Earth in meters
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double dLat = lat2 - lat1;
    double dLng = (point2.longitude - point1.longitude) * pi / 180;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in meters
  }

// Updated helper function to get the closest point on a line segment
  static LatLng _getClosestPointOnSegment(LatLng point, LatLng segmentStart, LatLng segmentEnd) {
    double lat1 = segmentStart.latitude;
    double lng1 = segmentStart.longitude;
    double lat2 = segmentEnd.latitude;
    double lng2 = segmentEnd.longitude;

    double latPoint = point.latitude;
    double lngPoint = point.longitude;

    double dx = lat2 - lat1;
    double dy = lat2 - lat1;

    if (dx == 0 && dy == 0) {
      return segmentStart; // The segment is a point
    }

    // Project point onto the line segment, but clamp to the segment boundaries
    double t = ((latPoint - lat1) * dx + (lngPoint - lng1) * dy) / (dx * dx + dy * dy);
    t = max(0, min(1, t));

    double closestLat = lat1 + t * dx;
    double closestLng = lng1 + t * dy;

    LatLng closestPointOnSegment = LatLng(closestLat, closestLng);

    // Check if the closest point is to the left or right of the path segment using cross product
    bool isLeft = _isLeftOfSegment(point, segmentStart, segmentEnd);

    if (isLeft) {
      print("Point is to the left of the path segment.");
      return closestPointOnSegment; // Return as is for left side
    } else {
      print("Point is to the right of the path segment.");
      return closestPointOnSegment; // Return as is for right side
    }
  }

// Function to determine if a point is to the left or right of a line segment
  static bool _isLeftOfSegment(LatLng point, LatLng segmentStart, LatLng segmentEnd) {
    return ((segmentEnd.longitude - segmentStart.longitude) * (point.latitude - segmentStart.latitude)
        - (segmentEnd.latitude - segmentStart.latitude) * (point.longitude - segmentStart.longitude)) > 0;
  }

}
