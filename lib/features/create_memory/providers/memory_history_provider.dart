// lib/features/profile/providers/memory_history_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/memory_capsule.dart';

class MemoryHistoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<MemoryCapsule> _memories = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<MemoryCapsule> get memories => _memories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Fetch memories
  // Update the fetchMemories() method in memory_history_provider.dart
Future<void> fetchMemories() async {
  if (_auth.currentUser == null) {
    _setError('User not authenticated');
    return;
  }
  
  _setLoading(true);
  
  try {
    print("Fetching memories for user: ${_auth.currentUser!.uid}");
    
    // Simplest possible query - just get all memories
    final snapshot = await _firestore
        .collection('memories')
        .get();
    
    // Filter and sort client-side
    _memories = snapshot.docs
        .map((doc) => MemoryCapsule.fromJson(doc.data(), doc.id))
        .where((memory) => memory.userId == _auth.currentUser!.uid) // Filter by userId in app
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by date
    
    print("Retrieved ${_memories.length} memories");
    notifyListeners();
  } catch (e) {
    print("Error in fetchMemories: $e");
    _setError('Error fetching memories: $e');
  } finally {
    _setLoading(false);
  }
}
   
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    print('MemoryHistoryProvider Error: $error');
    notifyListeners();
  }
}