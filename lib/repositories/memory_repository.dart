// lib/repositories/memory_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/memory_capsule.dart';
import '../services/storage_service.dart';

class MemoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Collection reference
  CollectionReference get _memoriesCollection => _firestore.collection('memories');
  
  // Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new memory capsule
  Future<MemoryCapsule> createMemory(MemoryCapsule memory) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Make sure memory has the current user ID
      final memoryWithUserId = memory.copyWith(
        userId: currentUserId,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      // Add to Firestore
      final docRef = await _memoriesCollection.add(memoryWithUserId.toJson());
      
      // Return the memory with the generated ID
      return memoryWithUserId.copyWith(id: docRef.id);
    } catch (e) {
      // Log and rethrow
      print('Error creating memory: $e');
      rethrow;
    }
  }

  // Update an existing memory capsule
  Future<void> updateMemory(MemoryCapsule memory) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (memory.id == null) {
      throw Exception('Memory ID is required for updates');
    }

    try {
      // Update with current timestamp
      final memoryWithTimestamp = memory.copyWith(
        lastUpdatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _memoriesCollection.doc(memory.id).update(memoryWithTimestamp.toJson());
    } catch (e) {
      // Log and rethrow
      print('Error updating memory: $e');
      rethrow;
    }
  }

  // Delete a memory capsule
  Future<void> deleteMemory(MemoryCapsule memory) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (memory.id == null) {
      throw Exception('Memory ID is required for deletion');
    }

    try {
      // First delete all associated media files
      for (var mediaItem in memory.media) {
        await _storageService.deleteMedia(mediaItem);
      }

      // Then delete the memory document
      await _memoriesCollection.doc(memory.id).delete();
    } catch (e) {
      // Log and rethrow
      print('Error deleting memory: $e');
      rethrow;
    }
  }

  // Get all memories for the current user
  Stream<List<MemoryCapsule>> getMemories() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _memoriesCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MemoryCapsule.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Get a single memory by ID
  Future<MemoryCapsule?> getMemoryById(String id) async {
    if (currentUserId == null) {
      return null;
    }

    try {
      final doc = await _memoriesCollection.doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Ensure the memory belongs to the current user
      if (data['userId'] != currentUserId) {
        throw Exception('Access denied');
      }
      
      return MemoryCapsule.fromJson(data, doc.id);
    } catch (e) {
      // Log and rethrow
      print('Error getting memory: $e');
      rethrow;
    }
  }
}