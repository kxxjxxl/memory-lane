// lib/models/memory_capsule.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Define privacy enum values for type safety
enum MemoryPrivacy {
  private,
  public,
}

// Extension to convert enum to string for Firestore storage
extension MemoryPrivacyExtension on MemoryPrivacy {
  String get value {
    switch (this) {
      case MemoryPrivacy.private:
        return 'private';
      case MemoryPrivacy.public:
        return 'public';
    }
  }
  
  // Helper method for display name
  String get displayName {
    switch (this) {
      case MemoryPrivacy.private:
        return 'Private';
      case MemoryPrivacy.public:
        return 'Public';
    }
  }
  
  // Helper method for description
  String get description {
    switch (this) {
      case MemoryPrivacy.private:
        return 'Only visible to you';
      case MemoryPrivacy.public:
        return 'Visible to everyone within 5km';
    }
  }
  
  // Helper method for icon
  IconData get icon {
    switch (this) {
      case MemoryPrivacy.private:
        return Icons.lock_outline;
      case MemoryPrivacy.public:
        return Icons.public;
    }
  }
}

// Helper to convert string to enum
MemoryPrivacy privacyFromString(String? value) {
  if (value == 'public') {
    return MemoryPrivacy.public;
  }
  return MemoryPrivacy.private; // Default to private
}

class MediaItem {
  final String url;
  final String type; // 'image', 'video', 'audio'
  final String? thumbnailUrl;
  final String fileName;

  MediaItem({
    required this.url,
    required this.type,
    this.thumbnailUrl,
    required this.fileName,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      url: json['url'] ?? '',
      type: json['type'] ?? 'image',
      thumbnailUrl: json['thumbnailUrl'],
      fileName: json['fileName'] ?? '',
    );
  }
}

class MemoryCapsule {
  final String? id;
  final String userId;
  final String capsuleType;
  final List<MediaItem> media;
  final GeoPoint location;
  final String locationName;
  final String message;
  final DateTime createdAt;
  final DateTime? lastUpdatedAt;
  final MemoryPrivacy privacy; // New privacy field

  MemoryCapsule({
    this.id,
    required this.userId,
    required this.capsuleType,
    required this.media,
    required this.location,
    required this.locationName,
    required this.message,
    required this.createdAt,
    this.lastUpdatedAt,
    this.privacy = MemoryPrivacy.private, // Default to private
  });

  String get type => capsuleType;
  List<MediaItem> get mediaItems => media;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'capsuleType': capsuleType,
      'media': media.map((item) => item.toJson()).toList(),
      'location': location,
      'locationName': locationName,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': lastUpdatedAt != null
          ? Timestamp.fromDate(lastUpdatedAt!)
          : null,
      'privacy': privacy.value, // Store the string value
    };
  }

  factory MemoryCapsule.fromJson(Map<String, dynamic> json, String docId) {
    List<MediaItem> mediaList = [];
    if (json['media'] != null) {
      mediaList = List<MediaItem>.from(
        (json['media'] as List).map(
          (item) => MediaItem.fromJson(item),
        ),
      );
    }

    return MemoryCapsule(
      id: docId,
      userId: json['userId'] ?? '',
      capsuleType: json['capsuleType'] ?? 'standard',
      media: mediaList,
      location: json['location'] ?? const GeoPoint(0, 0),
      locationName: json['locationName'] ?? '',
      message: json['message'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? (json['lastUpdatedAt'] as Timestamp).toDate()
          : null,
      privacy: privacyFromString(json['privacy']), // Convert from string
    );
  }

  MemoryCapsule copyWith({
    String? id,
    String? userId,
    String? capsuleType,
    List<MediaItem>? media,
    GeoPoint? location,
    String? locationName,
    String? message,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    MemoryPrivacy? privacy,
  }) {
    return MemoryCapsule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      capsuleType: capsuleType ?? this.capsuleType,
      media: media ?? this.media,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      privacy: privacy ?? this.privacy,
    );
  }
}