import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super(AppConstants.langAr) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(AppConstants.langKey) ?? AppConstants.langAr;
    state = lang;
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.langKey, lang);
    state = lang;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

// Translation helper
class AppTranslations {
  static final Map<String, Map<String, String>> _translations = {
    'ar': {
      'app_name': 'إيدوفلو',
      'welcome': 'مرحبا',
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'name': 'الاسم',
      'grade': 'السنة الدراسية',
      'continue': 'متابعة',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'search': 'بحث',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'success': 'تم بنجاح',
      'logout': 'تسجيل الخروج',
      'home': 'الرئيسية',
      'courses': 'الوحدات',
      'profile': 'الملف الشخصي',
      'notifications': 'الإشعارات',
      'settings': 'الإعدادات',
      'teacher': 'الأستاذ',
      'student': 'التلميذ',
      'parent': 'الولي',
      'points': 'نقاط',
      'rank': 'الترتيب',
      'badges': 'الشارات',
      'free': 'مجاني',
      'paid': 'مدفوع',
      'enroll': 'التسجيل',
      'enrolled': 'مسجل',
      'lock_screen': 'قفل الشاشة',
      'enter_pin': 'أدخل الرمز السري',
      'set_pin': 'إنشاء رمز سري',
      'language': 'اللغة',
      'arabic': 'العربية',
      'french': 'الفرنسية',
      'english': 'الإنجليزية',
    },
    'fr': {
      'app_name': 'EduFlow',
      'welcome': 'Bienvenue',
      'login': 'Se connecter',
      'register': 'Créer un compte',
      'email': 'Email',
      'password': 'Mot de passe',
      'name': 'Nom',
      'grade': 'Niveau scolaire',
      'continue': 'Continuer',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'search': 'Rechercher',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'success': 'Succès',
      'logout': 'Déconnexion',
      'home': 'Accueil',
      'courses': 'Unités',
      'profile': 'Profil',
      'notifications': 'Notifications',
      'settings': 'Paramètres',
      'teacher': 'Enseignant',
      'student': 'Élève',
      'parent': 'Parent',
      'points': 'Points',
      'rank': 'Classement',
      'badges': 'Badges',
      'free': 'Gratuit',
      'paid': 'Payant',
      'enroll': 'S\'inscrire',
      'enrolled': 'Inscrit',
      'lock_screen': 'Verrouiller',
      'enter_pin': 'Entrez le code PIN',
      'set_pin': 'Créer un code PIN',
      'language': 'Langue',
      'arabic': 'Arabe',
      'french': 'Français',
      'english': 'Anglais',
    },
    'en': {
      'app_name': 'EduFlow',
      'welcome': 'Welcome',
      'login': 'Sign In',
      'register': 'Create Account',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'grade': 'Grade Level',
      'continue': 'Continue',
      'save': 'Save',
      'cancel': 'Cancel',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'logout': 'Logout',
      'home': 'Home',
      'courses': 'Units',
      'profile': 'Profile',
      'notifications': 'Notifications',
      'settings': 'Settings',
      'teacher': 'Teacher',
      'student': 'Student',
      'parent': 'Parent',
      'points': 'Points',
      'rank': 'Rank',
      'badges': 'Badges',
      'free': 'Free',
      'paid': 'Paid',
      'enroll': 'Enroll',
      'enrolled': 'Enrolled',
      'lock_screen': 'Lock Screen',
      'enter_pin': 'Enter PIN',
      'set_pin': 'Set PIN',
      'language': 'Language',
      'arabic': 'Arabic',
      'french': 'French',
      'english': 'English',
    },
  };

  static String translate(String key, String language) {
    return _translations[language]?[key] ?? _translations['ar']?[key] ?? key;
  }
}