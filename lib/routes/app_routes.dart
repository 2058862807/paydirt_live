import 'package:flutter/material.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/dashboard/dashboard.dart';
import '../presentation/payment_processing/payment_processing.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String loginScreen = '/login-screen';
  static const String notifications = '/notifications';
  static const String dashboard = '/dashboard';
  static const String paymentProcessing = '/payment-processing';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const Dashboard(),
    loginScreen: (context) => const LoginScreen(),
    dashboard: (context) => const Dashboard(),
    paymentProcessing: (context) => const PaymentProcessing(),
    // TODO: Add your other routes here
  };
}
