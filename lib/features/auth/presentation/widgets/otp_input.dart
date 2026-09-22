import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design/design.dart';
import '../../../../core/utils/digits.dart';

/// Reserved digit slots backed by one invisible text field, so paste and
/// SMS autofill (`oneTimeCode`) keep working.
///
/// Each digit owns a fixed slot and changes in place; the slot is a ruled
/// field, not a box, because the whole system is printed on tape.
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
    return Semantics(
      label: 'Verification code, ${code.length} of ${widget.length} digits',
      textField: true,
      child: Stack(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignSpace.sm,
                    ),
                    child: _DigitSlot(
                      digit: i < code.length ? code[i] : null,
                      active: _focus.hasFocus && i == activeIndex,
                      hasError: widget.hasError,
                    ),
                  ),
              ],
            ),
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
      ),
    );
  }
}

class _DigitSlot extends StatelessWidget {
  const _DigitSlot({
    required this.digit,
    required this.active,
    required this.hasError,
  });

  final String? digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rule = hasError
        ? colors.signal
        : active
        ? colors.tint
        : colors.ruleStrong;
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 46,
            child: Center(
              child: digit == null
                  ? (active
                        ? Container(width: 2, height: 26, color: colors.tint)
                        : const SizedBox.shrink())
                  : Text(
                      digit!,
                      style: DesignTypography.serial(colors.ink, size: 32),
                    ),
            ),
          ),
          AnimatedContainer(
            duration: DesignMotion.quick,
            height: active || hasError ? DesignRule.heavy : DesignRule.medium,
            color: rule,
          ),
        ],
      ),
    );
  }
}
