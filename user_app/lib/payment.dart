import 'package:admin_app/main.dart';
import 'package:admin_app/success.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final int id;
  final int amt;

  const PaymentGatewayScreen({
    super.key,
    required this.id,
    required this.amt,
    required List<dynamic> purchasedItems,
  });

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isProcessing = false;

  final TextEditingController cardNumber = TextEditingController();
  final TextEditingController cardName = TextEditingController();
  final TextEditingController expiry = TextEditingController();
  final TextEditingController cvv = TextEditingController();

  // ── Palette (Synchronized with Global Dark Brand Identity) ────────────────
  static const Color _bg = Color(0xff0D0A14);
  static const Color _cardBg = Color(0xff161124);
  static const Color _surfaceAlt = Color(0xff1A142A);
  static const Color _border = Color(0xff2A1F3D);
  static const Color _accentPurple = Color(0xffA855F7);
  static const Color _accentPink = Color(0xffEC4899);
  static const Color _subtext = Color(0xff9CA3AF);
  static const Color _error = Color(0xffEF4444);

  static const LinearGradient _brandGradient = LinearGradient(
    colors: [_accentPurple, _accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Future<void> checkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      await supabase
          .from('tbl_cart')
          .update({'cart_status': 2})
          .eq('booking_id', widget.id);

      await supabase
          .from('tbl_booking')
          .update({'booking_status': 2, 'booking_amount': widget.amt})
          .eq('booking_id', widget.id);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentSuccessPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment Failed", style: GoogleFonts.outfit()),
          backgroundColor: _error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: _cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          "Secure Payment",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              /// HIGH FIDELITY CREDIT CARD CONTAINER UI
              Container(
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: _brandGradient,
                  boxShadow: [
                    BoxShadow(
                      color: _accentPurple.withOpacity(.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.credit_card_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        Text(
                          "VISA",
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    Text(
                      cardNumber.text.isEmpty
                          ? "XXXX XXXX XXXX XXXX"
                          : cardNumber.text,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CARD HOLDER",
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cardName.text.isEmpty
                                    ? "YOUR NAME"
                                    : cardName.text.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "EXPIRES",
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              expiry.text.isEmpty ? "MM/YY" : expiry.text,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              /// INJECTION PAYMENT INPUT FIELDS FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    /// CARD NUMBER INPUT
                    TextFormField(
                      controller: cardNumber,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        CardFormatter(),
                      ],
                      decoration: _inputDecoration(
                        "Card Number",
                        Icons.payment_rounded,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.replaceAll(" ", "").length != 16) {
                          return "Enter valid 16 digit card number";
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 18),

                    /// CARD HOLDER INPUT
                    TextFormField(
                      controller: cardName,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: _inputDecoration(
                        "Card Holder Name",
                        Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter name";
                        }

                        if (!RegExp(r'^[a-zA-Z ]{3,25}$').hasMatch(value)) {
                          return "Enter valid name";
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        /// EXPIRY CONTROL
                        Expanded(
                          child: TextFormField(
                            controller: expiry,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              ExpiryFormatter(),
                            ],
                            decoration: _inputDecoration(
                              "Expiry MM/YY",
                              Icons.calendar_today_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.length != 5) {
                                return "Invalid";
                              }

                              final parts = value.split('/');
                              int month = int.parse(parts[0]);
                              int year = int.parse(parts[1]);

                              if (month < 1 || month > 12) {
                                return "Invalid";
                              }

                              final now = DateTime.now();
                              int currentYear = now.year % 100;
                              int currentMonth = now.month;

                              if (year < currentYear ||
                                  (year == currentYear &&
                                      month < currentMonth)) {
                                return "Expired";
                              }

                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),

                        const SizedBox(width: 14),

                        /// SECURE CVV INPUT FIELD
                        Expanded(
                          child: TextFormField(
                            controller: cvv,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: _inputDecoration(
                              "CVV",
                              Icons.lock_outline_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.length != 3) {
                                return "Invalid";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    /// SUBMIT BUTTON ENGINE
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: _isProcessing ? null : _brandGradient,
                          color: _isProcessing
                              ? _accentPurple.withOpacity(0.5)
                              : null,
                          boxShadow: [
                            if (!_isProcessing)
                              BoxShadow(
                                color: _accentPurple.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  "Pay ₹${widget.amt}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          size: 14,
                          color: _subtext,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Secure Payment Powered by UvSense",
                          style: GoogleFonts.outfit(
                            color: _subtext,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(
        color: const Color(0xff4B5563),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: _accentPurple, size: 20),
      filled: true,
      fillColor: _surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentPurple, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _error, width: 1.2),
      ),
    );
  }
}

class CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(" ", "");

    if (text.length > 16) return oldValue;

    var newText = "";

    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) newText += " ";
      newText += text[i];
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll("/", "");

    if (text.length > 4) return oldValue;

    if (text.length >= 3) {
      text = "${text.substring(0, 2)}/${text.substring(2)}";
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
