// lib/repositories/memory_repository.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/memory_capsule.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';

class MemoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();

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
  Stream<List<MemoryCapsule>> getUserMemories() {
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
  
  // Get nearby public memories (including user's own memories)
  Stream<List<MemoryCapsule>> getNearbyMemories(GeoPoint currentLocation, {double radiusKm = 5.0}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    // For simplicity in this version, we'll fetch all public memories
    // and filter by distance client-side
    // In a production app, you'd use geohashing or a specialized
    // geospatial query solution
    
    return _memoriesCollection
        .where('privacy', isEqualTo: MemoryPrivacy.public.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final memories = snapshot.docs.map((doc) {
            return MemoryCapsule.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
          
          // Also get user's own memories
          final userMemoriesSnapshot = await _memoriesCollection
              .where('userId', isEqualTo: currentUserId)
              .get();
              
          final userMemories = userMemoriesSnapshot.docs.map((doc) {
            return MemoryCapsule.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
          
          // Combine and filter by distance
          final allMemories = [...memories, ...userMemories];
          
          return allMemories.where((memory) {
            // Calculate distance
            final distanceKm = _calculateDistance(
              currentLocation.latitude, 
              currentLocation.longitude,
              memory.location.latitude,
              memory.location.longitude
            );
            
            // Include if within radius
            return distanceKm <= radiusKm;
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
      final memory = MemoryCapsule.fromJson(data, doc.id);
      
      // Ensure the memory is accessible to the current user
      // (either it's owned by the user or it's public)
      if (memory.userId == currentUserId || 
          memory.privacy == MemoryPrivacy.public) {
        return memory;
      }
      
      throw Exception('Access denied');
    } catch (e) {
      // Log and rethrow
      print('Error getting memory: $e');
      rethrow;
    }
  }
  
  // Helper method to calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in kilometers
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
        sin(dLat/2) * sin(dLat/2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
        sin(dLon/2) * sin(dLon/2);
        
    final c = 2 * atan2(sqrt(a), sqrt(1-a)); 
    final distance = R * c;
    
    return distance;
  }
  
  double _toRadians(double degree) {
    return degree * (pi / 180);
  }
}