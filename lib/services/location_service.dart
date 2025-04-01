import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js' as js;
import 'dart:html' as html;

class LocationService {
  // Get API key from .env
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  // Request location permission and get the current position
  Future<GeoPoint?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return null;
    }

    // Request permission to access location
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      return null;
    }

    try {
      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return GeoPoint(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(GeoPoint coordinates) async {
    if (kIsWeb) {
      // Mock data for web development - St. John's addresses
      final lat = coordinates.latitude;
      final lng = coordinates.longitude;
      
      // Basic proximity check to return mock addresses in St. John's
      if ((lat - 47.5615).abs() < 0.01 && (lng - (-52.7126)).abs() < 0.01) {
        return "123 Water Street, St. John's, NL A1C 1A5, Canada";
      } else if ((lat - 47.5649).abs() < 0.01 && (lng - (-52.7093)).abs() < 0.01) {
        return "45 Harbour Drive, St. John's, NL A1C 6N6, Canada";
      } else if ((lat - 47.5701).abs() < 0.01 && (lng - (-52.6819)).abs() < 0.01) {
        return "Signal Hill National Historic Site, St. John's, NL A1A, Canada";
      } else {
        return "Custom Location in St. John's at ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
      }
    } else {
      // Original mobile implementation
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          coordinates.latitude, 
          coordinates.longitude
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }
      
      // If all else fails, return coordinates as string
      return 'Lat: ${coordinates.latitude.toStringAsFixed(4)}, '
          'Lng: ${coordinates.longitude.toStringAsFixed(4)}';
    }
  }
  
  // Search places
  Future<List<PlaceData>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    
    if (kIsWeb) {
      // For web development, use mock data for St. John's, NL, Canada
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      
      // Generate some mock places based on the query in St. John's
      return [
        PlaceData(
          placeId: "place_id_1",
          name: "$query",
          formattedAddress: "$query Ave, St. John's, NL, Canada",
          lat: 47.5615,
          lng: -52.7126,
        ),
        PlaceData(
          placeId: "place_id_2",
          name: "$query",
          formattedAddress: "$query Street, St. John's, NL A1C, Canada",
          lat: 47.5649,
          lng: -52.7093,
        ),
        PlaceData(
          placeId: "place_id_3",
          name: "$query",
          formattedAddress: "$query Road, St. John's, NL A1A, Canada",
          lat: 47.5701,
          lng: -52.6819,
        ),
      ];
    } else {
      // Mobile implementation (keep this as is)
      try {
        final response = await http.get(
          Uri.parse(
            'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$_apiKey'
          ),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final results = data['results'] as List;
            return results.map((place) => PlaceData.fromJson(place)).toList();
          }
        }
        return [];
      } catch (e) {
        debugPrint('Error searching places: $e');
        return [];
      }
    }
  }
  
  // Get coordinates from place ID
  Future<GeoPoint?> getCoordinatesFromPlaceId(String placeId) async {
    if (kIsWeb) {
      // Mock data for web development - St. John's locations
      switch (placeId) {
        case "place_id_1":
          return GeoPoint(47.5615, -52.7126); // Downtown St. John's
        case "place_id_2": 
          return GeoPoint(47.5649, -52.7093); // St. John's Harbour
        case "place_id_3":
          return GeoPoint(47.5701, -52.6819); // Signal Hill
        default:
          return GeoPoint(47.5615, -52.7126); // Default to downtown St. John's
      }
    } else {
      // Original mobile implementation
      try {
        final response = await http.get(
          Uri.parse(
            'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_apiKey'
          ),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final location = data['result']['geometry']['location'];
            return GeoPoint(location['lat'], location['lng']);
          }
        }
        return null;
      } catch (e) {
        debugPrint('Error getting place details: $e');
        return null;
      }
    }
  }
}

// Simple place data class
class PlaceData {
  final String placeId;
  final String name;
  final String? formattedAddress;
  final double lat;
  final double lng;
  
  PlaceData({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    required this.lat,
    required this.lng,
  });
  
  factory PlaceData.fromJson(Map<String, dynamic> json) {
    return PlaceData(
      placeId: json['place_id'],
      name: json['name'],
      formattedAddress: json['formatted_address'],
      lat: json['geometry']['location']['lat'],
      lng: json['geometry']['location']['lng'],
    );
  }
  
  factory PlaceData.fromJsObject(dynamic jsObject) {
    return PlaceData(
      placeId: jsObject['place_id'],
      name: jsObject['name'],
      formattedAddress: jsObject['formatted_address'],
      lat: jsObject['geometry']['location']['lat'],
      lng: jsObject['geometry']['location']['lng'],
    );
  }
} 