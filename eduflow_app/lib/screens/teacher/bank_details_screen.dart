import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../services/language_service.dart';

class TeacherBankDetailsScreen extends ConsumerStatefulWidget {
  const TeacherBankDetailsScreen({super.key});
  @override
  ConsumerState<TeacherBankDetailsScreen> createState() => _TeacherBankDetailsScreenState();
}

class _TeacherBankDetailsScreenState extends ConsumerState<TeacherBankDetailsScreen> {
  final _ibanCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _ibanError;
  String? _bankError;
  String? _holderError;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _ibanCtrl.dispose(); _bankCtrl.dispose(); _holderCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('bank_iban, bank_name, bank_holder')
          .eq('id', user.id)
          .single();
      _ibanCtrl.text = res['bank_iban'] ?? '';
      _bankCtrl.text = res['bank_name'] ?? '';
      _holderCtrl.text = res['bank_holder'] ?? '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String? _validateIban(String val) {
    final cleaned = val.replaceAll(' ', '').toUpperCase();
    if (cleaned.isEmpty) return 'IBAN is required';
    if (cleaned.length < 15 || cleaned.length > 34) return 'IBAN must be 15–34 characters';
    if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]+$').hasMatch(cleaned)) return 'Invalid IBAN format (e.g. TN59 1234...)';
    return null;
  }

  String? _validateBank(String val) {
    if (val.trim().isEmpty) return 'Bank name is required';
    if (val.trim().length < 2) return 'Bank name too short';
    return null;
  }

  String? _validateHolder(String val) {
    if (val.trim().isEmpty) return 'Account holder name is required';
    if (val.trim().length < 3) return 'Name too short';
    if (!RegExp(r'^[a-zA-Z\s\u0600-\u06FF]+$').hasMatch(val.trim())) return 'Name must contain only letters';
    return null;
  }

  Future<void> _save() async {
    setState(() {
      _ibanError = _validateIban(_ibanCtrl.text);
      _bankError = _validateBank(_bankCtrl.text);
      _holderError = _validateHolder(_holderCtrl.text);
    });
    if (_ibanError != null || _bankError != null || _holderError != null) return;

    setState(() => _saving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('profiles').update({
        'bank_iban': _ibanCtrl.text.replaceAll(' ', '').toUpperCase(),
        'bank_name': _bankCtrl.text.trim(),
        'bank_holder': _holderCtrl.text.trim(),
      }).eq('id', user.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bank details saved', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ));
    } catch (e) { debugPrint('Save bank error: $e'); }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.bgColor(context);
    final card = AppTheme.cardColor(context);
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final borderC = AppTheme.borderColor(context);
    final inputFill = AppTheme.inputFillColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bank Details', style: TextStyle(fontFamily: 'Cairo')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF059669).withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'Your bank details are used to receive payment withdrawals from EduFlow.',
                      style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: textM),
                    )),
                  ]),
                ),
                const SizedBox(height: 24),
                _label('IBAN', textM),
                _textField(
                  _ibanCtrl, 'TN59 1234 5678 9012 3456 78',
                  textD, textM, borderC, inputFill,
                  error: _ibanError,
                  onChanged: (v) => setState(() => _ibanError = null),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                _label('Bank Name', textM),
                _textField(
                  _bankCtrl, 'e.g. STB, BNA, Attijari...',
                  textD, textM, borderC, inputFill,
                  error: _bankError,
                  onChanged: (v) => setState(() => _bankError = null),
                ),
                const SizedBox(height: 16),
                _label('Account Holder Name', textM),
                _textField(
                  _holderCtrl, 'Full name as on bank account',
                  textD, textM, borderC, inputFill,
                  error: _holderError,
                  onChanged: (v) => setState(() => _holderError = null),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Bank Details', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                )),
              ]),
            ),
    );
  }

  Widget _label(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: color, fontWeight: FontWeight.w500)),
  );

  Widget _textField(
    TextEditingController ctrl, String hint, Color textD, Color textM, Color borderC, Color inputFill, {
    String? error, ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    TextField(
      controller: ctrl,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: TextStyle(fontFamily: 'Cairo', color: textD),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: 'Cairo', color: textM),
        filled: true, fillColor: inputFill,
        errorText: error,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderC)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: error != null ? AppTheme.error : borderC)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: error != null ? AppTheme.error : const Color(0xFF059669), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  ]);
}