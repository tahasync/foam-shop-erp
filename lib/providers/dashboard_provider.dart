import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/opening_balance.dart';
import '../services/accounting_service.dart';
import 'firebase_providers.dart';
import 'product_provider.dart';
import 'sale_provider.dart';
import 'purchase_provider.dart';
import 'expense_provider.dart';
import 'payment_provider.dart';
import 'supplier_payment_provider.dart';

final accountingServiceProvider = Provider<AccountingService>((ref) => AccountingService());

final openingBalanceStreamProvider = StreamProvider<OpeningBalance?>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.openingBalanceStream.map((snap) {
    if (snap.docs.isEmpty) return null;
    return OpeningBalance.fromMap(snap.docs.first.data() as Map<String, dynamic>);
  });
});

final accountingSummaryProvider = Provider<AsyncValue<AccountingSummary>>((ref) {
  final sales = ref.watch(salesStreamProvider).asData?.value ?? [];
  final purchases = ref.watch(purchasesStreamProvider).asData?.value ?? [];
  final expenses = ref.watch(expensesStreamProvider).asData?.value ?? [];
  final payments = ref.watch(paymentsStreamProvider).asData?.value ?? [];
  final supplierPayments = ref.watch(supplierPaymentsStreamProvider).asData?.value ?? [];
  final products = ref.watch(productsStreamProvider).asData?.value ?? [];
  final openingBal = ref.watch(openingBalanceStreamProvider).asData?.value;

  if (ref.watch(salesStreamProvider).isLoading) return const AsyncValue.loading();

  final service = ref.read(accountingServiceProvider);
  final result = service.compute(
    sales: sales,
    purchases: purchases,
    expenses: expenses,
    payments: payments,
    supplierPayments: supplierPayments,
    products: products,
    openingBal: openingBal,
  );

  return AsyncValue.data(result);
});
