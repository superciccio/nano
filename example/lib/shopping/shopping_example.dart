import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

// Model
class Product {
  final int id;
  final String name;
  final double price;

  const Product(this.id, this.name, this.price);
}

class CartItem {
  final Product product;
  final int quantity;

  const CartItem(this.product, this.quantity);

  double get total => product.price * quantity;
}

// Logic
class ShoppingLogic extends NanoLogic<dynamic> {
  // Available products (static for simplicity)
  final products = const [
    Product(1, 'Laptop', 999.0),
    Product(2, 'Phone', 599.0),
    Product(3, 'Headphones', 199.0),
    Product(4, 'Mouse', 49.0),
    Product(5, 'Keyboard', 89.0),
  ].toAtom('products');

  // Cart state: Map of ProductId -> Quantity
  final _cart = Atom<Map<int, int>>({}, label: 'cart_internal');

  // Computed: List of CartItems for UI
  late final cartItems = ComputedAtom(
    [_cart, products],
    () {
      final currentCart = _cart.value;
      final currentProducts = products.value;

      return currentCart.entries.map((entry) {
        final product = currentProducts.firstWhere((p) => p.id == entry.key);
        return CartItem(product, entry.value);
      }).toList();
    },
    label: 'cartItems',
  );

  // Computed: Total price
  late final totalPrice = ComputedAtom(
    [cartItems],
    () => cartItems.value.fold(0.0, (sum, item) => sum + item.total),
    label: 'totalPrice',
  );

  // Computed: Total items count
  late final totalItems = ComputedAtom(
    [_cart],
    () => _cart.value.values.fold(0, (sum, qty) => sum + qty),
    label: 'totalItems',
  );

  // Selector: efficient derived state that only updates when result changes
  late final isCartEmpty = _cart.select((map) => map.isEmpty, label: 'isCartEmpty');

  void addToCart(Product product) {
    _cart.update((map) {
      final newMap = Map<int, int>.from(map);
      newMap[product.id] = (newMap[product.id] ?? 0) + 1;
      return newMap;
    });
  }

  void removeFromCart(Product product) {
    _cart.update((map) {
      final newMap = Map<int, int>.from(map);
      if (!newMap.containsKey(product.id)) return map;

      if (newMap[product.id]! > 1) {
        newMap[product.id] = newMap[product.id]! - 1;
      } else {
        newMap.remove(product.id);
      }
      return newMap;
    });
  }

  void clearCart() {
    _cart(<int, int>{});
  }
}

// Page
class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<ShoppingLogic, dynamic>(
      create: (r) => ShoppingLogic(),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping Cart'),
            actions: [
              // Watch specific value for badge
              Watch(logic.totalItems, builder: (context, count) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Badge(
                      label: Text('$count'),
                      isLabelVisible: count > 0,
                      child: const Icon(Icons.shopping_cart),
                    ),
                  ),
                );
              }),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                flex: 2,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: logic.products.value.length,
                  itemBuilder: (context, index) {
                    final product = logic.products.value[index];
                    return Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text('\$${product.price}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () => logic.addToCart(product),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(thickness: 2),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Your Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 3,
                child: Watch(logic.cartItems, builder: (context, items) {
                  // Use the SelectorAtom to check for empty state efficiently
                  // (Though here we already have the items list, this is for showcase)
                  if (logic.isCartEmpty.value) {
                    return const Center(child: Text('Cart is empty'));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('${item.quantity} x \$${item.product.price} = \$${item.total}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => logic.removeFromCart(item.product),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => logic.addToCart(item.product),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Watch(logic.totalPrice, builder: (context, total) {
                      return Text(
                        'Total: \$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                    ElevatedButton(
                      onPressed: logic.clearCart,
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
