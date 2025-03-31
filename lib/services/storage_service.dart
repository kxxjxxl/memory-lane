// lib/services/storage_service.dart
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/memory_capsule.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Max size for Firestore (1MB is a safe limit)
  static const int _maxFileSize = 1024 * 1024; // 1MB

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Upload media to Firestore
  Future<MediaItem> uploadMedia({
    required html.File file,
    required String mediaType, // 'image', 'video', 'audio'
    void Function(double)? onProgress,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Check file size
    if (file.size > _maxFileSize) {
      throw Exception('File size exceeds 1MB limit. Please use a smaller file.');
    }

    // Generate unique file ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp-${file.name}';
    
    // Read file as base64
    final completer = Completer<String>();
    final reader = html.FileReader();
    
    reader.onLoad.listen((event) {
      // Get base64 data from the file reader result
      final result = reader.result as String;
      // The result includes the data URL prefix that we need to remove
      // Format is: data:mimetype;base64,actualData
      final base64Data = result.split(',')[1];
      completer.complete(base64Data);
    });
    
    reader.onError.listen((event) {
      completer.completeError('Error reading file: ${reader.error}');
    });
    
    // Simulate progress
    if (onProgress != null) {
      // Simulate 0% -> 50% progress while reading
      onProgress(0.1);
      
      Future.delayed(const Duration(milliseconds: 200), () {
        onProgress(0.3);
      });
      
      Future.delayed(const Duration(milliseconds: 400), () {
        onProgress(0.5);
      });
    }
    
    // Start reading the file as a data URL
    reader.readAsDataUrl(file);
    
    // Wait for the file to be read
    final base64Data = await completer.future;
    
    // Create a unique document for this media item in Firestore
    final mediaCollectionRef = _firestore.collection('users')
        .doc(currentUserId)
        .collection('media');
    
    final mediaDocRef = mediaCollectionRef.doc();
    
    // Store the media data
    final mediaData = {
      'fileName': fileName,
      'type': mediaType,
      'contentType': file.type,
      'data': base64Data,
      'createdAt': FieldValue.serverTimestamp(),
      'size': file.size,
    };
    
    // Simulate more progress
    if (onProgress != null) {
      // Simulate 50% -> 90% progress during upload
      onProgress(0.7);
    }
    
    // Upload to Firestore
    await mediaDocRef.set(mediaData);
    
    // Simulate complete
    if (onProgress != null) {
      onProgress(1.0);
    }
    
    // Create and return MediaItem
    return MediaItem(
      url: mediaDocRef.id, // We'll use the document ID as the "URL"
      type: mediaType,
      fileName: fileName,
      thumbnailUrl: mediaDocRef.id, // Same as url in this implementation
    );
  }

  // Get media by ID (to be used when displaying media)
  Future<Map<String, dynamic>> getMediaById(String mediaId) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final mediaDoc = await _firestore.collection('users')
          .doc(currentUserId)
          .collection('media')
          .doc(mediaId)
          .get();
      
      if (!mediaDoc.exists) {
        throw Exception('Media not found');
      }
      
      return mediaDoc.data() as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting media: $e');
      rethrow;
    }
  }

  // Delete media from Firestore
  Future<void> deleteMedia(MediaItem mediaItem) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Delete the media document
      await _firestore.collection('users')
          .doc(currentUserId)
          .collection('media')
          .doc(mediaItem.url) // We use the document ID as the URL
          .delete();
      
    } catch (e) {
      debugPrint('Error deleting media: $e');
      rethrow;
    }
  }
}