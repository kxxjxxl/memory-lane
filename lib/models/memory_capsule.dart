// lib/models/memory_capsule.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
    );
  }
}