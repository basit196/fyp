import 'package:flutter/material.dart';

/// Stripe publishable key (safe to ship in app).
const String stripePublishableKey =
    'pk_test_51OgPpFKLvENSzscJuOoZaDIalQQUJFUfO2uDVZHcHvgdRgaSZ3ELuxC2YfK91uUEKTOGfSq2QCHGEwfdHDanMZLF006tNsTVKx';

/// Stripe secret key — used in-app to create PaymentIntents (no Vercel/website; flutter_stripe SDK only).
/// For production, use a secure backend to create PaymentIntents and do not ship the secret in the app.
const String stripeSecretKey =
    'sk_test_51OgPpFKLvENSzscJ8EXwZ5R9ULP9MbcwSINwBMxVTloQ3AqzsAVMgFV8xSu8fXGg47t1EdnjnGFIW4wAliLuxp0D00YvUL67Fl';

class AppColors {
  static const primary = Color(0xFF2563EB);
  static const secondary = Color(0xFF10B981);
  static const accent = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const background = Color(0xFFF9FAFB);
  static const cardBackground = Colors.white;
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
}

class WorkerCategories {
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Electrician', 'icon': Icons.electrical_services, 'color': Color(0xFFFBBF24)},
    {'name': 'Plumber', 'icon': Icons.plumbing, 'color': Color(0xFF3B82F6)},
    {'name': 'Mechanic', 'icon': Icons.build, 'color': Color(0xFFEF4444)},
    {'name': 'Carpenter', 'icon': Icons.carpenter, 'color': Color(0xFF92400E)},
    {'name': 'Painter', 'icon': Icons.format_paint, 'color': Color(0xFF8B5CF6)},
    {'name': 'Tailor', 'icon': Icons.content_cut, 'color': Color(0xFFEC4899)},
    {'name': 'Cleaner', 'icon': Icons.cleaning_services, 'color': Color(0xFF10B981)},
    {'name': 'Gardener', 'icon': Icons.grass, 'color': Color(0xFF059669)},
    {'name': 'AC Technician', 'icon': Icons.ac_unit, 'color': Color(0xFF06B6D4)},
    {'name': 'Potter', 'icon': Icons.palette, 'color': Color(0xFF78350F)},
  ];
}


