import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentAmountWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onAmountChanged;
  final bool isValid;

  const PaymentAmountWidget({
    super.key,
    required this.controller,
    required this.onAmountChanged,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? AppTheme.getSuccessColor(true)
              : AppTheme.lightTheme.colorScheme.outline,
          width: isValid ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'attach_money',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Payment Amount',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isValid)
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.getSuccessColor(true),
                  size: 5.w,
                ),
            ],
          ),
          SizedBox(height: 3.h),

          // Amount input field
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              hintText: '\$0.00',
              hintStyle: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.lightTheme.colorScheme.outline,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,\$]')),
            ],
            onChanged: onAmountChanged,
          ),

          SizedBox(height: 2.h),

          // Numeric keypad
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          Row(
            children: [
              _buildKeypadButton('1'),
              SizedBox(width: 2.w),
              _buildKeypadButton('2'),
              SizedBox(width: 2.w),
              _buildKeypadButton('3'),
            ],
          ),
          SizedBox(height: 1.h),

          // Row 2: 4, 5, 6
          Row(
            children: [
              _buildKeypadButton('4'),
              SizedBox(width: 2.w),
              _buildKeypadButton('5'),
              SizedBox(width: 2.w),
              _buildKeypadButton('6'),
            ],
          ),
          SizedBox(height: 1.h),

          // Row 3: 7, 8, 9
          Row(
            children: [
              _buildKeypadButton('7'),
              SizedBox(width: 2.w),
              _buildKeypadButton('8'),
              SizedBox(width: 2.w),
              _buildKeypadButton('9'),
            ],
          ),
          SizedBox(height: 1.h),

          // Row 4: ., 0, backspace
          Row(
            children: [
              _buildKeypadButton('.'),
              SizedBox(width: 2.w),
              _buildKeypadButton('0'),
              SizedBox(width: 2.w),
              _buildKeypadButton('⌫', isBackspace: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {bool isBackspace = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleKeypadTap(value, isBackspace),
        child: Container(
          height: 12.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: isBackspace
                ? CustomIconWidget(
                    iconName: 'backspace',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 5.w,
                  )
                : Text(
                    value,
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _handleKeypadTap(String value, bool isBackspace) {
    String currentText = controller.text;

    if (isBackspace) {
      if (currentText.isNotEmpty) {
        String newText = currentText.substring(0, currentText.length - 1);
        controller.text = newText;
        onAmountChanged(newText);
      }
    } else {
      // Handle decimal point
      if (value == '.' && currentText.contains('.')) {
        return; // Don't allow multiple decimal points
      }

      String newText = currentText + value;
      controller.text = newText;
      onAmountChanged(newText);
    }
  }
}
