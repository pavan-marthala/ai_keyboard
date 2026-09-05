import 'package:atfix/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dimens.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onChanged,
    this.autofillHints,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: typography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: Dimens.smallPadding),
        ],
        TextFormField(
          controller: _effectiveController,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          autofillHints: widget.autofillHints,
          style: typography.bodyMedium.copyWith(color: colors.textPrimary),
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: widget.errorText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? GestureDetector(
                    onTap: () {
                      final controller = _effectiveController;
                      final selection = controller.selection;
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (controller.text.isNotEmpty && selection.isValid) {
                          controller.selection = selection;
                        }
                      });
                    },
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: colors.text4,
                      size: 20,
                    ),
                  )
                : widget.suffixIcon,
          ),
        ),
      ],
    );
  }
}
