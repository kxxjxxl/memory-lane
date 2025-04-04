// lib/features/map/screens/memory_map_view.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../models/memory_capsule.dart';
import '../../theme/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../features/create_memory/widgets/base64_media_display.dart';
import 'package:flutter/rendering.dart';
import '../../../repositories/memory_repository.dart';
import '../../../services/location_service.dart';

class MemoryMapView extends StatefulWidget {
  const MemoryMapView({Key? key}) : super(key: key);

  @override
  State<MemoryMapView> createState() => _MemoryMapViewState();
}

class _MemoryMapViewState extends State<MemoryMapView>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  final MemoryRepository _memoryRepository = MemoryRepository();
  final LocationService _locationService = LocationService();
  bool _showPublicMemories = true; // Toggle for showing public memories
  GeoPoint _currentLocation =
      const GeoPoint(37.7749, -122.4194); // Default location

  @override
  bool get wantKeepAlive => true;

  // Default to a central location (will be overridden by user location)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194), // San Francisco
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    if (_mapController != null) {
      try {
        _mapController!.dispose();
      } catch (e) {
        print('Error disposing map controller: $e');
      }
    }
    super.dispose();
  }

  // Get current user location
  Future<void> _getCurrentLocation() async {
    try {
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null) {
        setState(() {
          _currentLocation = GeoPoint(
            currentLocation.latitude,
            currentLocation.longitude,
          );

          _initialCameraPosition = CameraPosition(
            target: LatLng(currentLocation.latitude, currentLocation.longitude),
            zoom: 14,
          );
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    } finally {
      // Load memories regardless of whether we got location
      _loadMemories();
    }
  }

  // Load memories from Firestore
  Future<void> _loadMemories() async {
    if (!mounted) return;

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

      // Get user's own memories and public memories within radius
      Stream<List<MemoryCapsule>> memoriesStream;

      if (_showPublicMemories) {
        // Get both user's memories and nearby public memories
        memoriesStream = _memoryRepository.getNearbyMemories(_currentLocation);
      } else {
        // Get only user's memories
        memoriesStream = _memoryRepository.getUserMemories();
      }

      // Listen to the stream
      memoriesStream.listen((memories) async {
        // Create markers for each memory
        Set<Marker> markers = {};
        for (var memory in memories) {
          // Skip memories without location
          if (memory.location.latitude == 0 && memory.location.longitude == 0) {
            continue;
          }

          // Create a marker for this memory
          final marker = Marker(
            markerId: MarkerId(
                memory.id ?? 'memory_${DateTime.now().millisecondsSinceEpoch}'),
            position:
                LatLng(memory.location.latitude, memory.location.longitude),
            // Use different colors for own vs. public memories
            icon: await _getMarkerIcon(memory.type,
                isUserMemory: memory.userId == user.uid),
            // Handle tap to show detailed memory
            onTap: () => _showMemoryDetails(memory),
            // Add a custom info window for hover effect
            consumeTapEvents: true,
          );

          markers.add(marker);
        }

        // Update the markers
        if (mounted) {
          setState(() {
            _markers = markers;
            _isLoading = false;

            // If we have memories with locations, center the map on the first one
            if (markers.isNotEmpty && _mapController != null) {
              _zoomToFitAllMarkers();
            }
          });
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _error = 'Error loading memories: $e';
            _isLoading = false;
          });
        }
        print('Error in memory stream: $e');
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
      print('Error loading memories: $e');
    }
  }

  // Get a custom marker icon based on memory type
  Future<BitmapDescriptor> _getMarkerIcon(String type,
      {bool isUserMemory = true}) async {
    // For user's own memories
    if (isUserMemory) {
      switch (type.toLowerCase()) {
        case 'birthday':
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRose);
        case 'anniversary':
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange);
        case 'travel':
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan);
        default:
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet);
      }
    }
    // For public memories (using different colors)
    else {
      switch (type.toLowerCase()) {
        case 'birthday':
          return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        case 'anniversary':
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow);
        case 'travel':
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure);
        default:
          return BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue);
      }
    }
  }

  // Format a timestamp
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Show memory details in a bottom sheet
  void _showMemoryDetails(MemoryCapsule memory) {
    final user = FirebaseAuth.instance.currentUser;
    final isUserMemory = memory.userId == user?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Handle at top of sheet
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Close button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        // Add haptic feedback (vibration) when tapped
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Content
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                    children: [
                      // Memory header
                      Row(
                        children: [
                          // Memory type icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getCapsuleColor(memory.type)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getMemoryTypeIcon(memory.type),
                              color: _getCapsuleColor(memory.type),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Memory type and privacy
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      memory.type.capitalize(),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Privacy indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (memory.privacy ==
                                                MemoryPrivacy.public)
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            memory.privacy.icon,
                                            size: 12,
                                            color: (memory.privacy ==
                                                    MemoryPrivacy.public)
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            memory.privacy.displayName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: (memory.privacy ==
                                                      MemoryPrivacy.public)
                                                  ? Colors.green
                                                  : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  isUserMemory
                                      ? 'Your memory'
                                      : 'Shared memory',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Media (if available)
                      if (memory.mediaItems.isNotEmpty) ...[
                        _buildMediaSection(memory, isDarkMode),
                        const SizedBox(height: 24),
                      ],

                      // Message (if available)
                      if (memory.message.isNotEmpty) ...[
                        _buildMessageSection(memory, isDarkMode),
                        const SizedBox(height: 24),
                      ],

                      // Details section
                      _buildDetailsSection(memory, isUserMemory, isDarkMode),

                      // Action buttons for user's own memories
                      if (isUserMemory) ...[
                        const SizedBox(height: 32),
                        _buildActionButtons(memory, context, isDarkMode),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Build media gallery section
  Widget _buildMediaSection(MemoryCapsule memory, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: memory.mediaItems.isNotEmpty
                ? _buildMediaGallery(memory)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 48,
                          color:
                              isDarkMode ? Colors.grey[700] : Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No media attached',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Build media gallery
  Widget _buildMediaGallery(MemoryCapsule memory) {
    if (memory.mediaItems.isEmpty) {
      return const SizedBox();
    }

    // If only one media item, show it full width
    if (memory.mediaItems.length == 1) {
      return Base64MediaPreview(
        mediaId: memory.mediaItems.first.url,
        mediaType: memory.mediaItems.first.type,
        showControls: true,
      );
    }

    // If multiple media items, build a page view
    return PageView.builder(
      itemCount: memory.mediaItems.length,
      itemBuilder: (context, index) {
        final media = memory.mediaItems[index];
        return Stack(
          children: [
            // Media preview
            Base64MediaPreview(
              mediaId: media.url,
              mediaType: media.type,
              showControls: true,
            ),

            // Page indicator
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}/${memory.mediaItems.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build message section
  Widget _buildMessageSection(MemoryCapsule memory, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[850]
                : _getCapsuleColor(memory.type).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getCapsuleColor(memory.type).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            memory.message,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Build details section
  Widget _buildDetailsSection(
      MemoryCapsule memory, bool isUserMemory, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Location info
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: _getCapsuleColor(memory.type),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      memory.locationName.isNotEmpty
                          ? memory.locationName
                          : 'Unknown location',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Creation date
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: _getCapsuleColor(memory.type),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _formatDateDetailed(memory.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Only show last updated if it exists and is different from created date
          if (memory.lastUpdatedAt != null &&
              memory.lastUpdatedAt!.difference(memory.createdAt).inSeconds >
                  5) ...[
            const Divider(height: 24),

            // Last updated date
            Row(
              children: [
                Icon(
                  Icons.update,
                  color: _getCapsuleColor(memory.type),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Updated',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        _formatDateDetailed(memory.lastUpdatedAt!),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Build action buttons for user's own memories
  Widget _buildActionButtons(
      MemoryCapsule memory, BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        // Edit button
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to edit screen
              // Navigator.pushNamed(context, '/edit-memory', arguments: memory);
            },
          ),
        ),

        const SizedBox(width: 16),

        // Delete button
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              _showDeleteConfirmation(context, memory);
            },
          ),
        ),
      ],
    );
  }

  // Show confirmation dialog for memory deletion
  void _showDeleteConfirmation(BuildContext context, MemoryCapsule memory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory?'),
        content: const Text(
            'This action cannot be undone. All associated media will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close memory details sheet

              // TODO: Delete memory
              // _memoryRepository.deleteMemory(memory).then((_) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     const SnackBar(content: Text('Memory deleted successfully')),
              //   );
              //   _loadMemories(); // Reload the memories
              // }).catchError((e) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(content: Text('Error deleting memory: $e')),
              //   );
              // });
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Format date with time
  String _formatDateDetailed(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Get icon for memory type
  IconData _getMemoryTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'birthday':
        return Icons.cake;
      case 'anniversary':
        return Icons.favorite;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.card_giftcard; // standard
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Map'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Privacy filter toggle
          IconButton(
            icon: Icon(
              _showPublicMemories ? Icons.public : Icons.lock_outline,
              color: _showPublicMemories ? Colors.green : Colors.orange,
            ),
            tooltip: _showPublicMemories
                ? 'Showing all memories (public + yours)'
                : 'Showing only your memories',
            onPressed: () {
              setState(() {
                _showPublicMemories = !_showPublicMemories;
                _loadMemories(); // Reload memories with new filter
              });
            },
          ),
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
      body: Stack(
        children: [
          _isLoading
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
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
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
                                color:
                                    isDarkMode ? Colors.white70 : Colors.blue,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No memories found in your area',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Create location-based memories to see them on the map',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
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
                            if (!mounted) return; // Safety check

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

          // Filter info banner
          if (!_isLoading && _markers.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[850]!.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _showPublicMemories ? Icons.public : Icons.lock_outline,
                      color: _showPublicMemories ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _showPublicMemories
                            ? 'Showing all memories (public + yours)'
                            : 'Showing only your memories',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${_markers.length} found',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _markers.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                _zoomToFitAllMarkers();
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.center_focus_strong),
            )
          : null,
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
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}
