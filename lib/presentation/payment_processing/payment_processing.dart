import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import './widgets/payment_amount_widget.dart';
import './widgets/payment_description_widget.dart';
import './widgets/payment_method_widget.dart';
import './widgets/process_payment_button_widget.dart';

class PaymentProcessing extends StatefulWidget {
  const PaymentProcessing({super.key});

  @override
  State<PaymentProcessing> createState() => _PaymentProcessingState();
}

class _PaymentProcessingState extends State<PaymentProcessing> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _isValidAmount = false;

  // Mock payment methods data
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      "id": "pm_1",
      "type": "card",
      "brand": "visa",
      "last4": "4242",
      "expMonth": 12,
      "expYear": 2025,
      "isDefault": true,
    },
    {
      "id": "pm_2",
      "type": "card",
      "brand": "mastercard",
      "last4": "5555",
      "expMonth": 8,
      "expYear": 2026,
      "isDefault": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod =
        _paymentMethods.isNotEmpty ? _paymentMethods[0]["id"] : null;
    _amountController.addListener(_validateAmount);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateAmount() {
    final text =
        _amountController.text.replaceAll(',', '').replaceAll('\$', '');
    final amount = double.tryParse(text);
    setState(() {
      _isValidAmount = amount != null && amount > 0;
    });
  }

  String _formatAmount(String value) {
    if (value.isEmpty) return '';

    // Remove any non-digit characters except decimal point
    String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');

    // Parse as double
    double? amount = double.tryParse(cleanValue);
    if (amount == null) return value;

    // Format with commas
    String formatted = amount.toStringAsFixed(2);
    List<String> parts = formatted.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    // Add commas to integer part
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ',';
      }
      formattedInteger += integerPart[i];
    }

    return '\$$formattedInteger.$decimalPart';
  }

  Future<void> _processPayment() async {
    if (!_isValidAmount || _selectedPaymentMethod == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock Stripe checkout URL
      final String checkoutUrl =
          'https://checkout.stripe.com/pay/cs_test_mock_session_id';

      // Launch external browser for Stripe checkout
      final Uri url = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        // Simulate successful payment after returning from browser
        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment processed successfully! Transaction ID: txn_${DateTime.now().millisecondsSinceEpoch}',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              backgroundColor: AppTheme.getSuccessColor(true),
              duration: const Duration(seconds: 4),
            ),
          );

          // Navigate back to dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        throw Exception('Could not launch payment URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment failed: ${e.toString()}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onError,
              ),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _addNewPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Add New Payment Method',
              style: AppTheme.lightTheme.textTheme.headlineSmall,
            ),
            SizedBox(height: 3.h),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      hintText: '12/25',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'CVC',
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Payment method added successfully',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                      backgroundColor: AppTheme.getSuccessColor(true),
                    ),
                  );
                },
                child: const Text('Add Payment Method'),
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with back button
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.shadow,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CustomIconWidget(
                            iconName: 'arrow_back',
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                            size: 6.w,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Payment Processing',
                        style: AppTheme.lightTheme.textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 2.h),

                        // Payment Amount Section
                        PaymentAmountWidget(
                          controller: _amountController,
                          onAmountChanged: (value) {
                            final formatted = _formatAmount(value);
                            if (formatted != value) {
                              _amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            }
                          },
                          isValid: _isValidAmount,
                        ),

                        SizedBox(height: 4.h),

                        // Payment Method Section
                        PaymentMethodWidget(
                          paymentMethods: _paymentMethods,
                          selectedMethodId: _selectedPaymentMethod,
                          onMethodSelected: (methodId) {
                            setState(() {
                              _selectedPaymentMethod = methodId;
                            });
                          },
                          onAddNewMethod: _addNewPaymentMethod,
                        ),

                        SizedBox(height: 4.h),

                        // Payment Description Section
                        PaymentDescriptionWidget(
                          controller: _descriptionController,
                        ),

                        SizedBox(height: 6.h),

                        // Process Payment Button
                        ProcessPaymentButtonWidget(
                          isEnabled: _isValidAmount &&
                              _selectedPaymentMethod != null &&
                              !_isProcessing,
                          isProcessing: _isProcessing,
                          onPressed: _processPayment,
                        ),

                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Processing Payment...',
                          style: AppTheme.lightTheme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
