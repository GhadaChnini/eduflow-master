import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;
  int _selectedGrade = 0;
  String _lang = 'ar';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = Tr.t('fill_all_fields', _lang));
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _error = Tr.t('password_too_short', _lang));
      return;
    }
    setState(() { _loading = true; _error = null; });

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text('جاري إنشاء حسابك...', style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textDarkColor(context))),
          ],
        ),
      ),
    );

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: 'parent',
        gradeLevel: _selectedGrade > 0 ? _selectedGrade : null,
      );

      if (!mounted) return;
      try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
      setState(() => _loading = false);

      if (!mounted) return;
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        pageBuilder: (context, _, __) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(Tr.t('account_created', _lang),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.textDarkColor(context)),
                textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(Tr.t('login_now', _lang),
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)),
                textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.go('/auth/login');
              },
              child: Text(Tr.t('login_btn2', _lang),
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
      setState(() {
        _loading = false;
        _error = e.toString().contains('already registered') || e.toString().contains('already been registered')
            ? 'البريد الإلكتروني مستخدم بالفعل، سجل دخول أو استخدم بريداً آخر'
            : Tr.t('error_creating_account', _lang);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final inputFill = AppTheme.inputFillColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.go('/'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(AppTheme.isDark(context) ? 0.2 : 1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: borderC),
                    ),
                    child: Text(Tr.t('back_to_eduflow', _lang),
                      style: TextStyle(color: AppTheme.primary, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary, borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: const Center(child: Text('🎓', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 12),
              const Text('EduFlow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 8),
              Text(Tr.t('join_fun_title', _lang), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
              Text(Tr.t('create_account', _lang), style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: card, borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderC, width: 4),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Tr.t('full_name', _lang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.primary)),
                    const SizedBox(height: 8),
                    _buildTextField(Tr.t('name_placeholder', _lang), _nameController, inputFill, borderC),
                    const SizedBox(height: 20),
                    Text(Tr.t('email', _lang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.primary)),
                    const SizedBox(height: 8),
                    _buildTextField(Tr.t('email_placeholder', _lang), _emailController, inputFill, borderC, isLtr: true, inputType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    Text(Tr.t('password_label', _lang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.primary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDeco(Tr.t('password_min', _lang), inputFill, borderC, suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.primary),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      )),
                    ),
                    const SizedBox(height: 20),
                    Text(Tr.t('grade_optional', _lang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.primary)),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                        children: List.generate(AppConstants.grades.length, (index) {
                          final grade = AppConstants.grades[index];
                          final level = grade['level'] as int;
                          final isSelected = _selectedGrade == level;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedGrade = isSelected ? 0 : level),
                            child: Container(
                              width: 90,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryLight.withOpacity(AppTheme.isDark(context) ? 0.3 : 1) : inputFill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? AppTheme.primary : borderC, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Text('$level', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isSelected ? AppTheme.primary : textM)),
                                  const SizedBox(height: 4),
                                  Text(grade['name_fr'] as String, style: TextStyle(fontSize: 9, color: isSelected ? AppTheme.primary : textM, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFEE2E2), width: 2)),
                        child: Text('⚠️ $_error', style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo'), textAlign: TextAlign.right),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                        child: _loading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(Tr.t('start_adventure', _lang), style: TextStyle(fontSize: 17, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/auth/login'),
                        child: RichText(text: TextSpan(
                          text: Tr.t('have_account', _lang),
                          style: TextStyle(fontFamily: 'Cairo', color: textM, fontSize: 15, fontWeight: FontWeight.bold),
                          children: [TextSpan(text: Tr.t('login_link', _lang), style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900))],
                        )),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, Color fill, Color border, {TextInputType inputType = TextInputType.text, bool isLtr = false}) {
    return TextField(
      controller: controller, keyboardType: inputType,
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      textAlign: isLtr ? TextAlign.left : TextAlign.right,
      decoration: _inputDeco(hint, fill, border),
    );
  }

  InputDecoration _inputDeco(String hint, Color fill, Color border, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border, width: 4)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border, width: 4)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 4)),
      filled: true, fillColor: fill, suffixIcon: suffix,
    );
  }
}