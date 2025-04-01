// lib/features/create_memory/screens/time_capsule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/theme_provider.dart';
import '../providers/memory_provider.dart';
import '../../../models/memory_capsule.dart';
import '../widgets/media_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../services/location_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({Key? key}) : super(key: key);

  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Selected capsule type (default: standard)
  String _selectedCapsule = "standard";

  // For text editing in message step
  final TextEditingController _messageController = TextEditingController();

  // List of available capsule types (reduced to 4)
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

  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _defaultLocation = const LatLng(37.7749, -122.4194); // San Francisco as default

  final TextEditingController _searchController = TextEditingController();
  List<PlaceData> _searchResults = [];
  bool _isSearching = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateCharCount);
    
    // Initialize with empty message in provider
    Future.microtask(() {
      final memoryProvider = Provider.of<MemoryProvider>(context, listen: false);
      _messageController.text = memoryProvider.message;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _updateCharCount() {
    setState(() {
      // Update message in provider
      Provider.of<MemoryProvider>(context, listen: false)
        .setMessage(_messageController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final memoryProvider = Provider.of<MemoryProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenSize = MediaQuery.of(context).size;

    // Set selected capsule in provider
    Future.microtask(() {
      memoryProvider.setCapsuleType(_selectedCapsule);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Memory'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
              )
            : null,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.wb_sunny_outlined
                  : Icons.nights_stay_outlined,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Steps indicator
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _totalSteps,
                    (index) => Tooltip(
                      message: _getStepTitle(index),
                      child: _buildStepIndicator(index),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step title and description
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStepTitle(_currentStep),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStepDescription(_currentStep),
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content area
                  Expanded(
                    child: _buildStepContent(_currentStep),
                  ),

                  // Loading indicator or error message
                  if (memoryProvider.isLoading)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  
                  if (memoryProvider.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        memoryProvider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                  ),

                  // Navigation button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: memoryProvider.isLoading
                          ? null
                          : () async {
                        setState(() {
                          if (_currentStep < _totalSteps - 1) {
                            _currentStep++;
                          } else {
                            // Save capsule logic
                                  _saveMemoryCapsule(context);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getCapsuleColor().withOpacity(0.9),
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentStep == _totalSteps - 1
                            ? 'Save Memory'
                            : 'Continue',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMemoryCapsule(BuildContext context) async {
    final memoryProvider = Provider.of<MemoryProvider>(context, listen: false);
    
    // Set location if it hasn't been set yet
    if (memoryProvider.location.latitude == 0 && 
        memoryProvider.location.longitude == 0) {
      memoryProvider.setLocation(
        const GeoPoint(37.7749, -122.4194), // Default to San Francisco
        '123 Memory Lane, San Francisco',
      );
    }
    
    final memoryId = await memoryProvider.saveMemoryCapsule();
    
    if (memoryId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memory capsule saved successfully!'),
        ),
      );
      
      // Reset and navigate back
      setState(() {
        _currentStep = 0;
      });
    }
  }

  Widget _buildStepIndicator(int index) {
    final isActive = index <= _currentStep;
    final isCompleted = index < _currentStep;
    final isCurrent = index == _currentStep;

    return GestureDetector(
      onTap: () {
        // Allow navigation to this step if it's already active or previous steps are completed
        if (index <= _currentStep) {
          setState(() {
            _currentStep = index;
          });
        }
      },
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step number or check
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? _getCapsuleColor() : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: _getCapsuleColor().withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : null,
              border: index <= _currentStep
                  ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : Icon(
                    _getIconForStep(index),
                    color: Colors.white,
                    size: 20,
                  ),
          ),
        ),
        const SizedBox(height: 4),

        // Step label
        Text(
          _getStepShortLabel(index),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? _getCapsuleColor() : Colors.grey,
          ),
        ),
      ],
      ),
    );
  }

  String _getStepShortLabel(int step) {
    switch (step) {
      case 0:
        return "Capsule";
      case 1:
        return "Media";
      case 2:
        return "Location";
      case 3:
        return "Message";
      case 4:
        return "Preview";
      default:
        return "";
    }
  }

  IconData _getIconForStep(int step) {
    switch (step) {
      case 0: // Select capsule
        return Icons.card_giftcard;
      case 1: // Select media
        return Icons.image;
      case 2: // Set location
        return Icons.location_on;
      case 3: // Write message
        return Icons.message;
      case 4: // Preview
        return Icons.visibility;
      default:
        return Icons.circle;
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return "Select Capsule";
      case 1:
        return "Add Photos & Videos";
      case 2:
        return "Set Location";
      case 3:
        return "Write Message";
      case 4:
        return "Preview Capsule";
      default:
        return "";
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return "Choose a capsule type for your memory";
      case 1:
        return "Select photos and videos to include";
      case 2:
        return "Choose where to place your memory";
      case 3:
        return "Add a personal message";
      case 4:
        return "Review your memory before saving";
      default:
        return "";
    }
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildSelectCapsuleStep();
      case 1:
        return _buildSelectMediaStep();
      case 2:
        return _buildSetLocationStep();
      case 3:
        return _buildWriteMessageStep();
      case 4:
        return _buildPreviewStep();
      default:
        return Container();
    }
  }

  // Step 1: Select Capsule
  Widget _buildSelectCapsuleStep() {
    return Center(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: _capsuleTypes.length,
        itemBuilder: (context, index) {
          final capsule = _capsuleTypes[index];
          final isSelected = _selectedCapsule == capsule["id"];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCapsule = capsule["id"];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? capsule["color"]
                    : capsule["color"].withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: capsule["color"].withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Capsule icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : capsule["color"].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      capsule["icon"],
                      color: isSelected ? capsule["color"] : capsule["color"],
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Capsule name
                  Text(
                    capsule["name"],
                    style: TextStyle(
                      color: isSelected ? Colors.white : capsule["color"],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (isSelected) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: capsule["color"],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Selected",
                            style: TextStyle(
                              color: capsule["color"],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Step 2: Select Media
  Widget _buildSelectMediaStep() {
    final memoryProvider = Provider.of<MemoryProvider>(context);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Column(
      children: [
        // Media selection buttons
        Row(
          children: [
            Expanded(
              child: _buildMediaButton(
                icon: Icons.photo,
                label: 'Photos',
                color: Colors.blue,
          onTap: () {
                  memoryProvider.pickImages();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMediaButton(
                icon: Icons.videocam,
                label: 'Videos',
                color: Colors.red,
                onTap: () {
                  memoryProvider.pickVideos();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMediaButton(
                icon: Icons.mic,
                label: 'Audio',
                color: Colors.green,
                onTap: () {
                  memoryProvider.pickAudio();
                },
                  ),
                ),
              ],
        ),

        const SizedBox(height: 24),

        // Selected Items text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Items (${memoryProvider.mediaItems.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (memoryProvider.mediaItems.isNotEmpty)
            TextButton(
              onPressed: () {
                  memoryProvider.clearMedia();
              },
              child: Text(
                'Clear All',
                style: TextStyle(
                  color: _getCapsuleColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Selected media list
        Expanded(
          child: memoryProvider.mediaItems.isEmpty
              ? Container(
            decoration: BoxDecoration(
                    color: isDarkMode
                  ? const Color(0xFF2A2A2A)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[400]!.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No items selected yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
                )
              : MediaGrid(
                  mediaItems: memoryProvider.mediaItems,
                  onRemove: (index) => memoryProvider.removeMediaItem(index),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
            child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Set Location
  Widget _buildSetLocationStep() {
    final memoryProvider = Provider.of<MemoryProvider>(context);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    // Convert GeoPoint to LatLng if a location is already set
    LatLng _currentLocation = memoryProvider.location.latitude != 0 
        ? LatLng(memoryProvider.location.latitude, memoryProvider.location.longitude)
        : _defaultLocation;
    
    // Update markers when location changes
    _updateMarkers(_currentLocation);
    
    return Column(
      children: [
        // Map with Google Maps
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                // Conditionally render Google Maps based on platform
                if (kIsWeb)
                  // For web, use a fallback map image with a marker
                  Stack(
                    children: [
                      // Static map image
                  Container(
                        decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                              'https://maps.googleapis.com/maps/api/staticmap?'
                              'center=${_currentLocation.latitude},${_currentLocation.longitude}'
                              '&zoom=14&size=600x400&markers=color:red|'
                              '${_currentLocation.latitude},${_currentLocation.longitude}'
                              '&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}'
                            ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                      // Tap listener for web
                      GestureDetector(
                        onTap: () {
                          // Show a dialog to manually enter coordinates on web
                          _showLocationPickerDialog();
                        },
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  )
                else
                  // For mobile, use the Google Maps widget
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Apply custom map style for dark mode
                      if (isDarkMode) {
                        _setMapDarkMode(controller);
                      }
                    },
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onTap: (latLng) {
                      // Set marker on tap
                      _setMarker(latLng);
                      // Convert to GeoPoint and update provider
                      _updateLocationInProvider(latLng);
                    },
                  ),

                  // Search bar at top
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Search bar
                        Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                              Expanded(
                            child: TextField(
                                  controller: _searchController,
                                  decoration: const InputDecoration(
                                hintText: 'Search for a location',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                                  onChanged: (value) {
                                    // Debounce search to avoid too many API calls
                                    _debounce?.cancel();
                                    _debounce = Timer(const Duration(milliseconds: 500), () {
                                      _searchPlaces(value);
                                    });
                                  },
                                ),
                              ),
                              if (_isSearching)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              if (_searchController.text.isNotEmpty && !_isSearching)
                                IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                        
                        // Search results
                        if (_searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            constraints: BoxConstraints(
                              maxHeight: 300,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                              itemCount: _searchResults.length > 5 ? 5 : _searchResults.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final place = _searchResults[index];
                                return ListTile(
                                  title: Text(place.name),
                                  subtitle: Text(
                                    place.formattedAddress ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  leading: const Icon(Icons.location_on),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  dense: true,
                                  onTap: () => _selectPlace(place),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                
                // Location info
                if (memoryProvider.locationName.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                  ),
                ],
              ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: _getCapsuleColor(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              memoryProvider.locationName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Current location button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            onPressed: () => _getCurrentLocation(),
          ),
        ),
      ],
    );
  }

  // Add a new method for web location picker dialog
  void _showLocationPickerDialog() {
    final TextEditingController latController = TextEditingController();
    final TextEditingController lngController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g. 37.7749',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lngController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g. -122.4194',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
            onPressed: () {
                Navigator.pop(context);
                
                try {
                  final lat = double.parse(latController.text);
                  final lng = double.parse(lngController.text);
                  
                  final latLng = LatLng(lat, lng);
                  _setMarker(latLng);
                  _updateLocationInProvider(latLng);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid coordinates')),
                  );
                }
              },
              child: const Text('Set Location'),
            ),
          ],
        );
      },
    );
  }

  // Update markers on the map
  void _updateMarkers(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
    });
  }

  // Set marker at the tapped position
  void _setMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
    });
    
    // Move camera to the selected position
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  // Update location in the provider
  Future<void> _updateLocationInProvider(LatLng latLng) async {
    final provider = Provider.of<MemoryProvider>(context, listen: false);
    final geoPoint = GeoPoint(latLng.latitude, latLng.longitude);
    
    // Get address from coordinates
    final address = await _locationService.getAddressFromCoordinates(geoPoint);
    
    // Update provider
    provider.setLocation(geoPoint, address);
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    
    if (location != null) {
      final latLng = LatLng(location.latitude, location.longitude);
      
      // Update UI with the new location
      _setMarker(latLng);
      
      // Center map on the current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(latLng),
      );
      
      // Update provider
      _updateLocationInProvider(latLng);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current location selected'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get current location. Please ensure location services are enabled.'),
        ),
      );
    }
  }

  // Set dark mode style for the map
  void _setMapDarkMode(GoogleMapController controller) {
    controller.setMapStyle('''
      [
        {
          "elementType": "geometry",
          "stylers": [{"color": "#242f3e"}]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#746855"}]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#242f3e"}]
        },
        {
          "featureType": "administrative.locality",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#d59563"}]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#d59563"}]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry",
          "stylers": [{"color": "#263c3f"}]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#6b9a76"}]
        },
        {
          "featureType": "road",
          "elementType": "geometry",
          "stylers": [{"color": "#38414e"}]
        },
        {
          "featureType": "road",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#212a37"}]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#9ca5b3"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry",
          "stylers": [{"color": "#746855"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry.stroke",
          "stylers": [{"color": "#1f2835"}]
        },
        {
          "featureType": "road.highway",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#f3d19c"}]
        },
        {
          "featureType": "transit",
          "elementType": "geometry",
          "stylers": [{"color": "#2f3948"}]
        },
        {
          "featureType": "transit.station",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#d59563"}]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [{"color": "#17263c"}]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.fill",
          "stylers": [{"color": "#515c6d"}]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.stroke",
          "stylers": [{"color": "#17263c"}]
        }
      ]
    ''');
  }

  // Step 4: Write Message
  Widget _buildWriteMessageStep() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final charCount = _messageController.text.length;
    final isOverLimit = charCount > 500;

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2A2A2A)
                  : _getCapsuleColor().withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getCapsuleColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _messageController,
              maxLines: null,
              maxLength: 500,
              // Remove the default counter
              buildCounter: (context,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              decoration: InputDecoration(
                hintText: 'Write your message here...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Message formatting options
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFormatButton(Icons.format_bold, _getCapsuleColor(), "Bold"),
              _buildFormatButton(
                  Icons.format_italic, _getCapsuleColor(), "Italic"),
              _buildFormatButton(
                  Icons.format_color_text, _getCapsuleColor(), "Color"),
              _buildFormatButton(
                  Icons.emoji_emotions_outlined, _getCapsuleColor(), "Emoji"),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Character count
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$charCount/500 characters',
            style: TextStyle(
              color: isOverLimit ? Colors.red : Colors.grey,
              fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatButton(IconData icon, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: () {
            // Text formatting logic
          },
        ),
      ),
    );
  }

  // Step 5: Preview
  Widget _buildPreviewStep() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final memoryProvider = Provider.of<MemoryProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header with capsule info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCapsuleColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCapsuleIcon(),
                      color: _getCapsuleColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getCapsuleName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Media preview
                    memoryProvider.mediaItems.isEmpty
                        ? AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getCapsuleColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getCapsuleColor().withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 40,
                                color: _getCapsuleColor(),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No media selected',
                                style: TextStyle(
                                  color: _getCapsuleColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                          )
                        : MediaPreview(mediaItems: memoryProvider.mediaItems),

                    const SizedBox(height: 20),

                    // Location info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: _getCapsuleColor()),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Location',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  memoryProvider.locationName.isEmpty
                                      ? '123 Memory Lane, San Francisco'
                                      : memoryProvider.locationName,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Message preview
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Message',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF3A3A3A)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _messageController.text.isEmpty
                                ? 'No message written yet...'
                                : _messageController.text,
                            style: TextStyle(
                              color: _messageController.text.isEmpty
                                  ? Colors.grey
                                  : isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Created date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Created: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods to get capsule details
  Color _getCapsuleColor() {
    final capsule = _capsuleTypes.firstWhere(
      (c) => c["id"] == _selectedCapsule,
      orElse: () => _capsuleTypes[0],
    );
    return capsule["color"];
  }

  IconData _getCapsuleIcon() {
    final capsule = _capsuleTypes.firstWhere(
      (c) => c["id"] == _selectedCapsule,
      orElse: () => _capsuleTypes[0],
    );
    return capsule["icon"];
  }

  String _getCapsuleName() {
    final capsule = _capsuleTypes.firstWhere(
      (c) => c["id"] == _selectedCapsule,
      orElse: () => _capsuleTypes[0],
    );
    return capsule["name"];
  }

  String _getCapsuleId() {
    return _selectedCapsule;
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await _locationService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

  Future<void> _selectPlace(PlaceData place) async {
    // Clear search results
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });
    
    // Use the coordinates directly from the place data
    final geoPoint = GeoPoint(place.lat, place.lng);
    
    // Update map
    final latLng = LatLng(place.lat, place.lng);
    _setMarker(latLng);
    
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
    }
    
    // Update provider with location and address
    final provider = Provider.of<MemoryProvider>(context, listen: false);
    provider.setLocation(geoPoint, place.formattedAddress ?? place.name);
  }
}