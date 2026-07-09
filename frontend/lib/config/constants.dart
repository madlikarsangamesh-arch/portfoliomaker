import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'AI Portfolio Engineer';
  
  // Base API URL
  static String get baseApiUrl {
    if (kDebugMode) {
      if (kIsWeb) {
        return 'http://localhost:8000/api/v1';
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8000/api/v1';
      }
      return 'http://localhost:8000/api/v1';
    }
    // Production live Render backend API
    return 'https://portfoliomaker-fxke.onrender.com/api/v1';
  }
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userFullNameKey = 'user_fullname';
}
