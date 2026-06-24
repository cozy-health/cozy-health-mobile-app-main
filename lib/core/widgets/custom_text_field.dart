import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../gen/assets.gen.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool hasError;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.hasError = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _obscureText : false,
      style: AppTextStyles.body1.copyWith(color: AppColors.black),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.body1.copyWith(color: AppColors.grey),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.hasError ? Colors.red : AppColors.primary, 
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.hasError ? Colors.red : AppColors.primary, 
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.hasError ? Colors.red : AppColors.primary, 
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: widget.isPassword
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: widget.hasError
                      ? SvgPicture.asset(
                          Assets.svg.warning,
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.red,
                            BlendMode.srcIn,
                          ),
                        )
                      : SvgPicture.asset(
                          _obscureText ? Assets.svg.padlockClosed : Assets.svg.padlockOpen,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            AppColors.grey,
                            BlendMode.srcIn,
                          ),
                        ),
                ),
              )
            : widget.hasError
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(
                      Assets.svg.warning,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : null,
      ),
    );
  }
}