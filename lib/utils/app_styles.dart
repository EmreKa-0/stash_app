import 'package:flutter/material.dart';

// Tasarımda kullanılan ana renkler
const Color kLightBlue = Color(0xFFC7EBFD);
const Color kLightOrange = Color(0xFFFFE6B5);
const Color kInputFillColor = Color(0xFFFFF2D0);
const Color kPrimaryBlue = Color(0xFF0D47A1); // Koyu Mavi (Yazılar için)
const Color kOrangeButton = Color(0xFFF1B746); // Sign Up Buton Rengi
const Color kLightestBlue = Color(0xFFE0F7FA); // Login input rengi

// Yeniden Kullanılabilir Text Field Widget'ı
class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool isPassword;

  const CustomTextField(
      {super.key, required this.hintText, this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black87),
        filled: true,
        fillColor: kInputFillColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}
