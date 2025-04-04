// lib/features/create_memory/providers/memory_provider.dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/memory_capsule.dart';
import '../../../repositories/memory_repository.dart';
import '../../../services/storage_service.dart';
import '../../../services/media_picker_service.dart';

class MemoryProvider with ChangeNotifier {
  final MemoryRepository _repository = MemoryRepository();
  final StorageService _storageService = StorageService();
  final MediaPickerService _mediaPicker = MediaPickerService();
  
  // Current user ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  // Memory being created
  String _selectedCapsule = 'standard';
  final List<MediaItemWithFile> _mediaItems = [];
  GeoPoint _location = const GeoPoint(0, 0);
  String _locationName = '';
  String _message = '';
  MemoryPrivacy _privacy = MemoryPrivacy.private;
  
  // Getters
  String get selectedCapsule => _selectedCapsule;
  List<MediaItemWithFile> get mediaItems => _mediaItems;
  GeoPoint get location => _location;
  String get locationName => _locationName;
  String get message => _message;
  MemoryPrivacy get privacy => _privacy;
  
  // Status
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Set capsule type
  void setCapsuleType(String type) {
    _selectedCapsule = type;
    notifyListeners();
  }
  
  // Set location
  void setLocation(GeoPoint location, String name) {
    _location = location;
    _locationName = name;
    notifyListeners();
  }
  
  // Set message
  void setMessage(String message) {
    _message = message;
    notifyListeners();
  }
  
  // Set privacy
  void setPrivacy(MemoryPrivacy privacy) {
    _privacy = privacy;
    notifyListeners();
  }
  
  // Clear all data (reset)
  void reset() {
    _selectedCapsule = 'standard';
    
    // Revoke all object URLs before clearing
    for (var item in _mediaItems) {
      if (item.previewUrl != null) {
        _mediaPicker.revokeObjectUrl(item.previewUrl!);
      }
    }
    
    _mediaItems.clear();
    _location = const GeoPoint(0, 0);
    _locationName = '';
    _message = '';
    _privacy = MemoryPrivacy.private;
    notifyListeners();
  }
  
  // Pick images
  Future<void> pickImages() async {
    _setLoading(true);
    
    try {
      final files = await _mediaPicker.pickImages();
      
      // Check file size limits (1MB for Firestore implementation)
      for (var file in files) {
        if (file.size > 1024 * 1024) {
          _setError('File ${file.name} exceeds 1MB limit. Please use a smaller file.');
          _setLoading(false);
          return;
        }
      }
      
      for (var file in files) {
        // Create a temporary URL for preview
        final previewUrl = _mediaPicker.createObjectUrl(file);
        
        // Add to mediaItems list
        _mediaItems.add(
          MediaItemWithFile(
            file: file,
            previewUrl: previewUrl,
            type: 'image',
            uploadProgress: 0,
            isUploaded: false,
          ),
        );
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to pick images: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Pick videos
  Future<void> pickVideos() async {
    _setLoading(true);
    
    try {
      final files = await _mediaPicker.pickVideos();
      
      // Check file size limits (1MB for Firestore implementation)
      for (var file in files) {
        if (file.size > 1024 * 1024) {
          _setError('File ${file.name} exceeds 1MB limit. Please use a smaller file.');
          _setLoading(false);
          return;
        }
      }
      
      for (var file in files) {
        // Create a temporary URL for preview
        final previewUrl = _mediaPicker.createObjectUrl(file);
        
        // Add to mediaItems list
        _mediaItems.add(
          MediaItemWithFile(
            file: file,
            previewUrl: previewUrl,
            type: 'video',
            uploadProgress: 0,
            isUploaded: false,
          ),
        );
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to pick videos: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Pick audio
  Future<void> pickAudio() async {
    _setLoading(true);
    
    try {
      final files = await _mediaPicker.pickAudio();
      
      // Check file size limits (1MB for Firestore implementation)
      for (var file in files) {
        if (file.size > 1024 * 1024) {
          _setError('File ${file.name} exceeds 1MB limit. Please use a smaller file.');
          _setLoading(false);
          return;
        }
      }
      
      for (var file in files) {
        // Audio files don't have visual previews, but we need the URL for playback
        final previewUrl = _mediaPicker.createObjectUrl(file);
        
        // Add to mediaItems list
        _mediaItems.add(
          MediaItemWithFile(
            file: file,
            previewUrl: previewUrl,
            type: 'audio',
            uploadProgress: 0,
            isUploaded: false,
          ),
        );
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to pick audio: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Remove media item
  void removeMediaItem(int index) {
    if (index >= 0 && index < _mediaItems.length) {
      // Revoke object URL to avoid memory leaks
      if (_mediaItems[index].previewUrl != null) {
        _mediaPicker.revokeObjectUrl(_mediaItems[index].previewUrl!);
      }
      
      _mediaItems.removeAt(index);
      notifyListeners();
    }
  }
  
  // Clear all media
  void clearMedia() {
    // Revoke all object URLs
    for (var item in _mediaItems) {
      if (item.previewUrl != null) {
        _mediaPicker.revokeObjectUrl(item.previewUrl!);
      }
    }
    
    _mediaItems.clear();
    notifyListeners();
  }
  
  // Save memory capsule
  Future<String?> saveMemoryCapsule() async {
    if (currentUserId == null) {
      _setError('User not authenticated');
      return null;
    }
    
    _setLoading(true);
    
    try {
      // Upload all media files to Firestore
      final uploadedMedia = <MediaItem>[];
      
      for (int i = 0; i < _mediaItems.length; i++) {
        final item = _mediaItems[i];
        
        // Update progress in UI
        void updateProgress(double progress) {
          _mediaItems[i] = item.copyWith(
            uploadProgress: progress,
          );
          notifyListeners();
        }
        
        // Upload to Firestore as base64
        final mediaItem = await _storageService.uploadMedia(
          file: item.file,
          mediaType: item.type,
          onProgress: updateProgress,
        );
        
        // Mark as uploaded
        _mediaItems[i] = item.copyWith(
          isUploaded: true,
          uploadProgress: 1.0,
          uploadedItem: mediaItem,
        );
        notifyListeners();
        
        // Add to final list
        uploadedMedia.add(mediaItem);
      }
      
      // Create memory capsule
      final memory = MemoryCapsule(
        userId: currentUserId!,
        capsuleType: _selectedCapsule,
        media: uploadedMedia,
        location: _location,
        locationName: _locationName,
        message: _message,
        createdAt: DateTime.now(),
        privacy: _privacy,
      );
      
      // Save to Firestore
      final savedMemory = await _repository.createMemory(memory);
      
      // Reset after successful save
      reset();
      
      return savedMemory.id;
    } catch (e) {
      _setError('Failed to save memory: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _error = null;
    }
    notifyListeners();
  }
  
  // Helper method to set error
  void _setError(String error) {
    _error = error;
    print('MemoryProvider Error: $error');
    notifyListeners();
  }
}

// Extension class to track file uploads
class MediaItemWithFile {
  final html.File file;
  final String? previewUrl;
  final String type;
  final double uploadProgress;
  final bool isUploaded;
  final MediaItem? uploadedItem;
  
  MediaItemWithFile({
    required this.file,
    this.previewUrl,
    required this.type,
    this.uploadProgress = 0.0,
    this.isUploaded = false,
    this.uploadedItem,
  });
  
  MediaItemWithFile copyWith({
    html.File? file,
    String? previewUrl,
    String? type,
    double? uploadProgress,
    bool? isUploaded,
    MediaItem? uploadedItem,
  }) {
    return MediaItemWithFile(
      file: file ?? this.file,
      previewUrl: previewUrl ?? this.previewUrl,
      type: type ?? this.type,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploaded: isUploaded ?? this.isUploaded,
      uploadedItem: uploadedItem ?? this.uploadedItem,
    );
  }
  
  // File metadata
  String get fileName => file.name;
  int get fileSize => file.size;
  String get fileType => file.type;
}