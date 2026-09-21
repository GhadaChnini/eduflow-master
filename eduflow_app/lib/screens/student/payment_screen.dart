import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class PaymentScreen extends StatefulWidget {
  final String itemTitle;
  final int amount;
  final VoidCallback onSuccess;

  const PaymentScreen({
    super.key,
    required this.itemTitle,
    required this.amount,
    required this.onSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  String? _validate() {
    final cardNum = _cardNumberCtrl.text.replaceAll(' ', '');
    if (cardNum.isEmpty) return 'Card number is required';
    if (cardNum.length != 16) return 'Card number must be exactly 16 digits';
    if (!RegExp(r'^\d{16}$').hasMatch(cardNum)) return 'Card number must contain only digits';
    if (_cardNameCtrl.text.trim().isEmpty) return 'Cardholder name is required';
    if (_cardNameCtrl.text.trim().length < 3) return 'Cardholder name too short';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(_cardNameCtrl.text.trim())) return 'Name must contain only letters';
    final expiry = _expiryCtrl.text;
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return 'Expiry must be MM/YY format';
    final parts = expiry.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    final fullYear = 2000 + year;
    if (month < 1 || month > 12) return 'Invalid month (01-12)';
    if (fullYear < now.year || (fullYear == now.year && month < now.month)) return 'Card has expired';
    if (_cvvCtrl.text.isEmpty) return 'CVV is required';
    if (!RegExp(r'^\d{3,4}$').hasMatch(_cvvCtrl.text)) return 'CVV must be 3 or 4 digits';
    return null;
  }

  Future<void> _pay() async {
    final error = _validate();
    if (error != null) { setState(() => _error = error); return; }
    setState(() { _processing = true; _error = null; });
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          itemTitle: widget.itemTitle,
          amount: widget.amount,
          onDone: widget.onSuccess,
        ),
      ));
    }
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
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16))),
            ),
            const SizedBox(height: 20),
            const Text('💳', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            const Text('Secure Payment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
            const SizedBox(height: 4),
            Text(widget.itemTitle, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), fontFamily: 'Cairo')),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.lock, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text('SSL Secured  •  ${(widget.amount * 1.1).toStringAsFixed(2)} DT', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontFamily: 'Cairo')),
            ]),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Card Preview
            Container(
              width: double.infinity, height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('💳', style: TextStyle(fontSize: 28)),
                  const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontStyle: FontStyle.italic)),
                ]),
                const Spacer(),
                Text(
                  _cardNumberCtrl.text.isEmpty ? '•••• •••• •••• ••••' : _cardNumberCtrl.text,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cairo', letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_cardNameCtrl.text.isEmpty ? 'CARDHOLDER NAME' : _cardNameCtrl.text.toUpperCase(),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  Text(_expiryCtrl.text.isEmpty ? 'MM/YY' : _expiryCtrl.text,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ]),
              ]),
            ),
            const SizedBox(height: 28),
            // Card Number
            _label('Card Number', textM),
            TextField(
              controller: _cardNumberCtrl,
              keyboardType: TextInputType.number,
              maxLength: 19,
              onChanged: (v) {
                final formatted = _formatCardNumber(v.replaceAll(' ', ''));
                if (_cardNumberCtrl.text != formatted) {
                  _cardNumberCtrl.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
                }
                setState(() {});
              },
              style: TextStyle(fontFamily: 'Cairo', color: textD, fontSize: 16, letterSpacing: 2),
              decoration: _inputDec('1234 5678 9012 3456', inputFill, borderC, counterText: ''),
            ),
            const SizedBox(height: 16),
            _label('Cardholder Name', textM),
            TextField(
              controller: _cardNameCtrl,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontFamily: 'Cairo', color: textD),
              decoration: _inputDec('JOHN DOE', inputFill, borderC),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Expiry Date', textM),
                TextField(
                  controller: _expiryCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  onChanged: (v) {
                    if (v.length == 2 && !v.contains('/')) {
                      _expiryCtrl.value = TextEditingValue(text: '$v/', selection: const TextSelection.collapsed(offset: 3));
                    }
                    setState(() {});
                  },
                  style: TextStyle(fontFamily: 'Cairo', color: textD),
                  decoration: _inputDec('MM/YY', inputFill, borderC, counterText: ''),
                ),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('CVV', textM),
                TextField(
                  controller: _cvvCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  style: TextStyle(fontFamily: 'Cairo', color: textD),
                  decoration: _inputDec('•••', inputFill, borderC, counterText: ''),
                ),
              ])),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.error, fontFamily: 'Cairo', fontSize: 13)),
            ],
            const SizedBox(height: 24),
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Item', style: TextStyle(fontFamily: 'Cairo', color: textM)),
                  Flexible(child: Text(widget.itemTitle, style: TextStyle(fontFamily: 'Cairo', color: textD), textAlign: TextAlign.end)),
                ]),
                const Divider(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Price', style: TextStyle(fontFamily: 'Cairo', color: textM)),
                  Text('${widget.amount} DT', style: TextStyle(fontFamily: 'Cairo', color: textD)),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('EduFlow fee (10%)', style: TextStyle(fontFamily: 'Cairo', color: textM, fontSize: 12)),
                  Text('+${(widget.amount * 0.1).toStringAsFixed(2)} DT', style: TextStyle(fontFamily: 'Cairo', color: textM, fontSize: 12)),
                ]),
                const Divider(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('${(widget.amount * 1.1).toStringAsFixed(2)} DT', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2563EB))),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _processing ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: _processing
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Processing...', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                    ])
                  : Text('Pay ${(widget.amount * 1.1).toStringAsFixed(2)} DT', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
            )),
            const SizedBox(height: 12),
            Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock, size: 12, color: Color(0xFF059669)),
              const SizedBox(width: 4),
              Text('Your payment is secure and encrypted', style: TextStyle(fontSize: 11, fontFamily: 'Cairo', color: textM)),
            ])),
            const SizedBox(height: 80),
          ]),
        )),
      ]),
    );
  }

  Widget _label(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 13, fontFamily: 'Cairo', color: color, fontWeight: FontWeight.w500)),
  );

  InputDecoration _inputDec(String hint, Color fill, Color border, {String? counterText}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontFamily: 'Cairo', color: AppTheme.textMediumColor(context)),
    filled: true, fillColor: fill,
    counterText: counterText,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

// ─── Payment Success Screen ───────────────────────────────────────────────────

class PaymentSuccessScreen extends StatefulWidget {
  final String itemTitle;
  final int amount;
  final VoidCallback onDone;
  const PaymentSuccessScreen({super.key, required this.itemTitle, required this.amount, required this.onDone});
  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final textD = AppTheme.textDarkColor(context);
    final textM = AppTheme.textMediumColor(context);
    final card = AppTheme.cardColor(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF059669), width: 3)),
                child: const Center(child: Icon(Icons.check, color: Color(0xFF059669), size: 56)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: textD)),
            const SizedBox(height: 8),
            Text('You have been enrolled in', style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: textM)),
            const SizedBox(height: 4),
            Text(widget.itemTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF059669))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Amount paid', style: TextStyle(fontFamily: 'Cairo', color: textM)),
                  Text('${widget.amount} DT', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 16)),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Status', style: TextStyle(fontFamily: 'Cairo', color: textM)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                    child: const Text('Confirmed', style: TextStyle(fontFamily: 'Cairo', color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () { widget.onDone(); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              child: const Text('Continue', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
            )),
          ]),
        ),
      ),
    );
  }
}