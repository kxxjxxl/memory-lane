// lib/features/profile/providers/memory_history_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/memory_capsule.dart';
import '../../../repositories/memory_repository.dart';

class MemoryHistoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MemoryRepository _repository = MemoryRepository();
  
  List<MemoryCapsule> _memories = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  Stream<List<MemoryCapsule>> get memories => _repository.getUserMemories();
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Update a memory
  Future<void> updateMemory(MemoryCapsule memory) async {
    await _repository.updateMemory(memory);
    notifyListeners();
  }
  
  // Delete a memory
  Future<void> deleteMemory(MemoryCapsule memory) async {
    await _repository.deleteMemory(memory);
    notifyListeners();
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