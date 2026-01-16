import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano_annotations/nano_annotations.dart';
import 'package:nano_test_utils/nano_test_utils.dart';

part 'shopping_cart_test_example.g.dart';

// -----------------------------------------------------------------------------
// MODELS & SERVICES
// -----------------------------------------------------------------------------

class Product {
  final String id;
  final String name;
  final double price;
  const Product({required this.id, required this.name, required this.price});
}

class CartItem {
  final Product product;
  final int quantity;
  const CartItem({required this.product, required this.quantity});
  double get total => product.price * quantity;
}

class ProductService {
  Future<List<Product>> fetchProducts() async => [];
  Future<void> checkout(List<CartItem> items) async {}
}

// -----------------------------------------------------------------------------
// MODERN LOGIC
// -----------------------------------------------------------------------------

@nano
abstract class _ShoppingCartLogic extends NanoLogic {
  final ProductService _service;
  _ShoppingCartLogic(this._service);

  @async AsyncState<List<Product>> products = const AsyncIdle();
  @state List<CartItem> items = [];

  AsyncAtom<List<Product>> get products$;

  @override
  void onReady() {
    products$.track(_service.fetchProducts());
  }

  void addToCart(Product product) {
    final existingIndex = items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(items);
      updated[existingIndex] = CartItem(
        product: product,
        quantity: items[existingIndex].quantity + 1,
      );
      items = updated;
    } else {
      items = [...items, CartItem(product: product, quantity: 1)];
    }
  }

  Future<void> checkout() async {
    if (items.isEmpty) return;
    status.set(NanoStatus.loading);
    try {
      await _service.checkout(items);
      items = [];
      status.set(NanoStatus.success);
    } catch (e) {
      status.set(NanoStatus.error);
    }
  }
}

class ShoppingCartLogic extends _ShoppingCartLogic with _$ShoppingCartLogic {
  ShoppingCartLogic(super.service);
}

// -----------------------------------------------------------------------------
// MODERN UI (NanoComponent)
// -----------------------------------------------------------------------------

class ShoppingCartPage extends NanoComponent {
  const ShoppingCartPage({super.key});

  @override
  List<Object> get modules => [
    NanoLazy((r) => ShoppingCartLogic(r.get<ProductService>()))
  ];

  @override
  Widget view(BuildContext context) {
    final logic = context.use<ShoppingCartLogic>();

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: logic.products.map(
        idle: () => const Center(child: Text('Idle')),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err) => Center(child: Text('Error: $err')),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, i) => ListTile(
            title: Text(products[i].name),
            onTap: () => logic.addToCart(products[i]),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Items: ${logic.items.length}'),
              const Spacer(),
              ElevatedButton(
                onPressed: logic.checkout,
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MODERN TESTS
// -----------------------------------------------------------------------------

class MockService implements ProductService {
  @override
  Future<List<Product>> fetchProducts() async => [
    const Product(id: '1', name: 'Nano Sticker', price: 1.0),
  ];
  @override
  Future<void> checkout(List<CartItem> items) async {}
}

void main() {
  group('ShoppingCart Modern Tests', () {
    
    nanoTestWidgets('Full checkout flow',
      overrides: [
        NanoFactory<ProductService>((_) => MockService()),
      ],
      builder: () => const ShoppingCartPage(),
      verify: (tester) async {
        await tester.pumpSettled(); // Wait for products to load
        
        expect(find.text('Nano Sticker'), findsOneWidget);
        
        await tester.tap(find.text('Nano Sticker'));
        await tester.pump(); // Update count
        
        expect(find.text('Items: 1'), findsOneWidget);
        
        await tester.tap(find.text('Checkout'));
        await tester.pumpSettled();
        
        final logic = tester.read<ShoppingCartLogic>();
        expect(logic.items, isEmpty);
      },
    );

    test('Logic Snapshot', () async {
      final logic = ShoppingCartLogic(MockService());
      final harness = NanoTestHarness(logic);
      
      await harness.record((logic) async {
        logic.addToCart(const Product(id: '1', name: 'A', price: 10));
      });
      
      // Verification happens via golden file
      harness.expectSnapshot('cart_add_item');
    });
  });
}