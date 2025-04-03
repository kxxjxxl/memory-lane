import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../models/memory_capsule.dart';
import '../../theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MemoryMapView extends StatefulWidget {
  const MemoryMapView({Key? key}) : super(key: key);

  @override
  State<MemoryMapView> createState() => _MemoryMapViewState();
}

class _MemoryMapViewState extends State<MemoryMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  
  // Default to a central location (will be overridden by user location)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 12,
  );
  
  @override
  void initState() {
    super.initState();
    _loadMemories();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  
  // Load memories from Firestore
  Future<void> _loadMemories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }
      
      // Get user's memories from Firestore
      try {
        final memoriesSnapshot = await FirebaseFirestore.instance
            .collection('memories')
            .where('userId', isEqualTo: user.uid)
            .get();
        
        // Convert to memory capsules
        final memories = memoriesSnapshot.docs.map((doc) {
          final data = doc.data();
          return MemoryCapsule.fromJson(data, doc.id);
        }).toList();
        
        // Create markers for each memory
        Set<Marker> markers = {};
        for (var memory in memories) {
          // Skip memories without location
          if (memory.location.latitude == 0 && memory.location.longitude == 0) {
            continue;
          }
          
          // Create a marker for this memory
          final marker = Marker(
            markerId: MarkerId(memory.id ?? 'memory_${DateTime.now().millisecondsSinceEpoch}'),
            position: LatLng(memory.location.latitude, memory.location.longitude),
            infoWindow: InfoWindow(
              title: memory.type.capitalize(), 
              snippet: memory.message.isNotEmpty 
                  ? (memory.message.length > 30 
                      ? '${memory.message.substring(0, 30)}...' 
                      : memory.message)
                  : 'Created on ${_formatDate(memory.createdAt)}',
              onTap: () {
                _showMemoryDetails(memory);
              },
            ),
            icon: await _getMarkerIcon(memory.type),
          );
          
          markers.add(marker);
        }
        
        // Update the markers
        setState(() {
          _markers = markers;
          _isLoading = false;
          
          // If we have memories with locations, center the map on the first one
          if (markers.isNotEmpty) {
            final firstMarker = markers.first;
            _initialCameraPosition = CameraPosition(
              target: firstMarker.position,
              zoom: 12,
            );
            
            // Animate camera if map is already initialized
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(_initialCameraPosition),
            );
          }
        });
      } catch (firestoreError) {
        if (firestoreError.toString().contains('permission-denied')) {
          setState(() {
            // Temporarily comment this out to not show the error
            // _error = 'Firestore permission denied. Please check your Firebase security rules.';
            // _isLoading = false;
          });
          print('Firestore permission error: $firestoreError');
          
          // Load mock data instead
          await _loadMockMemories();
        } else {
          rethrow; // Re-throw for the outer catch block
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString().contains('permission-denied') 
            ? 'Firebase permission error. Check security rules.' 
            : 'Error loading memories: $e';
        _isLoading = false;
      });
      print('Error loading memories: $e');
    }
  }
  
  // Get a custom marker icon based on memory type
  Future<BitmapDescriptor> _getMarkerIcon(String type) async {
    switch (type.toLowerCase()) {
      case 'birthday':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      case 'anniversary':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'travel':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }
  
  // Format a timestamp
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Show memory details in a bottom sheet
  void _showMemoryDetails(MemoryCapsule memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Memory header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    memory.type.capitalize(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getCapsuleColor(memory.type),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const Divider(height: 30),
              
              // Location
              Row(
                children: [
                  Icon(Icons.location_on, color: _getCapsuleColor(memory.type)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      memory.locationName.isNotEmpty 
                          ? memory.locationName 
                          : 'Location not specified',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Created date
              Row(
                children: [
                  Icon(Icons.calendar_today, color: _getCapsuleColor(memory.type)),
                  const SizedBox(width: 8),
                  Text(
                    'Created on ${_formatDate(memory.createdAt)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Message
              if (memory.message.isNotEmpty) ...[
                Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.3) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    memory.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Media preview (simplified for now)
              if (memory.mediaItems.isNotEmpty) ...[
                Text(
                  'Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: memory.mediaItems.length,
                    itemBuilder: (context, index) {
                      final mediaItem = memory.mediaItems[index];
                      
                      return Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _getCapsuleColor(memory.type).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            _getMediaIcon(mediaItem.type),
                            size: 40,
                            color: _getCapsuleColor(memory.type),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const Spacer(),
              
              // View full memory button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to memory details screen
                    Navigator.pop(context);
                    // Add navigation to full memory view here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCapsuleColor(memory.type),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Full Memory',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Helper method to get color based on memory type
  Color _getCapsuleColor(String type) {
    switch (type.toLowerCase()) {
      case 'birthday':
        return const Color(0xFFFF6584);
      case 'anniversary':
        return const Color(0xFFF9A826);
      case 'travel':
        return const Color(0xFF43B5C3);
      default:
        return const Color(0xFF6C63FF); // standard
    }
  }
  
  // Get icon for media type
  IconData _getMediaIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'audio':
        return Icons.audiotrack;
      default:
        return Icons.attachment;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Map'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMemories,
          ),
          // Theme toggle
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadMemories,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _markers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 80,
                            color: isDarkMode ? Colors.white70 : Colors.blue,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No memories found in your area',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Create location-based memories to see them on the map',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                      onMapCreated: (controller) {
                        setState(() {
                          _mapController = controller;
                          
                          // Set map style based on theme
                          if (isDarkMode) {
                            controller.setMapStyle(_darkMapStyle);
                          }
                        });
                      },
                      padding: const EdgeInsets.only(bottom: 120),
                    ),
      floatingActionButton: _markers.isNotEmpty ? FloatingActionButton(
        onPressed: () {
          // Center the map on the user's current location
          // or zoom to fit all markers
          _zoomToFitAllMarkers();
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.center_focus_strong),
      ) : null,
    );
  }
  
  // Zoom map to fit all markers
  void _zoomToFitAllMarkers() {
    if (_markers.isEmpty || _mapController == null) return;
    
    if (_markers.length == 1) {
      // If there's only one marker, just center on it
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _markers.first.position,
            zoom: 14,
          ),
        ),
      );
      return;
    }
    
    // Calculate bounds to include all markers
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;
    
    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      
      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }
    
    // Create a bounding box
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    // Animate camera to show all markers with padding
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
    );
  }
  
  // Dark mode map style (from Google Maps Styling Wizard)
  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{ "color": "#242f3e" }]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#746855" }]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{ "color": "#242f3e" }]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#d59563" }]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#d59563" }]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{ "color": "#263c3f" }]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#6b9a76" }]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{ "color": "#38414e" }]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{ "color": "#212a37" }]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#9ca5b3" }]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{ "color": "#746855" }]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{ "color": "#1f2835" }]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#f3d19c" }]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{ "color": "#2f3948" }]
    },
    {
      "featureType": "transit.station",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#d59563" }]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{ "color": "#17263c" }]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#515c6d" }]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [{ "color": "#17263c" }]
    }
  ]
  ''';

  // Add this method to create mock memory data
  Future<void> _loadMockMemories() async {
    // Create mock memory capsules
    final mockMemories = [
      MemoryCapsule(
        id: 'mock-1',
        userId: 'mock-user',
        capsuleType: 'standard',
        media: [],
        location: const GeoPoint(47.5615, -52.7126), // St. John's
        locationName: "Water Street, St. John's, NL, Canada",
        message: "My first memory in downtown St. John's",
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      MemoryCapsule(
        id: 'mock-2',
        userId: 'mock-user',
        capsuleType: 'birthday',
        media: [],
        location: const GeoPoint(47.5701, -52.6819), // Signal Hill
        locationName: "Signal Hill, St. John's, NL, Canada",
        message: "Birthday celebration with a beautiful view!",
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      MemoryCapsule(
        id: 'mock-3',
        userId: 'mock-user',
        capsuleType: 'travel',
        media: [],
        location: const GeoPoint(47.5649, -52.7093), // Harbour
        locationName: "Harbour Drive, St. John's, NL, Canada",
        message: "Watching ships in the harbor",
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];

    // Create markers for each mock memory
    Set<Marker> markers = {};
    for (var memory in mockMemories) {
      final marker = Marker(
        markerId: MarkerId(memory.id ?? 'mock-${DateTime.now().millisecondsSinceEpoch}'),
        position: LatLng(memory.location.latitude, memory.location.longitude),
        infoWindow: InfoWindow(
          title: memory.type.capitalize(),
          snippet: memory.message.isNotEmpty
              ? (memory.message.length > 30
                  ? '${memory.message.substring(0, 30)}...'
                  : memory.message)
              : 'Created on ${_formatDate(memory.createdAt)}',
          onTap: () {
            _showMemoryDetails(memory);
          },
        ),
        icon: await _getMarkerIcon(memory.type),
      );

      markers.add(marker);
    }

    // Update the markers
    setState(() {
      _markers = markers;
      _isLoading = false;

      // Center map on first mock memory
      _initialCameraPosition = CameraPosition(
        target: LatLng(mockMemories.first.location.latitude, mockMemories.first.location.longitude),
        zoom: 12,
      );

      // Animate camera if map is already initialized
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(_initialCameraPosition),
      );
    });
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
} 