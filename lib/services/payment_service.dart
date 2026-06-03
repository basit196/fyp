import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'job_service.dart';

/// Handles Stripe Payment Sheet (flutter_stripe SDK only) and records payments in Firestore.
/// No Vercel/website: PaymentIntent is created via Stripe API from the app.
class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final JobService _jobService = JobService();

  static const String _stripeApiUrl = 'https://api.stripe.com/v1/payment_intents';

  /// Creates a PaymentIntent using Stripe API (no backend; SDK-only flow).
  Future<Map<String, String>> _createPaymentIntent({
    required int amountCents,
    required String jobId,
    required String userId,
    required String workerId,
    String currency = 'usd',
  }) async {
    final body = <String, String>{
      'amount': amountCents.toString(),
      'currency': currency,
      'automatic_payment_methods[enabled]': 'true',
      if (jobId.isNotEmpty) 'metadata[jobId]': jobId,
      if (userId.isNotEmpty) 'metadata[userId]': userId,
      if (workerId.isNotEmpty) 'metadata[workerId]': workerId,
    };

    final res = await http.post(
      Uri.parse(_stripeApiUrl),
      headers: {
        'Authorization': 'Bearer $stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body.keys.map((k) => '$k=${Uri.encodeComponent(body[k]!)}').join('&'),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final err = data['error'] as Map<String, dynamic>?;
      throw Exception(err?['message'] ?? res.body);
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'clientSecret': data['client_secret'] as String,
      'paymentIntentId': data['id'] as String,
    };
  }

  /// Records a successful payment and marks the job as paid so worker earnings update.
  Future<void> recordPaymentCompleted({
    required String jobId,
    required String userId,
    required String workerId,
    required String paymentIntentId,
    required double amount,
    required String userName,
    required String workerName,
    required String category,
  }) async {
    await _firestore.collection('payments').add({
      'jobId': jobId,
      'userId': userId,
      'workerId': workerId,
      'stripePaymentIntentId': paymentIntentId,
      'amount': amount,
      'currency': 'usd',
      'status': 'approved',
      'userName': userName,
      'workerName': workerName,
      'category': category,
      'approvedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _jobService.markAsPaid(jobId, workerId, userId, 'Stripe');
  }

  /// Runs the full flow: create PaymentIntent, show Payment Sheet, then record and credit the worker.
  Future<void> payWithStripe({
    required String jobId,
    required String userId,
    required String workerId,
    required double totalAmount,
    required String userName,
    required String workerName,
    required String category,
    String? userEmail,
  }) async {
    // Amount in cents (Stripe uses smallest currency unit)
    final amountCents = (totalAmount * 100).round();
    if (amountCents < 50) throw Exception('Amount must be at least \$0.50');

    final data = await _createPaymentIntent(
      amountCents: amountCents,
      jobId: jobId,
      userId: userId,
      workerId: workerId,
    );

    final clientSecret = data['clientSecret']!;
    final paymentIntentId = data['paymentIntentId']!;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'SkillLink',
        returnURL: 'skilllink://redirect',
        billingDetails: BillingDetails(
          email: userEmail,
          name: userName,
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    await recordPaymentCompleted(
      jobId: jobId,
      userId: userId,
      workerId: workerId,
      paymentIntentId: paymentIntentId,
      amount: totalAmount,
      userName: userName,
      workerName: workerName,
      category: category,
    );
  }
}
