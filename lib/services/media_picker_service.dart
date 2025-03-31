// lib/services/media_picker_service.dart
import 'dart:html' as html;
import 'dart:async';

class MediaPickerService {
  // Pick images from the browser
  Future<List<html.File>> pickImages({bool multiple = true}) async {
    final completer = Completer<List<html.File>>();
    final input = html.FileUploadInputElement();
    
    input.accept = 'image/*';
    input.multiple = multiple;
    
    // Add event listener for when files are selected
    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        completer.complete(List<html.File>.from(files));
      } else {
        completer.complete([]);
      }
    });
    
    // Handle when the dialog is cancelled
    input.addEventListener('cancel', (event) {
      completer.complete([]);
    });
    
    // Trigger file selection dialog
    input.click();
    
    return completer.future;
  }
  
  // Pick videos from the browser
  Future<List<html.File>> pickVideos({bool multiple = true}) async {
    final completer = Completer<List<html.File>>();
    final input = html.FileUploadInputElement();
    
    input.accept = 'video/*';
    input.multiple = multiple;
    
    // Add event listener for when files are selected
    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        completer.complete(List<html.File>.from(files));
      } else {
        completer.complete([]);
      }
    });
    
    // Handle when the dialog is cancelled
    input.addEventListener('cancel', (event) {
      completer.complete([]);
    });
    
    // Trigger file selection dialog
    input.click();
    
    return completer.future;
  }
  
  // Pick audio files from the browser
  Future<List<html.File>> pickAudio({bool multiple = true}) async {
    final completer = Completer<List<html.File>>();
    final input = html.FileUploadInputElement();
    
    input.accept = 'audio/*';
    input.multiple = multiple;
    
    // Add event listener for when files are selected
    input.onChange.listen((event) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        completer.complete(List<html.File>.from(files));
      } else {
        completer.complete([]);
      }
    });
    
    // Handle when the dialog is cancelled
    input.addEventListener('cancel', (event) {
      completer.complete([]);
    });
    
    // Trigger file selection dialog
    input.click();
    
    return completer.future;
  }
  
  // Create a temporary URL for a file (for preview)
  String createObjectUrl(html.File file) {
    return html.Url.createObjectUrl(file);
  }
  
  // Revoke a temporary URL when no longer needed
  void revokeObjectUrl(String url) {
    html.Url.revokeObjectUrl(url);
  }
}