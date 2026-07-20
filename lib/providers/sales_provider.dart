import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  double salePrice;

  CartItem({required this.product, this.quantity = 1, double? salePrice})
      : salePrice = salePrice ?? product.effectivePrice;

  double get lineTotal => quantity * salePrice;
}

class SalesState {
  final List<CartItem> cart;
  final String customerName;

  const SalesState({this.cart = const [], this.customerName = 'Walk-in Customer'});

  int get totalItems => cart.fold(0, (s, i) => s + i.quantity);

  double get subtotal => cart.fold(0.0, (s, i) => s + i.lineTotal);

  SalesState copyWith({List<CartItem>? cart, String? customerName}) {
    return SalesState(
      cart: cart ?? this.cart,
      customerName: customerName ?? this.customerName,
    );
  }
}

class SalesNotifier extends Notifier<SalesState> {
  @override
  SalesState build() => const SalesState();

  void addToCart(Product product) {
    final existing = state.cart.where((c) => c.product.id == product.id).firstOrNull;
    if (existing != null) {
      if (existing.quantity >= product.currentStock) return;
      existing.quantity++;
      state = state.copyWith(cart: [...state.cart]);
    } else {
      state = state.copyWith(cart: [...state.cart, CartItem(product: product, quantity: 1)]);
    }
  }

  void removeFromCart(String productId) {
    state = state.copyWith(cart: state.cart.where((c) => c.product.id != productId).toList());
  }

  void changeQty(String productId, int delta) {
    final idx = state.cart.indexWhere((c) => c.product.id == productId);
    if (idx == -1) return;
    final item = state.cart[idx];
    final newQty = item.quantity + delta;
    if (newQty < 1) {
      removeFromCart(productId);
      return;
    }
    if (newQty > item.product.currentStock) return;
    final updated = [...state.cart];
    updated[idx] = CartItem(product: item.product, quantity: newQty);
    state = state.copyWith(cart: updated);
  }

  void updateItemPrice(String productId, double newPrice) {
    final idx = state.cart.indexWhere((c) => c.product.id == productId);
    if (idx == -1) return;
    final updated = [...state.cart];
    updated[idx] = CartItem(
      product: updated[idx].product,
      quantity: updated[idx].quantity,
      salePrice: newPrice,
    );
    state = state.copyWith(cart: updated);
  }

  void setCustomer(String name) {
    state = state.copyWith(customerName: name);
  }

  void clearCart() {
    state = state.copyWith(cart: []);
  }
}

final salesProvider = NotifierProvider<SalesNotifier, SalesState>(SalesNotifier.new);
