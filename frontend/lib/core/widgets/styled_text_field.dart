import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool isPassword;
  final bool enabled;
  final bool readOnly;
  final IconData? icon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final void Function()? onTap;

  const StyledTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.validator,
    this.isPassword = false,
    this.enabled = true,
    this.readOnly = false,
    this.icon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      obscureText: isPassword,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        color: enabled ? Colors.white : Colors.white54,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF22252A),
        prefixIcon: icon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                child: Icon(icon, color: Colors.white30, size: 16),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 16,
        ),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.03), width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
      validator: validator,
    );
  }
}
