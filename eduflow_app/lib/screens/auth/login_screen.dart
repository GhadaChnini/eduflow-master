import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;
  String _lang = 'ar';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = Tr.t('please_enter_email_password', _lang));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(email: _emailController.text.trim(), password: _passwordController.text);
      final profile = await authService.getCurrentProfile();
      final role = profile?['role'] ?? 'student';
      if (mounted) {
        if (role == 'teacher' || role == 'admin') {
          context.go('/teacher');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      setState(() => _error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
    } finally {
      if (mounted) setState(() => _loading = false);
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
              const SizedBox(height: 24),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: const Center(child: Text('🌟', style: TextStyle(fontSize: 36))),
              ),
              const SizedBox(height: 12),
              const Text('EduFlow', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const Text('Kids Learning ✨', style: TextStyle(fontSize: 13, color: AppTheme.secondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(Tr.t('welcome_back', _lang), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
              Text(Tr.t('glad_to_see_you', _lang), style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderC, width: 4),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Tr.t('email', _lang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.primary, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      decoration: _inputDecoration('your@email.com', inputFill, borderC),
                    ),
                    const SizedBox(height: 20),
                    Text(Tr.t('password_label', _lang), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.primary, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration('••••••••', inputFill, borderC, suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.primary),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      )),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFEE2E2), width: 2)),
                        child: Text('⚠️ $_error', style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo'), textAlign: _lang == 'ar' ? TextAlign.right : TextAlign.left),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                        child: _loading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(Tr.t('login_btn', _lang), style: TextStyle(fontSize: 17, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showForgotPassword(context),
                        child: Text(Tr.t('forgot_password', _lang), style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: Divider(color: AppTheme.isDark(context) ? Colors.grey.shade700 : Colors.purple.shade100, thickness: 2)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(Tr.t('or', _lang), style: TextStyle(fontFamily: 'Cairo', color: textM))),
                      Expanded(child: Divider(color: AppTheme.isDark(context) ? Colors.grey.shade700 : Colors.purple.shade100, thickness: 2)),
                    ]),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/auth/register'),
                        child: RichText(text: TextSpan(
                          text: Tr.t('new_user', _lang),
                          style: TextStyle(fontFamily: 'Cairo', color: textM, fontSize: 15, fontWeight: FontWeight.bold),
                          children: [TextSpan(text: Tr.t('join_fun', _lang), style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900))],
                        )),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/auth/teacher-login'),
                        child: Text(Tr.t('teacher_login', _lang), style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showForgotPassword(BuildContext context) async {
    final emailCtrl = TextEditingController(text: _emailController.text);
    bool sending = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('🔑', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(Tr.t('forgot_password', _lang), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: AppTheme.textDarkColor(context))),
              const SizedBox(height: 8),
              Text(Tr.t('forgot_password_hint', _lang), style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textDarkColor(context)),
                decoration: InputDecoration(
                  hintText: Tr.t('email', _lang),
                  hintStyle: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primary),
                  filled: true,
                  fillColor: AppTheme.inputFillColor(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.borderColor(context))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sending ? null : () async {
                    if (emailCtrl.text.trim().isEmpty) return;
                    setState(() => sending = true);
                    try {
                      await Supabase.instance.client.auth.resetPasswordForEmail(emailCtrl.text.trim());
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(Tr.t('reset_email_sent', _lang), style: const TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                        ));
                      }
                    } catch (e) {
                      setState(() => sending = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                  child: sending
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(Tr.t('send_reset_link', _lang), style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color fill, Color border, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border, width: 4)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border, width: 4)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 4)),
      filled: true, fillColor: fill, suffixIcon: suffix,
    );
  }
}