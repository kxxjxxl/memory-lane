// lib/features/profile/screens/edit_memory_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/memory_capsule.dart';
import '../providers/memory_history_provider.dart';
import '../../theme/theme_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../../../services/location_service.dart';
import '../../create_memory/widgets/privacy_selector.dart';
import '../../create_memory/providers/memory_provider.dart';
import '../../create_memory/widgets/base64_media_display.dart';

class EditMemoryScreen extends StatefulWidget {
  final MemoryCapsule memory;

  const EditMemoryScreen({
    Key? key,
    required this.memory,
  }) : super(key: key);

  @override
  State<EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<EditMemoryScreen> {
  late TextEditingController _messageController;
  late TextEditingController _locationController;
  late String _selectedCapsuleType;
  late MemoryPrivacy _selectedPrivacy;
  bool _isLoading = false;
  String? _error;
  bool _showMap = false;  // Control map visibility

  // Media related variables
  List<MediaItem> _mediaItems = [];
  bool _isMediaChanged = false;

  // Map related variables
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  List<PlaceData> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  late LatLng _selectedLocation;
  final LocationService _locationService = LocationService();

  // List of available capsule types
  final List<Map<String, dynamic>> _capsuleTypes = [
    {
      "id": "standard",
      "name": "Standard",
      "icon": Icons.accessibility,
      "color": const Color(0xFF6C63FF),
    },
    {
      "id": "birthday",
      "name": "Birthday",
      "icon": Icons.cake,
      "color": const Color(0xFFFF6584),
    },
    {
      "id": "anniversary",
      "name": "Anniversary",
      "icon": Icons.favorite,
      "color": const Color(0xFFF9A826),
    },
    {
      "id": "travel",
      "name": "Travel",
      "icon": Icons.flight,
      "color": const Color(0xFF43B5C3),
    },
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.memory.message);
    _locationController = TextEditingController(text: widget.memory.locationName);
    _selectedCapsuleType = widget.memory.capsuleType;
    _selectedPrivacy = widget.memory.privacy;
    _selectedLocation = LatLng(widget.memory.location.latitude, widget.memory.location.longitude);
    _mediaItems = List.from(widget.memory.media);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Get color for selected capsule type
  Color _getCapsuleColor() {
    final capsule = _capsuleTypes.firstWhere(
      (c) => c['id'] == _selectedCapsuleType,
      orElse: () => _capsuleTypes[0],
    );
    return capsule['color'];
  }

  // Get icon for selected capsule type
  IconData _getCapsuleIcon() {
    final capsule = _capsuleTypes.firstWhere(
      (c) => c['id'] == _selectedCapsuleType,
      orElse: () => _capsuleTypes[0],
    );
    return capsule['icon'];
  }

  // Get name for selected capsule type
  String _getCapsuleName() {
    final capsule = _capsuleTypes.firstWhere(
      (c) => c['id'] == _selectedCapsuleType,
      orElse: () => _capsuleTypes[0],
    );
    return capsule['name'];
  }

  // Save changes to the memory
  Future<void> _saveChanges() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updatedMemory = widget.memory.copyWith(
        message: _messageController.text.trim(),
        locationName: _locationController.text.trim(),
        capsuleType: _selectedCapsuleType,
        location: GeoPoint(
          _selectedLocation.latitude,
          _selectedLocation.longitude,
        ),
        lastUpdatedAt: DateTime.now(),
        privacy: _selectedPrivacy,
        media: _mediaItems, // Include updated media items
      );

      final provider = Provider.of<MemoryHistoryProvider>(context, listen: false);
      await provider.updateMemory(updatedMemory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update memory: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Remove media item
  void _removeMediaItem(int index) {
    setState(() {
      _mediaItems.removeAt(index);
      _isMediaChanged = true;
    });
  }

  // Add images from memory provider
  Future<void> _addImages() async {
    final memoryProvider = Provider.of<MemoryProvider>(context, listen: false);
    await memoryProvider.pickImages();
    
    if (memoryProvider.mediaItems.isNotEmpty) {
      final newMediaItems = await memoryProvider.uploadMedia();
      
      setState(() {
        _mediaItems.addAll(newMediaItems);
        _isMediaChanged = true;
      });
      
      memoryProvider.clearMedia();
    }
  }

  // Add videos from memory provider
  Future<void> _addVideos() async {
    final memoryProvider = Provider.of<MemoryProvider>(context, listen: false);
    await memoryProvider.pickVideos();
    
    if (memoryProvider.mediaItems.isNotEmpty) {
      final newMediaItems = await memoryProvider.uploadMedia();
      
      setState(() {
        _mediaItems.addAll(newMediaItems);
        _isMediaChanged = true;
      });
      
      memoryProvider.clearMedia();
    }
  }

  // Add audio from memory provider
  Future<void> _addAudio() async {
    final memoryProvider = Provider.of<MemoryProvider>(context, listen: false);
    await memoryProvider.pickAudio();
    
    if (memoryProvider.mediaItems.isNotEmpty) {
      final newMediaItems = await memoryProvider.uploadMedia();
      
      setState(() {
        _mediaItems.addAll(newMediaItems);
        _isMediaChanged = true;
      });
      
      memoryProvider.clearMedia();
    }
  }

  // Search for places
  void _searchPlaces(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _isSearching = true;
        _searchResults = [];
      });
      
      _locationService.searchPlaces(query).then((places) {
        if (mounted) {
          setState(() {
            _searchResults = places;
            _isSearching = false;
          });
        }
      });
    });
  }

  // Select a place from search results
  void _selectPlace(PlaceData place) async {
    setState(() {
      _locationController.text = place.formattedAddress ?? place.name;
      _searchResults = [];
      
      if (place.lat != null && place.lng != null) {
        _selectedLocation = LatLng(place.lat!, place.lng!);
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation,
          ),
        };
        
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation, 15),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Memory'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode 
                ? Icons.wb_sunny_outlined 
                : Icons.nights_stay_outlined,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Memory type selector
            Text(
              'Memory Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _capsuleTypes.length,
                itemBuilder: (context, index) {
                  final capsule = _capsuleTypes[index];
                  final isSelected = _selectedCapsuleType == capsule['id'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCapsuleType = capsule['id'];
                      });
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? capsule['color'].withOpacity(0.2)
                            : isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? capsule['color']
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            capsule['icon'],
                            color: isSelected
                                ? capsule['color']
                                : isDarkMode
                                    ? Colors.white
                                    : Colors.grey[600],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            capsule['name'],
                            style: TextStyle(
                              color: isSelected
                                  ? capsule['color']
                                  : isDarkMode
                                      ? Colors.white
                                      : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Media Section
            Text(
              'Media',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            
            // Media selection buttons
            Row(
              children: [
                Expanded(
                  child: _buildMediaButton(
                    icon: Icons.photo,
                    label: 'Photos',
                    color: Colors.blue,
                    onTap: _addImages,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMediaButton(
                    icon: Icons.videocam,
                    label: 'Videos',
                    color: Colors.red,
                    onTap: _addVideos,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMediaButton(
                    icon: Icons.mic,
                    label: 'Audio',
                    color: Colors.green,
                    onTap: _addAudio,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Media preview grid
            _mediaItems.isEmpty
              ? Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 48,
                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No media attached',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: _buildMediaGrid(),
                ),

            const SizedBox(height: 24),

            // Message field
            Text(
              'Message',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode 
                    ? Colors.grey[800] 
                    : Colors.grey[100],
              ),
            ),

            const SizedBox(height: 24),
            
            // Privacy selector
            PrivacySelectorWidget(
              selectedPrivacy: _selectedPrivacy,
              onPrivacyChanged: (privacy) {
                setState(() {
                  _selectedPrivacy = privacy;
                });
              },
              isDarkMode: isDarkMode,
            ),
            
            const SizedBox(height: 24),

            // Location section
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Current location display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: _getCapsuleColor(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationController.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showMap = !_showMap;
                          });
                        },
                        child: Text(_showMap ? 'Hide Map' : 'Change Location'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map and search section (only shown when editing location)
            if (_showMap) ...[
              const SizedBox(height: 16),
              
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: isDarkMode 
                      ? Colors.grey[800] 
                      : Colors.grey[100],
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                            });
                          },
                        )
                      : null,
                ),
                onChanged: _searchPlaces,
              ),

              // Search results
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      return ListTile(
                        title: Text(place.name),
                        onTap: () => _selectPlace(place),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Map
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 15,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: (latLng) async {
                      setState(() {
                        _selectedLocation = latLng;
                        _markers = {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: latLng,
                          ),
                        };
                      });
                      
                      // Get address from coordinates
                      final geoPoint = GeoPoint(latLng.latitude, latLng.longitude);
                      final address = await _locationService.getAddressFromCoordinates(geoPoint);
                      setState(() {
                        _locationController.text = address;
                      });
                    },
                  ),
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: _getCapsuleColor(),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build media button
  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white : color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build media grid
  Widget _buildMediaGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      scrollDirection: Axis.horizontal,
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        final mediaItem = _mediaItems[index];
        return Stack(
          children: [
            // Media preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Base64MediaPreview(
                mediaId: mediaItem.url,
                mediaType: mediaItem.type,
                showControls: false,
              ),
            ),
            
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeMediaItem(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            
            // Type indicator
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getTypeColor(mediaItem.type).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getTypeIcon(mediaItem.type),
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _getTypeLabel(mediaItem.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper methods for media types
  IconData _getTypeIcon(String type) {
    switch (type) {
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'image':
        return 'Image';
      case 'video':
        return 'Video';
      case 'audio':
        return 'Audio';
      default:
        return 'File';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'audio':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}