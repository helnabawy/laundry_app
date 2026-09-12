import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/digits.dart';

/// Row of digit boxes backed by one invisible text field, so paste and
/// SMS autofill (`oneTimeCode`) work.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    required this.length,
    required this.onChanged,
    this.hasError = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String> onChanged;
  final bool hasError;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final activeIndex = math.min(code.length, widget.length - 1);
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _DigitBox(
                  digit: i < code.length ? code[i] : null,
                  active: _focus.hasFocus && i == activeIndex,
                  hasError: widget.hasError,
                ),
              ),
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: true,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [
                DigitsInputFormatter(),
                LengthLimitingTextInputFormatter(widget.length),
              ],
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                counterText: '',
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.digit,
    required this.active,
    required this.hasError,
  });

  final String? digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.danger
        : active
        ? AppColors.ink
        : AppColors.line;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 60,
      height: 66,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: active ? 1.8 : 1.2),
      ),
      child: digit != null
          ? Text(
              digit!,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            )
          : active
          ? Container(width: 2, height: 30, color: AppColors.ink)
          : null,
    );
  }
}
