import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano_example/shopping/shopping_example.dart';

void main() {
  group('ShoppingLogic', () {
    late ShoppingLogic logic;

    setUp(() {
      Nano.init();
      logic = ShoppingLogic();
    });

    tearDown(() {
      logic.dispose();
    });

    test('initial cart is empty', () {
      expect(logic.cartItems.value, isEmpty);
      expect(logic.totalPrice.value, 0.0);
      expect(logic.totalItems.value, 0);
      expect(logic.isCartEmpty.value, isTrue);
    });

    test('adding items updates state', () {
      final product1 = logic.products.value[0]; // Laptop: 999.0

      logic.addToCart(product1);

      expect(logic.cartItems.value.length, 1);
      expect(logic.cartItems.value.first.product, product1);
      expect(logic.cartItems.value.first.quantity, 1);
      expect(logic.totalPrice.value, 999.0);
      expect(logic.totalItems.value, 1);
      expect(logic.isCartEmpty.value, isFalse);

      logic.addToCart(product1);

      expect(logic.cartItems.value.length, 1);
      expect(logic.cartItems.value.first.quantity, 2);
      expect(logic.totalPrice.value, 1998.0);
      expect(logic.totalItems.value, 2);
    });

    test('removing items updates state', () {
      final product1 = logic.products.value[0];

      logic.addToCart(product1);
      logic.addToCart(product1);
      // Qty: 2

      logic.removeFromCart(product1);
      // Qty: 1

      expect(logic.cartItems.value.first.quantity, 1);
      expect(logic.totalItems.value, 1);

      logic.removeFromCart(product1);
      // Qty: 0 -> Removed

      expect(logic.cartItems.value, isEmpty);
      expect(logic.isCartEmpty.value, isTrue);
    });

    test('clear cart resets everything', () {
      final product1 = logic.products.value[0];
      final product2 = logic.products.value[1];

      logic.addToCart(product1);
      logic.addToCart(product2);

      expect(logic.cartItems.value, isNotEmpty);

      logic.clearCart();

      expect(logic.cartItems.value, isEmpty);
      expect(logic.totalPrice.value, 0.0);
      expect(logic.totalItems.value, 0);
      expect(logic.isCartEmpty.value, isTrue);
    });
  });
}
