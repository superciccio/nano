import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

/// Test case: Shopping cart feature to verify AI agent follows Nano patterns
/// This should demonstrate:
/// - Proper Atom usage
/// - ComputedAtom for derived state
/// - AsyncAtom for API calls
/// - Watch widgets for surgical rebuilds
/// - NanoLogic lifecycle
/// - Dependency injection

// Models
class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;
}

// Service (would be registered in Scope)
class ProductService {
  Future<List<Product>> fetchProducts() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      Product(id: '1', name: 'Widget', price: 9.99),
      Product(id: '2', name: 'Gadget', price: 19.99),
      Product(id: '3', name: 'Gizmo', price: 29.99),
    ];
  }

  Future<void> checkout(List<CartItem> items) async {
    await Future.delayed(Duration(seconds: 2));
    // Simulate checkout
  }
}

// Logic
class ShoppingCartLogic extends NanoLogic<void> {
  final ProductService _productService;

  ShoppingCartLogic({required ProductService productService})
      : _productService = productService;

  // ✅ CORRECT: Using AsyncAtom for async data
  final products = AsyncAtom<List<Product>>();

  // ✅ CORRECT: Using Atom with .toAtom() extension
  final cartItems = <CartItem>[].toAtom('cartItems');

  // ✅ CORRECT: ComputedAtom for derived state
  late final totalPrice = ComputedAtom(
    [cartItems],
    () => cartItems().fold(0.0, (sum, item) => sum + item.total),
    label: 'totalPrice',
  );

  late final itemCount = ComputedAtom(
    [cartItems],
    () => cartItems().fold(0, (sum, item) => sum + item.quantity),
    label: 'itemCount',
  );

  late final isEmpty = ComputedAtom(
    [cartItems],
    () => cartItems().isEmpty,
    label: 'isEmpty',
  );

  @override
  void onInit(void params) {
    // ✅ CORRECT: Using .track() for async operations
    products.track(_productService.fetchProducts());
  }

  // ✅ CORRECT: Business logic in Logic class, not in UI
  void addToCart(Product product) {
    final items = cartItems();
    final existingIndex =
        items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Update quantity
      final updated = List<CartItem>.from(items);
      updated[existingIndex] = CartItem(
        product: product,
        quantity: items[existingIndex].quantity + 1,
      );
      cartItems.set(updated);
    } else {
      // Add new item
      cartItems.set([...items, CartItem(product: product, quantity: 1)]);
    }
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
    // ✅ CORRECT: Using NanoView with DI
    return NanoView<ShoppingCartLogic, void>(
      create: (reg) => ShoppingCartLogic(
        productService: reg.get<ProductService>(),
      ),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping Cart'),
            actions: [
              // ✅ CORRECT: Using Watch for surgical rebuild
              Watch(logic.itemCount, builder: (context, count) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$count items'),
                  ),
                );
              }),
            ],
          ),
          body: Column(
            children: [
              // ✅ CORRECT: Using .when() for AsyncAtom
              Expanded(
                child: logic.products.when(
                  loading: (context) =>
                      const Center(child: CircularProgressIndicator()),
                  error: (context, error) => Center(
                    child: Text('Error: $error'),
                  ),
                  data: (context, products) {
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            // ✅ CORRECT: Simple action, direct method reference
                            onPressed: () => logic.addToCart(product),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              // ✅ CORRECT: Using tuple syntax for multiple atoms (not nested Watch)
              (logic.cartItems, logic.totalPrice).watch((context, items, total) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Cart is empty'),
                  );
                }

                return Column(
                  children: [
                    ...items.map((item) => ListTile(
                          title: Text(item.product.name),
                          subtitle: Text('Quantity: ${item.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => logic.updateQuantity(
                                  item.product.id,
                                  item.quantity - 1,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => logic.updateQuantity(
                                  item.product.id,
                                  item.quantity + 1,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    logic.removeFromCart(item.product.id),
                              ),
                            ],
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: \$${total.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          // ✅ CORRECT: Using Watch for status-dependent UI
                          Watch(logic.status, builder: (context, status) {
                            return ElevatedButton(
                              onPressed: status == NanoStatus.loading
                                  ? null
                                  : logic.checkout,
                              child: status == NanoStatus.loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Checkout'),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// Example setup in main.dart
void main() {
  runApp(
    // ✅ CORRECT: Using Scope for DI
    Scope(
      modules: [
        ProductService(), // Eager singleton
      ],
      child: const MaterialApp(
        home: ShoppingCartPage(),
      ),
    ),
  );
}
