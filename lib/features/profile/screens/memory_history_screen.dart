// lib/features/profile/screens/memory_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/animations/animated_widgets.dart';
import '../../theme/theme_provider.dart';
import '../providers/memory_history_provider.dart';
import '../../../models/memory_capsule.dart';
import '../widgets/memory_card.dart';

class MemoryHistoryScreen extends StatelessWidget {
  const MemoryHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final memoryProvider = Provider.of<MemoryHistoryProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory History'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Theme toggle button
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
      body: StreamBuilder<List<MemoryCapsule>>(
        stream: memoryProvider.memories,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Check if the error is about indexing
            final error = snapshot.error.toString();
            if (error.contains('index')) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Setting up memory indexing...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This is a one-time setup and should take just a few minutes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Other errors
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final memories = snapshot.data!;

          if (memories.isEmpty) {
            return FadeInWidget(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 100,
                      color: isDarkMode ? Colors.blue[400] : Colors.blue[700],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Memories Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Create your first memory to start your journey.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return FadeInWidget(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: memories.length,
              itemBuilder: (context, index) {
                final memory = memories[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MemoryCard(
                    memory: memory,
                    onEdit: () async {
                      // Handle edit
                      // You can navigate to an edit screen or show a dialog
                    },
                    onDelete: () async {
                      // Show confirmation dialog
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Memory?'),
                          content: const Text(
                            'This action cannot be undone. Are you sure you want to delete this memory?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'DELETE',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (shouldDelete == true) {
                        await memoryProvider.deleteMemory(memory);
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}