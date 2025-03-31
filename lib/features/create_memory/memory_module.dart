// lib/features/create_memory/memory_module.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/memory_provider.dart';
import 'screens/time_capsule_screen.dart';

class MemoryModule {
  // Register providers
  static List<ChangeNotifierProvider> registerProviders() {
    return [
      ChangeNotifierProvider<MemoryProvider>(
        create: (_) => MemoryProvider(),
      ),
    ];
  }
  
  // Screen routes
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/create-memory': (context) => const TimeCapsuleScreen(),
    };
  }
}