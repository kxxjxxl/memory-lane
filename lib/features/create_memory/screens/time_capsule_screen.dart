// lib/features/create_memory/screens/time_capsule_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_updateCharCount);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _updateCharCount() {
    setState(() {
      // Just to trigger a rebuild for character count
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenSize = MediaQuery.of(context).size;

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
                    (index) => _buildStepIndicator(index),
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

                  // Navigation button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (_currentStep < _totalSteps - 1) {
                            _currentStep++;
                          } else {
                            // Save capsule logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Memory capsule saved successfully!'),
                              ),
                            );
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

  Widget _buildStepIndicator(int index) {
    final isActive = index <= _currentStep;
    final isCompleted = index < _currentStep;
    final isCurrent = index == _currentStep;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step number or check
        Container(
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
    return Column(
      children: [
        // Photo/Video selection card
        GestureDetector(
          onTap: () {
            // Handle photo/video selection
          },
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getCapsuleColor().withOpacity(0.7),
                  _getCapsuleColor(),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getCapsuleColor().withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_photo_alternate,
                    color: _getCapsuleColor(),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select photos or videos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to browse your gallery',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Selected Items text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Selected Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Clear selection logic
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

        // Selected media placeholder
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Provider.of<ThemeProvider>(context).isDarkMode
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
          ),
        ),
      ],
    );
  }

  // Step 3: Set Location
  Widget _buildSetLocationStep() {
    return Column(
      children: [
        // Map placeholder
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE6EEF8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Map container
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                            'https://images.unsplash.com/photo-1553702446-a39d6fbee593?q=80'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Map overlay for better UI
                  Center(
                    child: Icon(
                      Icons.location_on,
                      size: 50,
                      color: _getCapsuleColor(),
                    ),
                  ),

                  // Search bar at top
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
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
                          const Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search for a location',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
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
            onPressed: () {
              // Handle using current location
            },
          ),
        ),
      ],
    );
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
                    AspectRatio(
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
                    ),

                    const SizedBox(height: 20),

                    // Location info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
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
                                  '123 Memory Lane, San Francisco',
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
}
