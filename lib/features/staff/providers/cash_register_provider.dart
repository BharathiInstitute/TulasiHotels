/// Cash register providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tulasihotels/features/staff/services/cash_register_service.dart';
import 'package:tulasihotels/models/cash_register_model.dart';

/// Stream today's register session
final todayRegisterProvider =
    StreamProvider.autoDispose<CashRegisterModel?>((ref) {
  return CashRegisterService.todayRegisterStream();
});

/// Stream register history
final registerHistoryProvider =
    StreamProvider.autoDispose<List<CashRegisterModel>>((ref) {
  return CashRegisterService.registerHistoryStream();
});
