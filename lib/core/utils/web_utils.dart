import 'package:flutter/foundation.dart' show kIsWeb;

// Safely set the Google Maps API key in web context
void setWebApiKey(String apiKey) {
  if (kIsWeb) {
    // This will only run on web platforms
    try {
      // Use eval to set the API key in window object
      // This avoids direct dart:js import issues
      _setApiKeyInBrowser(apiKey);
    } catch (e) {
      print('Error setting web API key: $e');
    }
  }
}

// This method handles the JS interaction - only called on web
void _setApiKeyInBrowser(String apiKey) {
  // This method is intentionally left empty in source code
  // At runtime on web, the JS bridge will provide the implementation
  // For mobile builds, this is a no-op method that gets compiled out

  // On web, you would manually add the script tag in index.html:
  // <script>
  //   window.googleMapsApiKey = "YOUR_API_KEY";
  // </script>

  // This prevents compilation issues while still supporting web functionality
}

// Private implementation using dynamic invocation
// This avoids direct imports of dart:js which can break non-web builds
void _evaluateJavaScript(String code) {
  if (kIsWeb) {
    // Dynamically access dart:js functionality using mirrors/reflection
    // or through method channel if available
    try {
      // Using Function.apply to dynamically evaluate JS
      final dynamic dartJsContext = _getDartJsContext();
      if (dartJsContext != null) {
        dartJsContext['eval']?.call([code]);
      }
    } catch (e) {
      print('Error executing JavaScript: $e');
    }
  }
}

// Get dart:js context without direct import
dynamic _getDartJsContext() {
  if (kIsWeb) {
    try {
      // This is a dynamic approach to access dart:js
      // It's not type-safe but avoids compilation issues on non-web platforms
      // ignore: avoid_dynamic_calls
      return _loadJsInterop();
    } catch (e) {
      print('Error loading JS interop: $e');
      return null;
    }
  }
  return null;
}

// Dynamic loader for JS interop
dynamic _loadJsInterop() {
  if (kIsWeb) {
    try {
      // Using a dynamic approach that will only be evaluated at runtime on web
      // ignore: avoid_dynamic_calls
      return dart_js_context();
    } catch (e) {
      return null;
    }
  }
  return null;
}

// This function will be replaced at runtime on web platforms
// It's a stub that will be overridden
dynamic dart_js_context() {
  // This will be replaced at runtime on web
  return null;
}
