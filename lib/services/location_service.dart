import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    try {
      if (kIsWeb) {
        // For web, use Google's Geocoding API directly
        final response = await http.get(
          Uri.parse(
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${coordinates.latitude},${coordinates.longitude}&key=$_apiKey'
          ),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            // Get the formatted address from the first result
            return data['results'][0]['formatted_address'];
          }
        }
      } else {
        // For mobile, use the geocoding package
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
      }
      
      // If all else fails, return coordinates as string
      return 'Lat: ${coordinates.latitude.toStringAsFixed(4)}, '
          'Lng: ${coordinates.longitude.toStringAsFixed(4)}';
    } catch (e) {
      debugPrint('Error getting address: $e');
      // Return coordinates as fallback
      return 'Lat: ${coordinates.latitude.toStringAsFixed(4)}, '
          'Lng: ${coordinates.longitude.toStringAsFixed(4)}';
    }
  }
  
  // Define a simple class for place search results
  Future<List<PlaceData>> searchPlaces(String query) async {
    if (query.isEmpty) return [];
    
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
  
  // Get coordinates from place ID
  Future<GeoPoint?> getCoordinatesFromPlaceId(String placeId) async {
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
} 