// lib/features/map/screens/memory_map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/animations/animated_widgets.dart';
import '../../theme/theme_provider.dart';
import 'memory_map_view.dart';

class MemoryMapScreen extends StatelessWidget {
  const MemoryMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pass control to our new MapView component
    return const FadeInWidget(
      child: MemoryMapView(),
    );
  }
}