import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../services/language_service.dart';
import '../../config/translations.dart';

class ApplyTeacherScreen extends ConsumerStatefulWidget {
  const ApplyTeacherScreen({super.key});

  @override
  ConsumerState<ApplyTeacherScreen> createState() => _ApplyTeacherScreenState();
}

class _ApplyTeacherScreenState extends ConsumerState<ApplyTeacherScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  XFile? _cvFile;
  bool _loading = false;
  String? _error;
  String _lang = 'ar';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(label: 'documents', extensions: ['pdf', 'doc', 'docx']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        setState(() => _error = 'حجم الملف يجب أن يكون أقل من 5 ميغابايت');
        return;
      }
      setState(() => _cvFile = file);
    }
  }

  Future<String?> _uploadCV() async {
    if (_cvFile == null) return null;
    try {
      final supabase = Supabase.instance.client;
      final bytes = await _cvFile!.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_cvFile!.name}';
      await supabase.storage.from('cvs').uploadBinary(fileName, bytes,
        fileOptions: const FileOptions(contentType: 'application/pdf'));
      return supabase.storage.from('cvs').getPublicUrl(fileName);
    } catch (e) {
      print('CV upload error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _bioController.text.isEmpty) {
      setState(() => _error = Tr.t('fill_all_fields', _lang));
      return;
    }
    if (_cvFile == null) {
      setState(() => _error = Tr.t('upload_cv_required', _lang));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final supabase = Supabase.instance.client;
      final existing = await supabase.from('teacher_applications').select('id, status').eq('email', _emailController.text.trim()).maybeSingle();
      if (existing != null) {
        final status = existing['status'] as String?;
        if (status == 'pending') {
          setState(() { _error = Tr.t('pending_application', _lang); _loading = false; });
          return;
        } else if (status == 'approved') {
          setState(() { _error = Tr.t('already_approved', _lang); _loading = false; });
          return;
        } else if (status == 'rejected') {
          await supabase.from('teacher_applications').delete().eq('email', _emailController.text.trim());
        }
      }
      final cvUrl = await _uploadCV();
      await supabase.from('teacher_applications').insert({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'cv_url': cvUrl,
        'status': 'pending',
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardColor(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(Tr.t('request_received', _lang),
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppTheme.textDarkColor(context)),
              textAlign: TextAlign.center),
            content: Text(Tr.t('check_email', _lang),
              style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)),
              textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(context); context.go('/'); },
                child: Text(Tr.t('excellent', _lang), style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _error = Tr.t('error_try_again', _lang));
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
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: bg,
                child: Align(
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
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: card, borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderC, width: 4),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('👩‍🏫', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 12),
                            Text(Tr.t('join_teachers', _lang),
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD),
                              textAlign: TextAlign.center),
                            Text(Tr.t('submit_data', _lang),
                              style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: textM),
                              textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(Tr.t('display_name', _lang), textD),
                            const SizedBox(height: 8),
                            _buildTextField(_nameController, Tr.t('name_example', _lang), inputFill, borderC),
                            const SizedBox(height: 16),
                            _buildLabel(Tr.t('email_label', _lang), textD),
                            const SizedBox(height: 8),
                            _buildTextField(_emailController, 'name@example.com', inputFill, borderC, isLtr: true, inputType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildLabel(Tr.t('bio_skills', _lang), textD),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _bioController, maxLines: 4,
                              textDirection: TextDirection.rtl,
                              decoration: _inputDecoration(Tr.t('bio_placeholder', _lang), inputFill, borderC),
                            ),
                            const SizedBox(height: 16),
                            _buildLabel(Tr.t('cv_file', _lang), textD),
                            const SizedBox(height: 8),
                            if (_cvFile == null)
                              GestureDetector(
                                onTap: _pickFile,
                                child: Container(
                                  width: double.infinity, padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: inputFill, borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderC, width: 3),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('📤', style: TextStyle(fontSize: 32)),
                                      const SizedBox(height: 8),
                                      Text(Tr.t('upload_cv', _lang),
                                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD)),
                                      Text(Tr.t('cv_size', _lang),
                                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: textM)),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight.withOpacity(AppTheme.isDark(context) ? 0.2 : 1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primary, width: 3),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                                      child: const Center(child: Text('📄', style: TextStyle(fontSize: 20))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(_cvFile!.name,
                                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: textD),
                                      overflow: TextOverflow.ellipsis)),
                                    IconButton(
                                      onPressed: () => setState(() => _cvFile = null),
                                      icon: const Text('✕', style: TextStyle(color: AppTheme.secondary, fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFEE2E2), width: 2)),
                                child: Text('⚠️ $_error', style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo')),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                                child: _loading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(Tr.t('send_request', _lang), style: TextStyle(fontSize: 15, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) => Text(text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: color));

  Widget _buildTextField(TextEditingController controller, String hint, Color fill, Color border,
      {TextInputType inputType = TextInputType.text, bool isLtr = false}) {
    return TextField(
      controller: controller, keyboardType: inputType,
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      decoration: _inputDecoration(hint, fill, border),
    );
  }

  InputDecoration _inputDecoration(String hint, Color fill, Color border) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(fontFamily: 'Cairo'),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border, width: 4)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border, width: 4)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 4)),
      filled: true, fillColor: fill,
    );
  }
}