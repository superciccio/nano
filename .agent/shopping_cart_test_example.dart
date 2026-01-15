import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano/test.dart'; // Import for .tester extension

// -----------------------------------------------------------------------------
// PART 1: The Application Code (Models, Service, Logic, UI)
// -----------------------------------------------------------------------------

// Models
class Product {
  final String id;
  final String name;
  final double price;

  const Product({required this.id, required this.name, required this.price});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ price.hashCode;
}

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity;

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode;
}

// Service
class ProductService {
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      const Product(id: '1', name: 'Widget', price: 9.99),
      const Product(id: '2', name: 'Gadget', price: 19.99),
      const Product(id: '3', name: 'Gizmo', price: 29.99),
    ];
  }

  Future<void> checkout(List<CartItem> items) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Simulate checkout
  }
}

// Logic
class ShoppingCartLogic extends NanoLogic<void> {
  final ProductService _productService;

  ShoppingCartLogic({required ProductService productService})
      : _productService = productService;

  // Atoms
  final products = AsyncAtom<List<Product>>();
  final cartItems = <CartItem>[].toAtom(label: 'cartItems');

  // Computed Atoms
  late final totalPrice = ComputedAtom<double>(
    () => cartItems().fold(0.0, (sum, item) => sum + item.total),
    label: 'totalPrice',
  );

  late final itemCount = ComputedAtom<int>(
    () => cartItems().fold(0, (sum, item) => sum + item.quantity),
    label: 'itemCount',
  );

  @override
  void onReady() {
    products.track(_productService.fetchProducts());
  }

  void addToCart(Product product) {
    cartItems.update((items) {
      final existingIndex =
          items.indexWhere((item) => item.product.id == product.id);

      if (existingIndex >= 0) {
        final updated = List<CartItem>.from(items);
        updated[existingIndex] = CartItem(
          product: product,
          quantity: items[existingIndex].quantity + 1,
        );
        return updated;
      } else {
        return [...items, CartItem(product: product, quantity: 1)];
      }
    });
  }

  void removeFromCart(String productId) {
    cartItems.update((items) =>
        items.where((item) => item.product.id != productId).toList());
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    cartItems.update((items) {
      final index = items.indexWhere((item) => item.product.id == productId);
      if (index < 0) return items;

      final updated = List<CartItem>.from(items);
      updated[index] = CartItem(
        product: items[index].product,
        quantity: quantity,
      );
      return updated;
    });
  }

  Future<void> checkout() async {
    if (cartItems().isEmpty) return;

    status.set(NanoStatus.loading);
    try {
      await _productService.checkout(cartItems());
      cartItems.set([]); // Clear cart
      status.set(NanoStatus.success);
    } catch (e) {
      error.set(e);
      status.set(NanoStatus.error);
    }
  }
}

// UI
class ShoppingCartPage extends StatelessWidget {
  const ShoppingCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<ShoppingCartLogic, void>(
      create: (reg) => ShoppingCartLogic(
        productService: reg.get<ProductService>(),
      ),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping Cart'),
            actions: [
              Watch(logic.itemCount, builder: (context, count) {
                return Text('$count items');
              }),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: logic.products.when(
                  loading: (context) => const CircularProgressIndicator(),
                  error: (context, error) => Text('Error: $error'),
                  data: (context, products) {
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product.name),
                          onTap: () => logic.addToCart(product),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Watch(logic.totalPrice, builder: (context, total) {
                return Text('Total: \$${total.toStringAsFixed(2)}');
              }),
              Watch(logic.status, builder: (context, status) {
                if (status == NanoStatus.loading) {
                  return const CircularProgressIndicator();
                }
                return ElevatedButton(
                  onPressed: logic.checkout,
                  child: const Text('Checkout'),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// PART 2: The Tests
// -----------------------------------------------------------------------------

// Mocks
class MockProductService implements ProductService {
  bool shouldFail = false;
  List<Product> products = [
    const Product(id: '1', name: 'Test Product', price: 10.0),
  ];

  @override
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(Duration.zero);
    if (shouldFail) throw Exception('Fetch failed');
    return products;
  }

  @override
  Future<void> checkout(List<CartItem> items) async {
    await Future.delayed(Duration.zero);
    if (shouldFail) throw Exception('Checkout failed');
  }
}

void main() {
  group('ShoppingCartLogic Tests', () {
    late ShoppingCartLogic logic;
    late MockProductService mockService;

    setUp(() {
      mockService = MockProductService();
      logic = ShoppingCartLogic(productService: mockService);
      // Initialize manually since we're not using NanoView here
      logic.onInit(null);
      logic.onReady();
    });

    test('Initial state is correct', () {
      expect(logic.cartItems.value, isEmpty);
      expect(logic.totalPrice.value, 0.0);
      expect(logic.itemCount.value, 0);
    });

    test('addToCart updates state correctly', () async {
      final product = mockService.products.first;
      
      // Use .tester to verify emissions
      final countTester = logic.itemCount.tester;
      final totalTester = logic.totalPrice.tester;

      logic.addToCart(product);

      expect(logic.cartItems.value.length, 1);
      expect(logic.cartItems.value.first.product, product);
      expect(logic.cartItems.value.first.quantity, 1);
      
      await countTester.expect([1]);
      await totalTester.expect([10.0]);
    });

    test('addToCart increments quantity for existing item', () {
      final product = mockService.products.first;
      logic.addToCart(product);
      logic.addToCart(product);

      expect(logic.cartItems.value.length, 1);
      expect(logic.cartItems.value.first.quantity, 2);
      expect(logic.totalPrice.value, 20.0);
    });

    test('removeFromCart removes item', () {
      final product = mockService.products.first;
      logic.addToCart(product);
      expect(logic.cartItems.value, isNotEmpty);

      logic.removeFromCart(product.id);
      expect(logic.cartItems.value, isEmpty);
    });

    test('checkout flow - success', () async {
      final product = mockService.products.first;
      logic.addToCart(product);
      
      // Reset status to success (simulating page loaded) so we can detect transition to loading
      logic.status.set(NanoStatus.success);
      final statusTester = logic.status.tester;

      final future = logic.checkout();
      
      // Should emit loading then success
      await statusTester.expect([NanoStatus.loading, NanoStatus.success]);
      
      await future;
      expect(logic.cartItems.value, isEmpty);
    });

    test('checkout flow - failure', () async {
      final product = mockService.products.first;
      logic.addToCart(product);
      mockService.shouldFail = true;

      // Reset status to success (simulating page loaded)
      logic.status.set(NanoStatus.success);
      final statusTester = logic.status.tester;

      await logic.checkout();
      
      await statusTester.expect([NanoStatus.loading, NanoStatus.error]);
      expect(logic.error.value, isNotNull);
      // Cart should remain full on error
      expect(logic.cartItems.value, isNotEmpty);
    });
  });

  group('ShoppingCartPage Widget Tests', () {
    testWidgets('Renders products and updates cart', (tester) async {
      final mockService = MockProductService();

      await tester.pumpWidget(
        Scope(
          modules: [
            NanoFactory<ProductService>((_) => mockService),
          ],
          child: const MaterialApp(
            home: ShoppingCartPage(),
          ),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

      // Wait for products to load
      await tester.pump(const Duration(milliseconds: 100));

      // Verify product list
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('0 items'), findsOneWidget);

      // Add to cart
      await tester.tap(find.text('Test Product'));
      await tester.pump();

      // Verify cart update
      expect(find.text('1 items'), findsOneWidget);
      expect(find.text('Total: \$10.00'), findsOneWidget);
    });
  });
}
