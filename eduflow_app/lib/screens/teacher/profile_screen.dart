import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../config/translations.dart';
import '../../services/language_service.dart';

class TeacherProfileScreen extends ConsumerStatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  ConsumerState<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends ConsumerState<TeacherProfileScreen> {
  String _lang = 'ar';
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _changingEmail = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _newEmailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final res = await Supabase.instance.client.from('profiles').select().eq('id', user.id).single();
    if (mounted) {
      setState(() {
        _profile = Map<String, dynamic>.from(res);
        _nameController.text = _profile!['name'] ?? '';
        _bioController.text = _profile!['bio'] ?? '';
        _phoneController.text = _profile!['phone'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final user = Supabase.instance.client.auth.currentUser!;
    final path = 'avatars/${user.id}.${picked.name.split('.').last}';
    await Supabase.instance.client.storage.from('unit_content').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    final url = Supabase.instance.client.storage.from('unit_content').getPublicUrl(path);
    await Supabase.instance.client.from('profiles').update({'avatar_url': url}).eq('id', user.id);
    setState(() => _profile!['avatar_url'] = url);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final user = Supabase.instance.client.auth.currentUser!;
    await Supabase.instance.client.from('profiles').update({
      'name': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      'phone': _phoneController.text.trim(),
    }).eq('id', user.id);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Tr.t('profile_updated', _lang), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    final bg = AppTheme.bgColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final inputFill = AppTheme.inputFillColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF9D5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        Row(children: [
                          GestureDetector(
                            onTap: () => context.go('/teacher/settings'),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(Tr.t('my_profile', _lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                        ]),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: _profile?['avatar_url'] != null ? NetworkImage(_profile!['avatar_url']) : null,
                                child: _profile?['avatar_url'] == null
                                    ? Text((_nameController.text.isNotEmpty ? _nameController.text[0] : '؟').toUpperCase(),
                                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))
                                    : null,
                              ),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, size: 16, color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_nameController.text.isNotEmpty ? _nameController.text : Tr.t('teacher', _lang),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                        Text(_profile?['email'] ?? '', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                          child: Text('👩‍🏫 ${Tr.t("teacher", _lang)}', style: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _field(Tr.t('full_name', _lang), _nameController, textD, textM, borderC, inputFill, icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        _field(Tr.t('bio', _lang), _bioController, textD, textM, borderC, inputFill, maxLines: 4, icon: Icons.info_outline),
                        const SizedBox(height: 16),
                        _field(Tr.t('phone', _lang), _phoneController, textD, textM, borderC, inputFill, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                            child: _saving
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(Tr.t('save_changes', _lang), style: const TextStyle(fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, Color textD, Color textM, Color borderC, Color inputFill, {int maxLines = 1, IconData? icon, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(fontFamily: 'Cairo', color: textD),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: AppTheme.primary, size: 20) : null,
            filled: true, fillColor: inputFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}