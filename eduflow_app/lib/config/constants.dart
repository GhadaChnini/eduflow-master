class AppConstants {
  // Supabase
  static const String supabaseUrl = 'https://sdtaqwkqtmccutjyodpg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkdGFxd2txdG1jY3V0anlvZHBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1NzQxMTMsImV4cCI6MjEwMjE1MDExM30.vcvcAJBRDlRZTD8R02Z547gYnVgtVmMhmtRWawmwRwU';

  // App Info
  static const String appName = 'EduFlow';
  static const String appNameAr = 'إيدوفلو';

  // Colors
  static const int primaryColor = 0xFF7C3AED;
  static const int secondaryColor = 0xFFEC4899;
  static const int accentColor = 0xFFF59E0B;
  static const int successColor = 0xFF059669;
  static const int errorColor = 0xFFDC2626;
  static const int backgroundColor = 0xFFF9FAFB;

  // Payment
  static const double platformFeePercent = 5.0;
  static const double fixedFee = 2.0;

  // PIN
  static const int pinLength = 4;

  // Grades
  static const List<Map<String, dynamic>> grades = [
    {'level': 1, 'name_ar': 'السنة الأولى', 'name_fr': '1ère année'},
    {'level': 2, 'name_ar': 'السنة الثانية', 'name_fr': '2ème année'},
    {'level': 3, 'name_ar': 'السنة الثالثة', 'name_fr': '3ème année'},
    {'level': 4, 'name_ar': 'السنة الرابعة', 'name_fr': '4ème année'},
    {'level': 5, 'name_ar': 'السنة الخامسة', 'name_fr': '5ème année'},
    {'level': 6, 'name_ar': 'السنة السادسة', 'name_fr': '6ème année'},
  ];

  // Languages
  static const String langAr = 'ar';
  static const String langFr = 'fr';
  static const String langEn = 'en';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String langKey = 'app_language';
  static const String pinKey = 'parent_pin';
  static const String themeKey = 'app_theme';
}